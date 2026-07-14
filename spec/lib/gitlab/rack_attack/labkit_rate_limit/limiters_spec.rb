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

    it 'builds each throttle rule with action :block by default' do
      described_class.all

      expect(Labkit::RateLimit::Rule).to have_received(:new)
        .with(hash_including(name: 'unauthenticated_web', action: :block))
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

    it 'builds the web-path rule and its frontend companion as sibling :block rules' do
      # The companion is its own registry entry (its own counter/rule name) backing the
      # same throttle; both build as :block by default.
      web = registry.all.fetch('throttle_unauthenticated_web')
      frontend = registry.all.fetch('throttle_unauthenticated_web_frontend')
      described_class.all

      expect(Labkit::RateLimit::Rule).to have_received(:new)
        .with(hash_including(name: 'unauthenticated_web', match: web.match, action: :block))
      expect(Labkit::RateLimit::Rule).to have_received(:new)
        .with(hash_including(name: 'unauthenticated_web_frontend', match: frontend.match, action: :block))
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
            match: { path: Gitlab::RackAttack::Request::RUNNER_JOBS_PATH_REGEX, requester_id: /./ }, action: :skip))
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

      it 'shapes the frontend companion as its own dry-run log rule and bypass' do
        # The companion is the same Rack::Attack throttle, so it follows the same
        # dry-run state: a :log rule and its own terminating :skip, keyed by the
        # companion name so it does not collide with the web-path rule's counter.
        frontend_match = registry.all.fetch('throttle_unauthenticated_web_frontend').match
        described_class.all

        expect(Labkit::RateLimit::Rule).to have_received(:new)
          .with(hash_including(name: 'unauthenticated_web_frontend', match: frontend_match, action: :log))
        expect(Labkit::RateLimit::Rule).to have_received(:new)
          .with(hash_including(name: 'unauthenticated_web_frontend_dry_run_bypass', match: frontend_match,
            action: :skip))
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

    def selected_in(limiter, **overrides)
      result = limiter.check(facts(**overrides))
      result.rule.name if result.matched?
    end

    # The git rows carry a git path, which also matches WEB_PATH_REGEX (a git path is
    # a web request), so they also assert the git rules are ordered before (and so
    # exclude) the web-path rule.
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
        path: '/dashboard', setting_unauthenticated_web: true
      },
      'authenticated_web' => {
        path: '/dashboard', setting_authenticated_web: true,
        requester_type: 'user', requester_id: '1'
      },
      # The frontend companion: a CSRF request on an API path (not a web path), which
      # the web-path rule misses but the frontend rule claims before the API rule.
      'unauthenticated_web_frontend' => {
        path: paths[:api], frontend: true, setting_unauthenticated_web: true
      },
      'authenticated_web_frontend' => {
        path: paths[:api], frontend: true, setting_authenticated_web: true,
        requester_type: 'user', requester_id: '1'
      },
      'unauthenticated_api' => { path: paths[:api], setting_unauthenticated_api: true },
      'authenticated_api' => {
        path: paths[:api], setting_authenticated_api: true,
        requester_type: 'user', requester_id: '1'
      },
      'unauthenticated_git_http' => {
        path: paths[:git], setting_unauthenticated_git_http: true
      },
      'authenticated_git_http' => {
        path: paths[:git], setting_authenticated_git_http: true,
        setting_authenticated_web: true, requester_type: 'user', requester_id: '1'
      },
      'authenticated_git_lfs' => {
        path: paths[:git_lfs], setting_authenticated_git_lfs: true,
        setting_authenticated_web: true, requester_type: 'user', requester_id: '1'
      }
    }

    general_cases.each do |throttle, request_facts|
      it "selects #{throttle} for its representative request" do
        expect(selected_in(general, **request_facts)).to eq(throttle)
      end
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

    it 'skips an authenticated request on the runner-jobs path before the authenticated API throttle' do
      expect(selected_in(general,
        path: '/api/v4/jobs/1', setting_authenticated_api: true,
        requester_type: 'user', requester_id: '1')).to eq('runner_jobs')
    end

    it 'lets a runner-token request escape every throttle (no requester, runner_id present)' do
      # A runner registration token has no requester, so no authenticated rule matches,
      # and runner_id present fails the unauthenticated rules' runner_id: nil gate.
      expect(selected_in(general,
        path: paths[:api], runner_id: '5',
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
        path: paths[:git_lfs], requester_type: 'user', requester_id: '1',
        setting_authenticated_web: true, setting_authenticated_git_lfs: false)).to eq('authenticated_web')
    end

    it 'selects nothing when no rule classification holds' do
      expect(selected_in(general, ip: '1.2.3.4')).to be_nil
    end

    it 'suppresses an authenticated rule when its discriminator is absent' do
      # The presence gate (requester_id: /./ in the match) is what stops an
      # authenticated rule firing for a request that resolved no requester - the
      # equivalent of the Rack::Attack lambda returning nil, and the path an
      # allowlisted user takes (the classifier nulls out the id). Only the
      # authenticated throttle is enabled here, so with the id absent nothing matches.
      expect(selected_in(general,
        path: paths[:api], setting_authenticated_api: true,
        requester_id: nil, requester_type: nil)).to be_nil
    end

    it 'exempts an allowlisted user (blank requester id) from both the authenticated and unauthenticated rules' do
      # A blank id fails the authenticated /./ gate and the unauthenticated nil gate,
      # so an allowlisted user is counted by neither - mirroring Rack::Attack, where an
      # allowlisted user has a nil throttled_identifer and unauthenticated? false. An
      # anonymous request (requester_id nil) on the same path still hits unauthenticated_api.
      expect(selected_in(general,
        path: paths[:api], requester_id: '',
        setting_authenticated_api: true, setting_unauthenticated_api: true)).to be_nil
    end

    describe 'counting by the requester pair' do
      def check_api(type:, id:)
        general.check(facts(
          path: '/api/v4/projects', setting_authenticated_api: true,
          requester_type: type, requester_id: id
        ))
      end

      it 'collides two requests with the same (type, id) on one counter' do
        first = check_api(type: 'user', id: '42')
        second = check_api(type: 'user', id: '42')

        expect(first.rule.name).to eq('authenticated_api')
        expect(second.info.count).to eq(2)
      end

      it 'keeps a DeployToken and a User with the same numeric id on separate counters' do
        user = check_api(type: 'user', id: '42')
        deploy_token = check_api(type: 'deploy_token', id: '42')

        # Distinct counters: each first hit on its own key reads count 1, so the type
        # segment is part of the redis key (a DeployToken does not bump the User key).
        expect(user.info.count).to eq(1)
        expect(deploy_token.info.count).to eq(1)
      end

      it 'keeps two different ids of the same type on separate counters' do
        first = check_api(type: 'user', id: '1')
        second = check_api(type: 'user', id: '2')

        expect(first.info.count).to eq(1)
        expect(second.info.count).to eq(1)
      end
    end
  end
end
