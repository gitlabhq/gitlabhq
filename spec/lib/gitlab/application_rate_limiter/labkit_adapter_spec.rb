# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ApplicationRateLimiter::LabkitAdapter,
  :clean_gitlab_redis_rate_limiting, :prometheus, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe '.shadow_or_enforce?' do
    using RSpec::Parameterized::TableSyntax

    where(:scenario, :key, :threshold_override, :interval_override, :flag_on, :expected) do
      'key not handled by the adapter'             | :notification_emails | nil | nil | true  | false
      'threshold override forces the legacy path'  | :pipelines_create    | 10  | nil | true  | false
      'interval override forces the legacy path'   | :pipelines_create    | nil | 60  | true  | false
      'use_labkit flag is off'                     | :pipelines_create    | nil | nil | false | false
      'handled key, no overrides, flag on'         | :pipelines_create    | nil | nil | true  | true
    end

    with_them do
      before do
        stub_feature_flags(rate_limiter_use_labkit_pipelines_create: flag_on)
      end

      it 'returns the expected dispatch decision' do
        expect(
          described_class.shadow_or_enforce?(key,
            threshold_override: threshold_override,
            interval_override: interval_override)
        ).to be(expected)
      end
    end

    context 'with flag basis resolution' do
      it 'reads the per-key flag for cohort 1 entries' do
        expect(described_class.shadow_or_enforce?(:pipelines_create,
          threshold_override: nil, interval_override: nil)).to be(true)

        stub_feature_flags(rate_limiter_use_labkit_pipelines_create: false)
        expect(described_class.shadow_or_enforce?(:pipelines_create,
          threshold_override: nil, interval_override: nil)).to be(false)
      end

      it 'reads the cohort-wide flag for cohort 2 entries' do
        expect(described_class.shadow_or_enforce?(:ai_action,
          threshold_override: nil, interval_override: nil)).to be(true)

        stub_feature_flags(rate_limiter_use_labkit_cohort_2: false)
        expect(described_class.shadow_or_enforce?(:ai_action,
          threshold_override: nil, interval_override: nil)).to be(false)
      end

      it 'reads the cohort-wide flag for cohort 3 entries' do
        expect(described_class.shadow_or_enforce?(:glql,
          threshold_override: nil, interval_override: nil)).to be(true)

        stub_feature_flags(rate_limiter_use_labkit_cohort_3: false)
        expect(described_class.shadow_or_enforce?(:glql,
          threshold_override: nil, interval_override: nil)).to be(false)
      end
    end

    context 'when an override is passed' do
      let(:override_counter) { instance_double(Prometheus::Client::Counter, increment: nil) }

      before do
        stub_feature_flags(rate_limiter_use_labkit_pipelines_create: true)
        allow(Gitlab::Metrics).to receive(:counter).and_call_original
        allow(Gitlab::Metrics).to receive(:counter)
          .with(:gitlab_rate_limiter_labkit_override_total, anything, anything)
          .and_return(override_counter)
      end

      where(:threshold_override, :interval_override, :expected_kind) do
        10  | nil | :threshold
        nil | 60  | :interval
        10  | 60  | :both
      end

      with_them do
        it 'records the override kind on the counter' do
          expect(override_counter).to receive(:increment)
            .with(key: :pipelines_create, override: expected_kind)

          described_class.shadow_or_enforce?(:pipelines_create,
            threshold_override: threshold_override,
            interval_override: interval_override)
        end
      end

      it 'does not record overrides for keys the adapter does not handle' do
        expect(override_counter).not_to receive(:increment)

        described_class.shadow_or_enforce?(:notification_emails, threshold_override: 10, interval_override: nil)
      end

      it 'does not record when no override is passed' do
        expect(override_counter).not_to receive(:increment)

        described_class.shadow_or_enforce?(:pipelines_create, threshold_override: nil, interval_override: nil)
      end
    end
  end

  describe '.enforce?' do
    it 'reflects the per-key enforce flag for cohort 1 entries' do
      expect(described_class.enforce?(:pipelines_create)).to be(true)

      stub_feature_flags(rate_limiter_use_labkit_pipelines_create_enforce: false)
      expect(described_class.enforce?(:pipelines_create)).to be(false)
    end

    it 'reflects the cohort-wide enforce flag for cohort 2 entries' do
      expect(described_class.enforce?(:ai_action)).to be(true)

      stub_feature_flags(rate_limiter_use_labkit_cohort_2_enforce: false)
      expect(described_class.enforce?(:ai_action)).to be(false)
    end

    it 'reflects the cohort-wide enforce flag for cohort 3 entries' do
      expect(described_class.enforce?(:glql)).to be(true)

      stub_feature_flags(rate_limiter_use_labkit_cohort_3_enforce: false)
      expect(described_class.enforce?(:glql)).to be(false)
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

  describe '.record_divergence' do
    let(:counter) { instance_double(Prometheus::Client::Counter, increment: nil) }

    before do
      allow(Gitlab::Metrics).to receive(:counter).and_return(counter)
    end

    it 'increments the match label when decisions agree' do
      allow(described_class).to receive(:window_boundary?).and_return(false)
      expect(counter).to receive(:increment)
        .with(key: :pipelines_create, agreement: :match, boundary: false)

      described_class.record_divergence(:pipelines_create, true, true)
    end

    it 'increments the diverge label when decisions disagree' do
      allow(described_class).to receive(:window_boundary?).and_return(false)
      expect(counter).to receive(:increment)
        .with(key: :pipelines_create, agreement: :diverge, boundary: false)

      described_class.record_divergence(:pipelines_create, true, false)
    end

    it 'tags increments inside the boundary noise window with boundary: true' do
      allow(described_class).to receive(:window_boundary?).and_return(true)
      expect(counter).to receive(:increment)
        .with(key: :pipelines_create, agreement: :diverge, boundary: true)

      described_class.record_divergence(:pipelines_create, true, false)
    end
  end
end
