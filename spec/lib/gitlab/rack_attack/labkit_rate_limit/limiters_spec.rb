# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RackAttack::LabkitRateLimit::Limiters, feature_category: :rate_limiting do
  let(:registry) { Gitlab::RackAttack::LabkitRateLimit::ThrottleRegistry }

  after do
    described_class.reset!
  end

  describe '.all' do
    before do
      allow(Labkit::RateLimit::Rule).to receive(:new).and_call_original
    end

    it 'builds each throttle rule with action :limit by default' do
      described_class.all

      expect(Labkit::RateLimit::Rule).to have_received(:new)
        .with(hash_including(name: 'unauthenticated_web', action: :limit))
    end

    it 'builds every rule regardless of cohort (universal presence)', :aggregate_failures do
      limiters = described_class.all

      expect(limiters.keys).to include(registry::GENERAL, registry::PROTECTED)
      # a cohort-1 and a cohort-3 throttle are both built without any cohort being
      # passed in: cohort gates enforcement, not presence.
      expect(Labkit::RateLimit::Rule).to have_received(:new).with(hash_including(name: 'unauthenticated_packages_api'))
      expect(Labkit::RateLimit::Rule).to have_received(:new).with(hash_including(name: 'authenticated_git_http'))
    end

    it 'builds the rule match from the registry, with no cohort key' do
      entry = registry.all.fetch('throttle_unauthenticated_web')
      described_class.all

      expect(Labkit::RateLimit::Rule).to have_received(:new)
        .with(hash_including(name: entry.rule_name, match: entry.match))
    end

    # enforced_response and annotate_rate_limit_headers resolve a counted rule
    # back to its throttle via ThrottleRegistry.by_rule_name; a counting rule not
    # named after a registry entry would silently lose its 429s and headers.
    it 'names every counting rule after a registry entry, so a matched rule always resolves to its throttle' do
      built_rules = []
      allow(Labkit::RateLimit::Rule).to receive(:new).and_wrap_original do |original, **kwargs|
        built_rules << kwargs
        original.call(**kwargs)
      end

      described_class.all

      counting_rule_names = built_rules.reject { |kwargs| kwargs[:action] == :skip }.map { |kwargs| kwargs[:name] }

      expect(counting_rule_names).not_to be_empty
      expect(registry.by_rule_name.keys).to include(*counting_rule_names)
    end

    it 'follows each claiming throttle rule with a terminating claim of the same match' do
      # labkit evaluates every matching rule, so the claim is what stops a
      # specialized request also being counted by the general rules below it.
      # The registry declares the claim (claims: true); the match is derived
      # from the entry's own, never written out.
      entry = registry.all.fetch('throttle_unauthenticated_web')
      described_class.all

      expect(Labkit::RateLimit::Rule).to have_received(:new)
        .with(hash_including(name: 'unauthenticated_web_claim', match: entry.match, action: :skip))
    end

    it 'builds only the counting rule for an entry that does not declare a claim' do
      entries = registry.all
      entries.fetch('throttle_unauthenticated_web').claims = false
      allow(registry).to receive(:all).and_return(entries)
      described_class.all

      expect(Labkit::RateLimit::Rule).to have_received(:new)
        .with(hash_including(name: 'unauthenticated_web', action: :limit))
      expect(Labkit::RateLimit::Rule).not_to have_received(:new)
        .with(hash_including(name: 'unauthenticated_web_claim'))
    end

    it 'builds each web throttle as one rule, keeping the throttle on a single counter' do
      # The rule name keys the Redis counter; web_or_frontend carries the
      # disjunction that would otherwise need two rules (and so two counters).
      web = registry.all.fetch('throttle_unauthenticated_web')
      described_class.all

      expect(Labkit::RateLimit::Rule).to have_received(:new)
        .with(hash_including(name: 'unauthenticated_web', match: web.match, action: :limit)).once
      expect(Labkit::RateLimit::Rule).not_to have_received(:new)
        .with(hash_including(name: 'unauthenticated_web_frontend'))
    end

    describe 'synthetic terminating rules' do
      it 'gives every limiter a first-position bypass rule that permits and terminates without counting' do
        described_class.all

        expect(Labkit::RateLimit::Rule).to have_received(:new)
          .with(hash_including(name: 'bypass_header', match: { bypass: true },
            characteristics: [:ip], action: :skip)).at_least(:once)
      end

      it 'builds one unauthenticated skip rule per registry skip_match' do
        described_class.all

        registry.skip_matches.each do |name, match|
          expect(Labkit::RateLimit::Rule).to have_received(:new)
            .with(hash_including(name: name, match: match, action: :skip)).at_least(:once)
        end
      end

      it 'adds a runner-jobs skip rule on the general limiter' do
        described_class.all

        expect(Labkit::RateLimit::Rule).to have_received(:new)
          .with(hash_including(name: 'runner_jobs',
            match: { runner_jobs: true, requester_id: /./ }, action: :skip))
      end
    end

    context 'when a user allowlist is configured' do
      before do
        allow(::Gitlab::RackAttack).to receive(:user_allowlist)
          .and_return(Gitlab::RackAttack::UserAllowlist.new('7,42'))
      end

      it 'builds the allowlist skip rule matching the stringified ids' do
        described_class.all

        expect(Labkit::RateLimit::Rule).to have_received(:new)
          .with(hash_including(name: 'user_allowlist', action: :skip,
            match: { requester_type: 'user', requester_id: { oneOf: %w[7 42] } })).at_least(:once)
      end

      it 'places the skip rule with the synthetic skips, ahead of every throttle rule, on every limiter' do
        limiter_rules = {}
        allow(Labkit::RateLimit::Limiter).to receive(:new).and_wrap_original do |original, **kwargs|
          limiter_rules[kwargs[:name]] = kwargs[:rules].map(&:name)
          original.call(**kwargs)
        end

        described_class.all

        expect(limiter_rules).not_to be_empty
        limiter_rules.each do |limiter_name, names|
          expect(names.first(2)).to eq(%w[bypass_header user_allowlist]),
            "#{limiter_name} starts with #{names.first(3)}"
        end
      end
    end

    context 'when the user allowlist is empty' do
      it 'builds no allowlist rule' do
        allow(::Gitlab::RackAttack).to receive(:user_allowlist)
          .and_return(Gitlab::RackAttack::UserAllowlist.new(nil))
        described_class.all

        expect(Labkit::RateLimit::Rule).not_to have_received(:new)
          .with(hash_including(name: 'user_allowlist'))
      end
    end

    context 'when a throttle is in dry-run mode' do
      before do
        stub_env('GITLAB_THROTTLE_DRY_RUN', 'throttle_unauthenticated_web')
      end

      it 'builds the dry-run rule with action :log so the metric fires correctly' do
        described_class.all

        expect(Labkit::RateLimit::Rule).to have_received(:new)
          .with(hash_including(name: 'unauthenticated_web', action: :log))
      end

      it 'follows the dry-run rule with a terminating skip bypass of the same match' do
        entry = registry.all.fetch('throttle_unauthenticated_web')
        described_class.all

        expect(Labkit::RateLimit::Rule).to have_received(:new)
          .with(hash_including(name: 'unauthenticated_web_dry_run_bypass', match: entry.match, action: :skip))
      end

      it 'omits the dry-run bypass for an entry that does not declare a claim' do
        # One declaration governs both shapes: the bypass is the claim in its
        # dry-run form.
        entries = registry.all
        entries.fetch('throttle_unauthenticated_web').claims = false
        allow(registry).to receive(:all).and_return(entries)
        described_class.all

        expect(Labkit::RateLimit::Rule).to have_received(:new)
          .with(hash_including(name: 'unauthenticated_web', action: :log))
        expect(Labkit::RateLimit::Rule).not_to have_received(:new)
          .with(hash_including(name: 'unauthenticated_web_dry_run_bypass'))
      end
    end
  end

  # Classification selection: run a representative request's facts through the real
  # limiter and assert which single rule it selects. This is the faithfulness check
  # for the registry ordering and matchers, covering both over-classification (a rule
  # claiming a request it should not) and under-classification (missing one). The wip
  # cohort flags default OFF in the test env, so this drives the limiter directly with
  # every rule present.
  describe 'classification selection', :clean_gitlab_redis_rate_limiting do
    let(:general) { described_class.all.fetch(registry::GENERAL) }
    let(:protected_limiter) { described_class.all.fetch(registry::PROTECTED) }

    # Representative request paths that match each throttle's path regex.
    paths = {
      collector: '/-/collector/i',
      api: '/api/v4/projects',
      packages: '/api/v4/projects/1/packages/npm/foo',
      files: '/api/v4/projects/1/repository/files/app.rb',
      git: '/gitlab-org/gitlab.git/info/refs',
      git_lfs: '/gitlab-org/gitlab.git/info/lfs/objects/batch'
    }

    # All facts false/absent except the overrides, so each row states exactly the
    # facts a representative request of that throttle carries. Keys come from the
    # classifier, so a renamed fact surfaces here too.
    def facts(**overrides)
      keys = Gitlab::RackAttack::LabkitRateLimit::ClassifiedRequest
        .new(Rack::MockRequest.env_for('/')).labkit_facts.keys
      keys.index_with { false }
        .merge(
          ip: '1.2.3.4',
          requester_id: nil, requester_type: nil, runner_id: nil,
          aid: nil, path: '/', method: 'GET', **overrides
        )
    end

    # The rule that terminated evaluation. An enforced throttle terminates on its
    # claim skip (the counting rule itself never terminates under labkit's
    # evaluate-all semantics), so the claim suffix is stripped: the selection
    # under test is the throttle, not the mechanism. Synthetic skips (bypass,
    # skip_*, runner_jobs) and dry-run bypasses keep their own names.
    def selected_in(limiter, **overrides)
      result = limiter.check(facts(**overrides))
      result.rule.name.delete_suffix('_claim') if result.matched?
    end

    # The git rows carry web_or_frontend: true (a git path is a web request) with the
    # matching web throttle setting on, so they also assert the git rules are ordered
    # before - and so exclude - the web rules.
    # Unauthenticated rows carry no requester_id/runner_id override, so the facts
    # helper's nil defaults are the unauthenticated? decomposition the rules gate on.
    general_cases = {
      'product_analytics_collector' => { path: paths[:collector], aid: 'app-1' },
      'unauthenticated_packages_api' => {
        path: paths[:packages], setting_unauthenticated_packages: true
      },
      'authenticated_packages_api' => {
        path: paths[:packages], setting_authenticated_packages: true,
        requester_type: 'user', requester_id: '1'
      },
      'unauthenticated_files_api' => {
        path: paths[:files], setting_unauthenticated_files: true
      },
      'authenticated_files_api' => {
        path: paths[:files], setting_authenticated_files: true,
        requester_type: 'user', requester_id: '1'
      },
      'unauthenticated_deprecated_api' => {
        deprecated: true, setting_unauthenticated_deprecated: true
      },
      'authenticated_deprecated_api' => {
        deprecated: true, setting_authenticated_deprecated: true,
        requester_type: 'user', requester_id: '1'
      },
      'unauthenticated_web' => {
        path: '/dashboard', web_or_frontend: true, setting_unauthenticated_web: true
      },
      'authenticated_web' => {
        path: '/dashboard', web_or_frontend: true, setting_authenticated_web: true,
        requester_type: 'user', requester_id: '1'
      },
      'unauthenticated_api' => { path: paths[:api], setting_unauthenticated_api: true },
      'authenticated_api' => {
        path: paths[:api], setting_authenticated_api: true,
        requester_type: 'user', requester_id: '1'
      },
      'unauthenticated_git_http' => {
        path: paths[:git], web_or_frontend: true, setting_unauthenticated_git_http: true,
        setting_unauthenticated_web: true
      },
      'authenticated_git_http' => {
        path: paths[:git], web_or_frontend: true, setting_authenticated_git_http: true,
        setting_authenticated_web: true, requester_type: 'user', requester_id: '1'
      },
      'authenticated_git_lfs' => {
        path: paths[:git_lfs], web_or_frontend: true, setting_authenticated_git_lfs: true,
        setting_authenticated_web: true, requester_type: 'user', requester_id: '1'
      }
    }

    general_cases.each do |throttle, request_facts|
      it "selects #{throttle} for its representative request" do
        expect(selected_in(general, **request_facts)).to eq(throttle)
      end
    end

    it 'counts a frontend request on an API path under the web throttle, not the API throttle' do
      # The API rules' frontend: false gate keeps Rack::Attack's !frontend_request?
      # exclusion even with the web throttle setting off.
      frontend_api = {
        path: paths[:api], frontend: true, web_or_frontend: true,
        setting_unauthenticated_api: true
      }

      expect(selected_in(general, **frontend_api, setting_unauthenticated_web: true)).to eq('unauthenticated_web')
      expect(selected_in(general, **frontend_api, setting_unauthenticated_web: false)).to be_nil
    end

    it 'accumulates web-page and frontend-API requests from one IP on a single counter' do
      # The regression this MR fixes: two rules would split the counter and the IP
      # would reach the limit later than under Rack::Attack.
      web_page = general.check(
        facts(path: '/dashboard', web_or_frontend: true, setting_unauthenticated_web: true))
      frontend_api = general.check(
        facts(path: paths[:api], frontend: true, web_or_frontend: true, setting_unauthenticated_web: true))

      # An under-limit check terminates on the claim skip, so the counted throttle
      # evaluation is read off #evaluations.
      expect(web_page.evaluations.first.rule.name).to eq('unauthenticated_web')
      expect(frontend_api.evaluations.first.rule.name).to eq('unauthenticated_web')
      expect(web_page.evaluations.first.info.count).to eq(1)
      expect(frontend_api.evaluations.first.info.count).to eq(2)
    end

    it 'lets the collector rule claim a collector request, leaving it out of the web counter' do
      # Rack::Attack counts a collector request under both throttles (a collector
      # path is also a web path); the claim is a known, accepted divergence.
      expect(selected_in(general,
        path: paths[:collector], aid: 'app-1', web_or_frontend: true,
        setting_unauthenticated_web: true)).to eq('product_analytics_collector')
    end

    protected_cases = {
      'unauthenticated_protected_paths' => {
        method: 'POST', protected_path: true, setting_protected_paths: true
      },
      'authenticated_protected_paths_api' => {
        method: 'POST', path: paths[:api], protected_path: true, setting_protected_paths: true,
        requester_type: 'user', requester_id: '1'
      },
      'authenticated_get_protected_paths_web' => {
        method: 'GET', path: '/dashboard', protected_path: true, setting_protected_paths: true,
        requester_type: 'user', requester_id: '1'
      }
    }

    protected_cases.each do |throttle, request_facts|
      it "selects #{throttle} in the protected-paths limiter" do
        expect(selected_in(protected_limiter, **request_facts)).to eq(throttle)
      end
    end

    it 'skips an unauthenticated internal/health/registry request before any throttle' do
      expect(selected_in(general,
        path: '/-/health', setting_unauthenticated_api: true)).to eq('skip_health_checks')
    end

    it 'skips a job-token request on the runner-jobs path before the authenticated API throttle' do
      expect(selected_in(general,
        path: '/api/v4/jobs/1', runner_jobs: true, setting_authenticated_api: true,
        requester_type: 'user', requester_id: '1')).to eq('runner_jobs')
    end

    it 'counts a PAT-authenticated request on the runner-jobs path under the authenticated API throttle' do
      # Only runner- or job-token-authenticated requests are exempt from the
      # authenticated API throttle on the jobs path (runner_jobs fact); a bot
      # polling job status with a PAT is ordinary API usage and stays counted.
      expect(selected_in(general,
        path: '/api/v4/jobs/1', setting_authenticated_api: true,
        requester_type: 'user', requester_id: '1')).to eq('authenticated_api')
    end

    it 'lets a runner-token request escape every throttle (no requester, runner_id present)' do
      # A runner registration token has no requester, so no authenticated rule matches,
      # and runner_id present fails the unauthenticated rules' runner_id: nil gate.
      expect(selected_in(general,
        path: paths[:api], runner_id: '5',
        setting_unauthenticated_api: true, setting_authenticated_api: true)).to be_nil
    end

    it 'lets a runner-token request on the runner-jobs path escape every rule including the skip' do
      # The runner_jobs skip carries a requester presence gate, so a runner-token
      # request is not claimed by it and escapes unmatched, as on every other path.
      expect(selected_in(general,
        path: '/api/v4/jobs/request', runner_jobs: true, runner_id: '5',
        setting_unauthenticated_api: true, setting_authenticated_api: true)).to be_nil
    end

    it 'falls through to general API when the packages throttle is disabled' do
      expect(selected_in(general,
        path: paths[:packages], setting_unauthenticated_api: true,
        setting_unauthenticated_packages: false)).to eq('unauthenticated_api')
    end

    context 'when a specialized throttle is in dry-run mode' do
      before do
        stub_env('GITLAB_THROTTLE_DRY_RUN', 'throttle_unauthenticated_packages_api')
      end

      # The :log packages rule does not terminate, so without its terminating allow
      # the request would fall through to unauthenticated_api (a packages path is also
      # an API path) and be enforced there - a divergence from Rack::Attack, whose
      # !throttle_packages? exclusion holds whether or not packages is tracked.
      it 'short-circuits the packages request on its bypass instead of the general API rule' do
        expect(selected_in(general,
          path: paths[:packages], setting_unauthenticated_api: true,
          setting_unauthenticated_packages: true)).to eq('unauthenticated_packages_api_dry_run_bypass')
      end
    end

    it 'lets authenticated web claim a git-lfs request when the lfs throttle is disabled (fallthrough)' do
      expect(selected_in(general,
        path: paths[:git_lfs], web_or_frontend: true, requester_type: 'user', requester_id: '1',
        setting_authenticated_web: true, setting_authenticated_git_lfs: false)).to eq('authenticated_web')
    end

    it 'selects nothing when no rule classification holds' do
      expect(selected_in(general, ip: '1.2.3.4')).to be_nil
    end

    it 'suppresses an authenticated rule when its discriminator is absent' do
      # The presence gate (requester_id: /./ in the match) is what stops an
      # authenticated rule firing for a request that resolved no requester - the
      # equivalent of the Rack::Attack lambda returning nil. Only the
      # authenticated throttle is enabled here, so with the id absent nothing matches.
      expect(selected_in(general,
        path: paths[:api], setting_authenticated_api: true,
        requester_id: nil, requester_type: nil)).to be_nil
    end

    context 'with a user allowlist configured' do
      before do
        allow(::Gitlab::RackAttack).to receive(:user_allowlist)
          .and_return(Gitlab::RackAttack::UserAllowlist.new('7'))
      end

      it 'claims an allowlisted user on the skip rule before the identity throttles' do
        expect(selected_in(general,
          path: paths[:api], requester_type: 'user', requester_id: '7',
          setting_authenticated_api: true, setting_unauthenticated_api: true)).to eq('user_allowlist')
      end

      it 'claims an allowlisted user in the protected-paths limiter too' do
        expect(selected_in(protected_limiter,
          method: 'POST', protected_path: true, setting_protected_paths: true,
          requester_type: 'user', requester_id: '7')).to eq('user_allowlist')
      end

      it 'claims an allowlisted user before the aid-keyed collector throttle (full bypass)' do
        # Wider than Rack::Attack's safelist on purpose: the collector path has
        # been dead since 13.3 (gitlab-com/gl-infra/production-engineering#29563).
        expect(selected_in(general,
          path: paths[:collector], aid: 'app-1',
          requester_type: 'user', requester_id: '7')).to eq('user_allowlist')
      end

      it 'counts a non-allowlisted user as usual' do
        expect(selected_in(general,
          path: paths[:api], requester_type: 'user', requester_id: '8',
          setting_authenticated_api: true)).to eq('authenticated_api')
      end

      it 'counts a deploy token sharing the allowlisted numeric id (the type gate)' do
        expect(selected_in(general,
          path: paths[:api], requester_type: 'deploy_token', requester_id: '7',
          setting_authenticated_api: true)).to eq('authenticated_api')
      end
    end

    describe 'counting by the requester pair' do
      def check_api(type:, id:)
        general.check(facts(
          path: '/api/v4/projects', setting_authenticated_api: true,
          requester_type: type, requester_id: id
        ))
      end

      # An under-limit check terminates on the claim skip, which carries no
      # counter, so the counted throttle evaluation is read off #evaluations.
      def counted(result)
        result.evaluations.first
      end

      it 'collides two requests with the same (type, id) on one counter' do
        first = check_api(type: 'user', id: '42')
        second = check_api(type: 'user', id: '42')

        expect(counted(first).rule.name).to eq('authenticated_api')
        expect(counted(second).info.count).to eq(2)
      end

      it 'keeps a DeployToken and a User with the same numeric id on separate counters' do
        user = check_api(type: 'user', id: '42')
        deploy_token = check_api(type: 'deploy_token', id: '42')

        # Distinct counters: each first hit on its own key reads count 1, so the type
        # segment is part of the redis key (a DeployToken does not bump the User key).
        expect(counted(user).info.count).to eq(1)
        expect(counted(deploy_token).info.count).to eq(1)
      end

      it 'keeps two different ids of the same type on separate counters' do
        first = check_api(type: 'user', id: '1')
        second = check_api(type: 'user', id: '2')

        expect(counted(first).info.count).to eq(1)
        expect(counted(second).info.count).to eq(1)
      end
    end
  end
end
