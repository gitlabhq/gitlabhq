# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RackAttack::LabkitRateLimit::ThrottleRegistry, feature_category: :rate_limiting do
  describe '.all' do
    subject(:entries) { described_class.all }

    it 'backs every entry with a throttle and covers the whole Rack::Attack set' do
      # Every throttle Rack::Attack registers (via the shared all_throttle_definitions
      # source) must be classified into the shadow, and every entry must back a throttle
      # that exists (a sibling rule via its :name). A new throttle cannot silently escape
      # the shadow, and a renamed one fails loudly.
      backing = entries.each_value.map(&:name).uniq

      expect(backing).to match_array(Gitlab::RackAttack.all_throttle_definitions.keys)
    end

    it 'builds an entry per throttle backed by a Rack::Attack throttle definition' do
      entries.each_value do |entry|
        expect(entry.definition).to be_a(Gitlab::RackAttack::ThrottleDefinition)
        expect(entry.definition.options).to be_present
        expect(entry.definition.request_identifier).to respond_to(:call)
      end
    end

    it 'classifies every throttle into a limiter and a valid counting characteristic' do
      # EE merges its own throttle into meta (its own limiter and the :path
      # characteristic), asserted in ee/spec; here we pin that every entry is
      # classified into some limiter and counts by a known discriminator. The SDK's
      # Rule expects characteristics as an array, so the registry already stores them
      # that way (no array-wrapping in Limiters).
      entries.each_value do |entry|
        expect(entry.limiter).to be_present
        expect(entry.characteristics).to be_an(Array).and(be_present)
        expect(entry.characteristics).to all(
          be_in(%i[ip requester_id requester_type aid path])
        )
      end
    end

    it 'presence-gates every nil-able discriminator in its match' do
      # requester_id / aid are nil for an unauthenticated (or non-collector, or
      # allowlisted) request, so a rule counting by one must gate on that value being
      # present (a /./ matcher) or it would fire for a request that carries no such
      # identifier. The gate is on the id (the field that is nil when no requester
      # resolved), not the type; ip, path and requester_type need no gate. This guards
      # the invariant the old PRESENCE_GATED_CHARACTERISTICS list enforced, now that
      # the gate lives in each static match.
      gateable = %i[requester_id aid]

      entries.each_value do |entry|
        (entry.characteristics & gateable).each do |char|
          expect(entry.match[char]).to eq(/./),
            "expected #{entry.rule_name} to presence-gate #{char} (match[#{char}] == /./)"
        end
      end
    end

    it 'derives labkit-valid rule names from the registry key' do
      entries.each do |rule_id, entry|
        expect(entry.rule_name).to eq(rule_id.delete_prefix('throttle_'))
        expect(entry.rule_name).to match(/\A[a-z0-9_]+\z/)
      end
    end

    it 'raises if the registry names a throttle Rack::Attack does not define' do
      allow(Gitlab::RackAttack).to receive(:all_throttle_definitions).and_return({})

      expect { described_class.all }.to raise_error(KeyError, /unknown throttle/)
    end
  end

  describe 'classification matches' do
    it 'gives every throttle a non-empty match over fact keys, with matcher-valued values' do
      described_class.all.each_value do |entry|
        expect(entry.match).to be_present
        expect(entry.match.keys).to all(be_a(Symbol))
        # values are what Labkit's Matcher accepts: a Regexp (path or the /./ presence
        # gate), a String (method), a boolean (classification / enable settings), or
        # nil (the unauthenticated rules' requester_id / runner_id absence gate).
        expect(entry.match.values).to all(be_a(Regexp).or(be_a(String)).or(be_in([true, false, nil])))
      end
    end

    it 'references only facts that ClassifiedRequest produces' do
      # The middleware matches each throttle's :match against the facts
      # ClassifiedRequest builds, so a typo'd or renamed fact key would silently
      # never fire. Pin the registry's match keys - the throttle rules and the
      # synthetic skip rules - to the classifier's fact set (this covers EE too:
      # under EE both sides gain the incident throttle and verified_geo_request keys).
      throttle_keys = described_class.all.values.flat_map { |entry| entry.match.keys }
      skip_keys = described_class.skip_matches.values.flat_map(&:keys)
      match_keys = (throttle_keys + skip_keys).uniq
      produced = Gitlab::RackAttack::LabkitRateLimit::ClassifiedRequest
        .new(Rack::MockRequest.env_for('/')).labkit_facts.keys

      expect(produced).to include(*match_keys)
    end
  end

  describe 'the web throttle disjunction' do
    # web_request? OR frontend_request? cannot be one AND-match, so each web throttle
    # is a web-path rule (WEB_PATH_REGEX) plus a frontend companion (the frontend fact)
    # as a sibling entry backing the same throttle, with its own counter (rule_name).
    {
      'throttle_unauthenticated_web' => 'throttle_unauthenticated_web_frontend',
      'throttle_authenticated_web' => 'throttle_authenticated_web_frontend'
    }.each do |web_id, frontend_id|
      it "expresses #{web_id} as a WEB_PATH_REGEX rule and a frontend companion" do
        entries = described_class.all
        web = entries.fetch(web_id)
        frontend = entries.fetch(frontend_id)

        expect(web.match[:path]).to eq(described_class::WEB_PATH_REGEX)
        expect(frontend.match).to include(frontend: true)
        expect(frontend.match).not_to have_key(:path)
        # The companion is its own rule (counter) but the same backing throttle.
        expect(frontend.rule_name).to eq(frontend_id.delete_prefix('throttle_'))
        expect(frontend.name).to eq(web_id)
        expect(frontend.cohort).to eq(web.cohort)
      end
    end
  end

  describe '.skip_matches' do
    it 'gates each path skip on an unauthenticated request' do
      described_class.skip_matches.each_value do |match|
        expect(match).to include(requester_id: nil, runner_id: nil)
      end
    end

    it 'matches the internal API, health and container-registry paths', :aggregate_failures do
      skip_matches = described_class.skip_matches

      expect(skip_matches['skip_internal_api'][:path].match?('/api/v4/internal/allowed')).to be(true)
      expect(skip_matches['skip_health_checks'][:path].match?('/-/health')).to be(true)
      expect(skip_matches['container_registry_event_path'][:path].match?('/api/v4/container_registry_event/x'))
        .to be(true)
      expect(skip_matches['skip_internal_api'][:path].match?('/api/v4/projects')).to be(false)
    end
  end

  describe 'WEB_PATH_REGEX' do
    using RSpec::Parameterized::TableSyntax

    # Parity guard: the native web matcher must classify a path exactly as the
    # predicate it replaces (web_request? == !api_request? && !health_check_request?).
    # If API_PATH_REGEX or the health family changes and the lookahead stops tracking
    # it, this fails - which is the whole point of building the end state now.
    def request_for(path)
      Gitlab::RackAttack::LabkitRateLimit::ClassifiedRequest.new(Rack::MockRequest.env_for(path))
    end

    where(:path, :web) do
      '/'                | true   # plain web
      '/dashboard'       | true
      '/groups/foo'      | true
      '/api'             | true   # no trailing slash, so not an API path
      '/apiv2/things'    | true   # /api not on a boundary
      '/-/metric'        | true   # not the health family (metrics, with the s)
      '/-/other'         | true
      '/api/v4/projects' | false  # API path
      '/oauth/authorize' | false  # /oauth/ at the start
      '/foo/oauth/token' | false  # /oauth/ matches anywhere, not just the start
      '/-/health'        | false  # health family
      '/-/liveness'      | false
      '/-/readiness'     | false
      '/-/metrics'       | false
      '/-/healthz'       | false  # health-family prefix
    end

    with_them do
      it 'matches a path iff the request is web_request?' do
        request = request_for(path)

        expect(described_class::WEB_PATH_REGEX.match?(request.logical_path)).to eq(web)
        expect(described_class::WEB_PATH_REGEX.match?(request.logical_path)).to eq(request.web_request?)
      end
    end
  end

  describe '.cohorts' do
    it 'lists the distinct cohorts ascending' do
      expect(described_class.cohorts).to eq([1, 2, 3])
    end
  end

  describe '.flag_basis' do
    it 'namespaces the basis so it cannot collide with the ApplicationRateLimiter cohorts' do
      expect(described_class.flag_basis(3)).to eq('rack_cohort_3')
    end
  end

  describe 'feature flags' do
    it 'has a shadow and enforce wip flag for every cohort' do
      described_class.cohorts.each do |cohort|
        basis = described_class.flag_basis(cohort)

        expect(Feature::Definition.definitions)
          .to include(:"rate_limiter_use_labkit_#{basis}", :"rate_limiter_use_labkit_#{basis}_enforce")
      end
    end
  end
end
