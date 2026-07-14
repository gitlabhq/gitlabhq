# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RackAttack::LabkitRateLimit::ClassifiedRequest, feature_category: :rate_limiting do
  def facts_for(path, env_overrides = {})
    env = Rack::MockRequest.env_for(path).merge(env_overrides)
    described_class.new(env).labkit_facts
  end

  describe '#labkit_facts' do
    describe 'identity and matcher-input values' do
      it 'carries the discriminator and matcher values, never coerced' do
        facts = facts_for('/api/v4/projects?aid=xyz', 'REMOTE_ADDR' => '1.2.3.4', 'REQUEST_METHOD' => 'POST')

        expect(facts).to include(ip: '1.2.3.4', path: '/api/v4/projects', aid: 'xyz', method: 'POST')
      end

      it 'resolves no requester or runner id for an unauthenticated request' do
        expect(facts_for('/api/v4/projects')).to include(
          requester_id: nil, requester_type: nil, runner_id: nil
        )
      end

      it 'uses the logical path, with the relative-URL-root prefix stripped' do
        allow(Gitlab.config.gitlab).to receive(:relative_url_root).and_return('/gitlab')

        expect(facts_for('/gitlab/api/v4/projects')).to include(path: '/api/v4/projects')
      end
    end

    describe 'classification facts' do
      it 'is not a frontend request without a verified CSRF token' do
        # web_request? is no longer a fact (the registry matches it as WEB_PATH_REGEX);
        # frontend is the one web-side fact left, since it is CSRF/session-based and
        # cannot be a path matcher. A plain request carries no CSRF token.
        expect(facts_for('/dashboard')).to include(frontend: false)
        expect(facts_for('/api/v4/projects')).to include(frontend: false)
      end

      it 'reflects the bypass header only when set to 1', :aggregate_failures do
        allow(Gitlab::Throttle).to receive(:bypass_header).and_return('HTTP_X_BYPASS')

        expect(facts_for('/x', 'HTTP_X_BYPASS' => '1')).to include(bypass: true)
        expect(facts_for('/x', 'HTTP_X_BYPASS' => '0')).to include(bypass: false)
        expect(facts_for('/x')).to include(bypass: false)
      end
    end

    # The single protected_path fact is method-aware: a GET matches against the
    # GET protected-paths list, any other method against the POST list. This is the
    # collapsed form of the old protected_path? (POST) / get_request_protected_path?
    # (GET) pair; each rule's own `method:` gate is what pairs the fact with the list
    # its method selected, so one fact serves both the POST and GET throttles.
    describe 'the method-aware protected_path fact' do
      before do
        stub_application_setting(
          protected_paths: ['/users/sign_in'],
          protected_paths_for_get_request: ['/dashboard']
        )
      end

      it 'matches a GET against the GET list, not the POST list', :aggregate_failures do
        expect(facts_for('/dashboard', 'REQUEST_METHOD' => 'GET')).to include(protected_path: true)
        expect(facts_for('/users/sign_in', 'REQUEST_METHOD' => 'GET')).to include(protected_path: false)
      end

      it 'matches a POST against the POST list, not the GET list', :aggregate_failures do
        expect(facts_for('/users/sign_in', 'REQUEST_METHOD' => 'POST')).to include(protected_path: true)
        expect(facts_for('/dashboard', 'REQUEST_METHOD' => 'POST')).to include(protected_path: false)
      end
    end

    # The web-before-api ordering rests on a real frontend request (an API path with
    # a verified CSRF token) producing frontend: true, so the web throttle's frontend
    # companion claims it before the API rule. The synthetic selection spec proves the
    # ordering given the fact; this proves a real frontend request produces it.
    describe 'a frontend request on an API path' do
      it 'is frontend even though the path is an API path' do
        allow(Gitlab::RequestForgeryProtection).to receive(:verified?).and_return(true)

        facts = facts_for('/api/v4/projects',
          'HTTP_X_CSRF_TOKEN' => 'token', 'rack.session' => { _csrf_token: 'token' })

        expect(facts).to include(frontend: true, path: '/api/v4/projects')
      end
    end

    # A runner-authenticated request has no requester but a runner_id, so the
    # unauthenticated rules' `runner_id: nil` guard keeps it out of the IP throttles.
    describe 'a runner-authenticated request' do
      it 'has a runner_id and no requester' do
        request = described_class.new(Rack::MockRequest.env_for('/api/v4/jobs/request'))
        runner = instance_double(Ci::Runner, id: 1)
        authenticator = instance_double(Gitlab::Auth::RequestAuthenticator,
          find_authenticated_requester: nil, runner: runner)
        allow(request).to receive(:request_authenticator).and_return(authenticator)

        expect(request.labkit_facts).to include(runner_id: '1', requester_id: nil)
      end
    end

    describe 'enable settings the rules match on' do
      it 'reflects the application settings each rule matches on' do
        stub_application_setting(
          throttle_unauthenticated_api_enabled: true,
          throttle_authenticated_web_enabled: false,
          throttle_protected_paths_enabled: true
        )

        expect(facts_for('/api/v4/projects')).to include(
          setting_unauthenticated_api: true,
          setting_authenticated_web: false,
          setting_protected_paths: true
        )
      end
    end

    describe 'strict-boolean coercion' do
      # deprecated_api_request? returns nil (not false) when with_projects is an
      # unparseable string, because Gitlab::Utils.to_boolean returns nil. The rule
      # matcher compares with ==, so an uncoerced nil would diverge from Rack::Attack,
      # which reads nil as falsy. So coerce it.
      it 'coerces a nil predicate result to false (deprecated API, unparseable with_projects)' do
        expect(facts_for('/api/v4/groups/1?with_projects=garbage')).to include(deprecated: false)
      end

      it 'returns a strict boolean for every classification fact' do
        raw_keys = %i[ip requester_id requester_type runner_id aid path method]
        classification = facts_for('/api/v4/projects').except(*raw_keys)

        expect(classification.values).to all(be_in([true, false]))
      end
    end

    describe 'authenticated request' do
      let(:request) { described_class.new(Rack::MockRequest.env_for('/api/v4/projects')) }

      def stub_requester(type:, id:)
        allow(request).to receive(:authenticated_identifier)
          .and_return({ identifier_type: type, identifier_id: id })
      end

      it 'splits the resolved requester into a stringified id and type' do
        stub_requester(type: :user, id: 1)

        expect(request.labkit_facts).to include(requester_id: '1', requester_type: 'user')
      end

      it 'stringifies an integer id so the presence-gate regex does not raise and fail open' do
        # requester.id is an Integer; the presence gate matches it with a Regexp, and
        # Regexp#match? raises TypeError on an Integer (which the Labkit evaluator
        # would catch and fail open). The id must therefore be a String.
        stub_requester(type: :user, id: 42)

        expect(request.labkit_facts[:requester_id]).to eq('42')
        expect { /./.match?(request.labkit_facts[:requester_id]) }.not_to raise_error
      end

      it 'keeps a DeployToken and a User with the same numeric id distinct via the type fact' do
        stub_requester(type: :deploy_token, id: 1)

        expect(request.labkit_facts).to include(requester_id: '1', requester_type: 'deploy_token')
      end

      it 'blanks an allowlisted user so it is exempt from both the presence gate and the nil gate' do
        # A blank id (not nil) is the allowlisted marker: it fails the authenticated
        # rules' /./ gate and the unauthenticated rules' nil gate, so no identity
        # throttle counts it, while a nil id would make it look anonymous.
        allow(::Gitlab::RackAttack).to receive(:user_allowlist).and_return(Set.new([7]))
        stub_requester(type: :user, id: 7)

        expect(request.labkit_facts).to include(requester_id: '', requester_type: '')
      end

      it 'does not set the throttle safelist instrumentation for an allowlisted user', :request_store do
        allow(::Gitlab::RackAttack).to receive(:user_allowlist).and_return(Set.new([7]))
        stub_requester(type: :user, id: 7)
        Gitlab::Instrumentation::Throttle.safelist = nil

        request.labkit_facts

        expect(Gitlab::Instrumentation::Throttle.safelist).to be_nil
      end
    end
  end
end
