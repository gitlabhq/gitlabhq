# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ApplicationRateLimiter::LabkitAdapter,
  :clean_gitlab_redis_rate_limiting, :prometheus, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe '.set_mode?' do
    it 'returns true for entries with count_distinct (set-mode rules)' do
      allow(Gitlab::ApplicationRateLimiter::LabkitAdapter::SupportedRateLimits).to receive(:all).and_return(
        fake_key: { count_distinct: :project_id, characteristics: %i[user], action: :block }
      )

      expect(described_class.set_mode?(:fake_key)).to be(true)
    end

    it 'returns false for INCR-mode entries' do
      expect(described_class.set_mode?(:pipelines_create)).to be(false)
    end

    it 'returns false for keys not in the registry' do
      expect(described_class.set_mode?(:not_a_registered_key)).to be(false)
    end
  end

  describe '.cost_mode?' do
    it 'returns true for a resource-usage (cost-mode) entry' do
      expect(described_class.cost_mode?(:main_db_duration_limit_per_worker)).to be(true)
    end

    it 'returns false for an INCR-mode entry' do
      expect(described_class.cost_mode?(:pipelines_create)).to be(false)
    end

    it 'returns false for keys not in the registry' do
      expect(described_class.cost_mode?(:not_a_registered_key)).to be(false)
    end
  end

  describe '.run!' do
    context 'when called repeatedly within a single period' do
      it 'increments the same labkit counter' do
        described_class.run!(:users_get_by_id, scope: user)
        described_class.run!(:users_get_by_id, scope: user)

        count = Gitlab::Redis::RateLimiting.with do |r|
          r.get("labkit:rl:applimiter_users_get_by_id:limit_user_lookups_by_user:user:#{user.id}")
        end

        expect(count.to_i).to eq(2)
      end

      it 'returns true once the threshold is exceeded' do
        threshold = 1
        allow(Gitlab::CurrentSettings.current_application_settings)
          .to receive(:users_get_by_id_limit).and_return(threshold)

        described_class.run!(:users_get_by_id, scope: user)
        result = described_class.run!(:users_get_by_id, scope: user)

        expect(result).to be(true)
      end
    end

    context 'when the labkit check errors' do
      let(:broken_result) { Labkit::RateLimit::Result.new(matched: false, error: true, action: :allow) }

      before do
        allow_next_instance_of(Labkit::RateLimit::Limiter) do |limiter|
          allow(limiter).to receive(:check).and_return(broken_result)
        end
      end

      it 'returns false and fails open' do
        expect(described_class.run!(:users_get_by_id, scope: user)).to be(false)
      end
    end

    context 'with scopes that flatten to the same identifier' do
      it 'collapses a bare model and a single-element array onto the same labkit counter' do
        described_class.run!(:notes_create, scope: user)
        described_class.run!(:notes_create, scope: [user])

        count = Gitlab::Redis::RateLimiting.with do |r|
          r.get("labkit:rl:applimiter_notes_create:limit_notes_by_user:user:#{user.id}")
        end

        expect(count.to_i).to eq(2)
      end
    end

    context "with labkit's Redis key shape" do
      it 'writes the count under the expected labkit key' do
        described_class.run!(:pipelines_create, scope: [project, user, 'abc123'])

        expected_key = "labkit:rl:applimiter_pipelines_create:limit_pipelines_by_project_user_sha" \
          ":project:#{project.id}:user:#{user.id}:sha:abc123"
        count = Gitlab::Redis::RateLimiting.with { |r| r.get(expected_key) }

        expect(count.to_i).to eq(1)
      end

      it "fills missing characteristic values with the '_unknown_' sentinel" do
        described_class.run!(:search_rate_limit, scope: [user])

        expected_key = "labkit:rl:applimiter_search_rate_limit:limit_searches_by_user_scope" \
          ":user:#{user.id}:search_scope:_unknown_"
        count = Gitlab::Redis::RateLimiting.with { |r| r.get(expected_key) }

        expect(count.to_i).to eq(1)
      end
    end

    context 'with a polymorphic-scope key' do
      let_it_be(:group) { create(:group) }

      it 'routes Project and Group scopes to disjoint counters' do
        described_class.run!(:web_hook_test, scope: [project, user])
        described_class.run!(:web_hook_test, scope: [group, user])

        project_key = "labkit:rl:applimiter_web_hook_test:limit_web_hook_tests_by_parent_user" \
          ":project:#{project.id}:group:_unknown_:user:#{user.id}"
        group_key = "labkit:rl:applimiter_web_hook_test:limit_web_hook_tests_by_parent_user" \
          ":project:_unknown_:group:#{group.id}:user:#{user.id}"

        Gitlab::Redis::RateLimiting.with do |r|
          expect(r.get(project_key).to_i).to eq(1)
          expect(r.get(group_key).to_i).to eq(1)
        end
      end
    end

    context 'with a key whose actor can be a User or an IP string' do
      it 'routes a User scope to the user characteristic' do
        described_class.run!(:expanded_diff_files, scope: user)

        expected_key = "labkit:rl:applimiter_expanded_diff_files:limit_expanded_diff_files_by_user_or_ip" \
          ":user:#{user.id}:ip:_unknown_"
        count = Gitlab::Redis::RateLimiting.with { |r| r.get(expected_key) }

        expect(count.to_i).to eq(1)
      end

      it 'routes a String scope to the ip characteristic' do
        described_class.run!(:expanded_diff_files, scope: '203.0.113.7')

        expected_key = "labkit:rl:applimiter_expanded_diff_files:limit_expanded_diff_files_by_user_or_ip" \
          ":user:_unknown_:ip:203.0.113.7"
        count = Gitlab::Redis::RateLimiting.with { |r| r.get(expected_key) }

        expect(count.to_i).to eq(1)
      end
    end

    context 'with STI subclass scope values' do
      let_it_be(:deploy_key) { create(:deploy_key) }

      it 'routes a DeployKey to :key via is_a?, not into a primitive slot' do
        described_class.run!(:gitlab_shell_operation, scope: [:upload, 'group/project', deploy_key])

        expected_key = "labkit:rl:applimiter_gitlab_shell_operation" \
          ":limit_gitlab_shell_operations_by_action_project_actor" \
          ":action:upload:repo_path:group/project:user:_unknown_:key:#{deploy_key.id}:ip:_unknown_"
        count = Gitlab::Redis::RateLimiting.with { |r| r.get(expected_key) }

        expect(count.to_i).to eq(1)
      end
    end

    # Regression for gitlab.com/gitlab-org/gitlab/-/issues/599855: the
    # untrusted-IP branch in lib/api/internal/base.rb passes three Strings
    # as scope (action, repo path, ip). Before the :project to :repo_path
    # rename, only :action and :ip were primitive zip targets and the IP
    # was silently dropped, collapsing every untrusted-IP client to the
    # same repo into a single Redis counter. params[:project] is a repo
    # path String per lib/api/helpers/internal_helpers.rb:173.
    context 'with the SSH internal-API anonymous branch (action, repo path, IP - all Strings)' do
      it 'preserves per-IP counters: two distinct IPs hitting the same repo must not collide' do
        action       = 'git-upload-pack'
        repo_path    = 'gitlab-org/gitlab'

        described_class.run!(:gitlab_shell_operation, scope: [action, repo_path, '203.0.113.10'])
        described_class.run!(:gitlab_shell_operation, scope: [action, repo_path, '203.0.113.11'])

        ip_a_key = "labkit:rl:applimiter_gitlab_shell_operation" \
          ":limit_gitlab_shell_operations_by_action_project_actor" \
          ":action:#{action}:repo_path:#{repo_path}:user:_unknown_:key:_unknown_:ip:203.0.113.10"
        ip_b_key = "labkit:rl:applimiter_gitlab_shell_operation" \
          ":limit_gitlab_shell_operations_by_action_project_actor" \
          ":action:#{action}:repo_path:#{repo_path}:user:_unknown_:key:_unknown_:ip:203.0.113.11"

        Gitlab::Redis::RateLimiting.with do |r|
          expect(r.get(ip_a_key).to_i).to eq(1), 'expected a per-IP counter for 203.0.113.10'
          expect(r.get(ip_b_key).to_i).to eq(1), 'expected a per-IP counter for 203.0.113.11'
        end
      end
    end

    context 'with a count_distinct (set-mode) registry entry' do
      let_it_be(:project_a) { create(:project) }
      let_it_be(:project_b) { create(:project) }

      let(:spec) do
        {
          limiter_name: 'applimiter_distinct_downloads',
          rule_name: 'limit_distinct_downloads_by_user',
          characteristics: %i[user],
          count_distinct: :project_id,
          action: :block
        }
      end

      let(:set_key) do
        "labkit:rl:applimiter_distinct_downloads:limit_distinct_downloads_by_user:user:#{user.id}"
      end

      before do
        allow(Gitlab::ApplicationRateLimiter::LabkitAdapter::SupportedRateLimits).to receive(:all)
          .and_return(distinct_downloads: spec)
        allow(Gitlab::ApplicationRateLimiter).to receive(:threshold).with(:distinct_downloads).and_return(5)
        allow(Gitlab::ApplicationRateLimiter).to receive(:interval).with(:distinct_downloads).and_return(60)
      end

      it 'SADDs the resource_id onto a SET keyed by the characteristic bucket' do
        described_class.run!(:distinct_downloads, scope: user, context: { resource_id: project_a.id })
        described_class.run!(:distinct_downloads, scope: user, context: { resource_id: project_b.id })
        described_class.run!(:distinct_downloads, scope: user, context: { resource_id: project_a.id })

        members = Gitlab::Redis::RateLimiting.with { |r| r.smembers(set_key) }
        expect(members).to contain_exactly(project_a.id.to_s, project_b.id.to_s)
      end

      it 'peek reads SCARD without writing a SET member or requiring resource_id', :aggregate_failures do
        described_class.run!(:distinct_downloads, scope: user, context: { resource_id: project_a.id })
        described_class.run!(:distinct_downloads, scope: user, context: { resource_id: project_b.id })

        expect(described_class.run_peek!(:distinct_downloads, scope: user)).to be(false)

        members = Gitlab::Redis::RateLimiting.with { |r| r.smembers(set_key) }
        expect(members).to contain_exactly(project_a.id.to_s, project_b.id.to_s)
      end

      it 'forwards threshold_override through rule_context to labkit Rule limit', :aggregate_failures do
        # Add 3 distinct projects, override threshold to 2 - should report exceeded.
        described_class.run!(:distinct_downloads, scope: user,
          context: { resource_id: project_a.id, threshold: 2, interval: 600 })
        result_b = described_class.run!(:distinct_downloads, scope: user,
          context: { resource_id: project_b.id, threshold: 2, interval: 600 })

        expect(result_b).to be(false) # exactly at limit, not exceeded
        project_c = create(:project)
        result_c = described_class.run!(:distinct_downloads, scope: user,
          context: { resource_id: project_c.id, threshold: 2, interval: 600 })

        expect(result_c).to be(true)
      end

      it 'falls back to the registered threshold/interval when rule_context overrides are nil', :aggregate_failures do
        4.times do
          described_class.run!(:distinct_downloads, scope: user,
            context: { resource_id: create(:project).id })
        end
        result_at_threshold = described_class.run!(:distinct_downloads, scope: user,
          context: { resource_id: create(:project).id })
        expect(result_at_threshold).to be(false) # 5 distinct == registered threshold

        result_over = described_class.run!(:distinct_downloads, scope: user,
          context: { resource_id: create(:project).id })
        expect(result_over).to be(true)
      end
    end

    context 'with duplicate AR scope values of the same registered class' do
      let_it_be(:user_a) { create(:user) }
      let_it_be(:user_b) { create(:user) }

      it 'routes the first AR instance and discards subsequent same-class instances' do
        described_class.run!(:users_get_by_id, scope: [user_a, user_b])

        first_key  = "labkit:rl:applimiter_users_get_by_id:limit_user_lookups_by_user:user:#{user_a.id}"
        second_key = "labkit:rl:applimiter_users_get_by_id:limit_user_lookups_by_user:user:#{user_b.id}"

        Gitlab::Redis::RateLimiting.with do |r|
          expect(r.get(first_key).to_i).to eq(1)
          expect(r.get(second_key)).to be_nil
        end
      end
    end

    context 'with a threshold_from_caller key (web_hook_calls)' do
      let_it_be(:namespace) { create(:namespace) }

      let(:expected_key) do
        "labkit:rl:applimiter_web_hook_calls:limit_web_hook_calls_by_namespace:namespace:#{namespace.id}"
      end

      it 'increments the namespace-keyed labkit counter' do
        described_class.run!(:web_hook_calls, scope: namespace, context: { threshold: 10 })

        count = Gitlab::Redis::RateLimiting.with { |r| r.get(expected_key) }
        expect(count.to_i).to eq(1)
      end

      it 'resolves the limit from the caller threshold in rule_context' do
        described_class.run!(:web_hook_calls, scope: namespace, context: { threshold: 1 })
        result = described_class.run!(:web_hook_calls, scope: namespace, context: { threshold: 1 })

        expect(result).to be(true)
      end

      it 'does not exceed when the count is within the caller threshold' do
        result = described_class.run!(:web_hook_calls, scope: namespace, context: { threshold: 100 })

        expect(result).to be(false)
      end

      it 'routes a Group scope through the namespace characteristic' do
        group = create(:group)
        described_class.run!(:web_hook_calls, scope: group, context: { threshold: 10 })

        group_key = "labkit:rl:applimiter_web_hook_calls:limit_web_hook_calls_by_namespace:namespace:#{group.id}"
        count = Gitlab::Redis::RateLimiting.with { |r| r.get(group_key) }
        expect(count.to_i).to eq(1)
      end
    end

    context 'with a cost-mode key (main_db_duration_limit_per_worker)' do
      let(:expected_key) do
        "labkit:rl:applimiter_main_db_duration_limit_per_worker:limit_main_db_duration_per_worker" \
          ":worker_name:SomeWorker"
      end

      def labkit_cost
        Gitlab::Redis::RateLimiting.with { |r| r.get(expected_key) }
      end

      it 'accumulates the per-call cost (INCRBYFLOAT) on the worker-keyed counter' do
        described_class.run!(:main_db_duration_limit_per_worker, scope: 'SomeWorker',
          context: { threshold: 10, interval: 60 }, cost: 1.5)
        described_class.run!(:main_db_duration_limit_per_worker, scope: 'SomeWorker',
          context: { threshold: 10, interval: 60 }, cost: 2.5)

        expect(labkit_cost.to_f).to eq(4.0)
      end

      it 'returns true when the cost exceeds the caller threshold' do
        result = described_class.run!(:main_db_duration_limit_per_worker, scope: 'SomeWorker',
          context: { threshold: 10, interval: 60 }, cost: 11.0)

        expect(result).to be(true)
      end

      it 'returns false and writes no Redis key when the cost is zero', :aggregate_failures do
        result = described_class.run!(:main_db_duration_limit_per_worker, scope: 'SomeWorker',
          context: { threshold: 10, interval: 60 }, cost: 0)

        expect(result).to be(false)
        expect(labkit_cost).to be_nil
      end
    end
  end

  describe '.build_rule' do
    context 'with a cost-mode key (threshold and interval supplied per call)' do
      let(:spec) { Gitlab::ApplicationRateLimiter::LabkitAdapter::SupportedRateLimits.all[key] }
      let(:key) { :main_db_duration_limit_per_worker }

      # The key is not registered in ApplicationRateLimiter.rate_limits, so the
      # registry fallback (threshold(key)/interval(key)) must not be consulted -
      # interval(key) would raise InvalidKeyError. Both values arrive per call.
      it 'resolves limit/period from rule_context without touching the registry', :aggregate_failures do
        expect(Gitlab::ApplicationRateLimiter).not_to receive(:threshold)
        expect(Gitlab::ApplicationRateLimiter).not_to receive(:interval)

        rule = described_class.send(:build_rule, key, spec)

        expect(rule.limit.call({ threshold: 42, interval: 600 })).to eq(42)
        expect(rule.period.call({ threshold: 42, interval: 600 })).to eq(600)
      end
    end

    context 'with a plain INCR key called with a per-call override' do
      let(:spec) { Gitlab::ApplicationRateLimiter::LabkitAdapter::SupportedRateLimits.all[:pipelines_create] }

      # Overrides used to route to the legacy path; with the legacy path gone,
      # labkit honours them through the rule_context lambdas.
      it 'resolves limit/period from the override in rule_context', :aggregate_failures do
        rule = described_class.send(:build_rule, :pipelines_create, spec)

        expect(rule.limit.call({ threshold: 7, interval: 30 })).to eq(7)
        expect(rule.period.call({ threshold: 7, interval: 30 })).to eq(30)
      end

      it 'falls back to the registry when no override is supplied', :aggregate_failures do
        allow(Gitlab::ApplicationRateLimiter).to receive(:threshold).with(:pipelines_create).and_return(99)
        allow(Gitlab::ApplicationRateLimiter).to receive(:interval).with(:pipelines_create).and_return(60)

        rule = described_class.send(:build_rule, :pipelines_create, spec)

        expect(rule.limit.call({})).to eq(99)
        expect(rule.period.call({})).to eq(60)
      end
    end
  end

  describe '.run_peek!' do
    it 'does not increment the labkit counter on a fresh key' do
      expect(described_class.run_peek!(:glql, scope: 'sha-abc123')).to be(false)

      labkit_key = "labkit:rl:applimiter_glql:limit_glql_queries_by_query_sha:query_sha:sha-abc123"
      count = Gitlab::Redis::RateLimiting.with { |r| r.get(labkit_key) }

      expect(count).to be_nil
    end

    it 'reads the counter populated by a paired non-peek caller without further increment' do
      described_class.run!(:glql, scope: 'sha-abc123')
      described_class.run!(:glql, scope: 'sha-abc123')
      described_class.run_peek!(:glql, scope: 'sha-abc123')

      labkit_key = "labkit:rl:applimiter_glql:limit_glql_queries_by_query_sha:query_sha:sha-abc123"
      count = Gitlab::Redis::RateLimiting.with { |r| r.get(labkit_key) }

      expect(count.to_i).to eq(2)
    end

    it 'returns true once the threshold is exceeded' do
      described_class.run!(:glql, scope: 'sha-abc123')
      described_class.run!(:glql, scope: 'sha-abc123')

      expect(described_class.run_peek!(:glql, scope: 'sha-abc123')).to be(true)
    end

    context 'with a threshold_from_caller key (web_hook_calls)' do
      let_it_be(:namespace) { create(:namespace) }

      let(:expected_key) do
        "labkit:rl:applimiter_web_hook_calls:limit_web_hook_calls_by_namespace:namespace:#{namespace.id}"
      end

      it 'does not increment the counter' do
        described_class.run_peek!(:web_hook_calls, scope: namespace, context: { threshold: 10 })

        expect(Gitlab::Redis::RateLimiting.with { |r| r.get(expected_key) }).to be_nil
      end

      it 'reads the counter written by a paired non-peek call' do
        described_class.run!(:web_hook_calls, scope: namespace, context: { threshold: 1 })
        described_class.run!(:web_hook_calls, scope: namespace, context: { threshold: 1 })

        expect(described_class.run_peek!(:web_hook_calls, scope: namespace,
          context: { threshold: 1 })).to be(true)
      end
    end

    context 'when the labkit peek errors' do
      let(:broken_result) { Labkit::RateLimit::Result.new(matched: false, error: true, action: :allow) }

      before do
        allow_next_instance_of(Labkit::RateLimit::Limiter) do |limiter|
          allow(limiter).to receive(:peek).and_return(broken_result)
        end
      end

      it 'returns false and fails open' do
        expect(described_class.run_peek!(:glql, scope: 'sha-abc123')).to be(false)
      end
    end
  end

  describe '.ar_characteristic_types' do
    it 'orders subclasses before their registered bases' do
      table = described_class.send(:ar_characteristic_types)
      classes = table.keys

      classes.each_with_index do |klass, i|
        classes[(i + 1)..].each do |later|
          expect(later).not_to be < klass,
            "#{later} (=> #{table[later]}) is a subclass of #{klass} " \
              "(=> #{table[klass]}) but appears after it; is_a? routing " \
              "would assign #{later} instances to #{table[klass]} rather " \
              "than #{table[later]}."
        end
      end
    end
  end
end
