# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Issues::Rebalancing::State, :clean_gitlab_redis_shared_state do
  shared_examples 'issues rebalance caching' do
    describe '#track_new_running_rebalance' do
      it 'caches a project id to track caching in progress' do
        expect { rebalance_caching.track_new_running_rebalance }.to change { rebalance_caching.concurrent_running_rebalances_count }.from(0).to(1)
      end
    end

    describe '#set and get current_index' do
      it 'returns zero as current index when index not cached' do
        expect(rebalance_caching.get_current_index).to eq(0)
      end

      it 'returns cached current index' do
        expect { rebalance_caching.cache_current_index(123) }.to change { rebalance_caching.get_current_index }.from(0).to(123)
      end
    end

    describe '#set and get current_project' do
      it 'returns nil if there is no project_id cached' do
        expect(rebalance_caching.get_current_project_id).to be_nil
      end

      it 'returns cached current project_id' do
        expect { rebalance_caching.cache_current_project_id(456) }.to change { rebalance_caching.get_current_project_id }.from(nil).to('456')
      end
    end

    describe "#rebalance_in_progress?" do
      it 'return zero if no re-balances are running' do
        expect(rebalance_caching.concurrent_running_rebalances_count).to eq(0)
      end

      it 'return false if no re-balances are running' do
        expect(rebalance_caching.rebalance_in_progress?).to be false
      end

      it 'return true a re-balance for given project/namespace is running' do
        rebalance_caching.track_new_running_rebalance

        expect(rebalance_caching.rebalance_in_progress?).to be true
      end
    end

    context 'caching issue ids' do
      context 'with no issue ids cached' do
        it 'returns zero when there are no cached issue ids' do
          expect(rebalance_caching.issue_count).to eq(0)
        end

        it 'returns empty array when there are no cached issue ids' do
          expect(rebalance_caching.get_cached_issue_ids(0, 100)).to eq([])
        end
      end

      context 'with cached issue ids' do
        before do
          generate_and_cache_issues_ids(count: 3)
        end

        it 'returns count of cached issue ids' do
          expect(rebalance_caching.issue_count).to eq(3)
        end

        it 'returns array of issue ids' do
          expect(rebalance_caching.get_cached_issue_ids(0, 100)).to eq(%w[1 2 3])
        end

        it 'limits returned values' do
          expect(rebalance_caching.get_cached_issue_ids(0, 2)).to eq(%w[1 2])
        end

        context 'when caching duplicate issue_ids' do
          before do
            generate_and_cache_issues_ids(count: 3, position_offset: 3, position_direction: -1)
          end

          it 'does not cache duplicate issues' do
            expect(rebalance_caching.issue_count).to eq(3)
          end

          it 'returns cached issues with latest scores' do
            expect(rebalance_caching.get_cached_issue_ids(0, 100)).to eq(%w[3 2 1])
          end
        end
      end
    end

    context 'when setting expiration' do
      context 'when tracking new rebalance' do
        it 'returns as expired for non existent key' do
          ::Gitlab::Redis::SharedState.with do |redis|
            expect(redis.ttl(Gitlab::Issues::Rebalancing::State::CONCURRENT_RUNNING_REBALANCES_KEY)).to be < 0
          end
        end

        it 'has expiration set' do
          rebalance_caching.track_new_running_rebalance

          ::Gitlab::Redis::SharedState.with do |redis|
            expect(redis.ttl(Gitlab::Issues::Rebalancing::State::CONCURRENT_RUNNING_REBALANCES_KEY)).to be_between(0, described_class::REDIS_EXPIRY_TIME.ago.to_i)
          end
        end
      end

      context 'when setting current index' do
        it 'returns as expiring for non existent key' do
          ::Gitlab::Redis::SharedState.with do |redis|
            expect(redis.ttl(rebalance_caching.send(:current_index_key))).to be < 0
          end
        end

        it 'has expiration set' do
          rebalance_caching.cache_current_index(123)

          ::Gitlab::Redis::SharedState.with do |redis|
            expect(redis.ttl(rebalance_caching.send(:current_index_key))).to be_between(0, described_class::REDIS_EXPIRY_TIME.ago.to_i)
          end
        end
      end

      context 'when setting current project id' do
        it 'returns as expired for non existent key' do
          ::Gitlab::Redis::SharedState.with do |redis|
            expect(redis.ttl(rebalance_caching.send(:current_project_key))).to be < 0
          end
        end

        it 'has expiration set' do
          rebalance_caching.cache_current_project_id(456)

          ::Gitlab::Redis::SharedState.with do |redis|
            expect(redis.ttl(rebalance_caching.send(:current_project_key))).to be_between(0, described_class::REDIS_EXPIRY_TIME.ago.to_i)
          end
        end
      end

      context 'when setting cached issue ids' do
        it 'returns as expired for non existent key' do
          ::Gitlab::Redis::SharedState.with do |redis|
            expect(redis.ttl(rebalance_caching.send(:issue_ids_key))).to be < 0
          end
        end

        it 'has expiration set' do
          generate_and_cache_issues_ids(count: 3)

          ::Gitlab::Redis::SharedState.with do |redis|
            expect(redis.ttl(rebalance_caching.send(:issue_ids_key))).to be_between(0, described_class::REDIS_EXPIRY_TIME.ago.to_i)
          end
        end
      end
    end

    context 'cleanup cache' do
      before do
        generate_and_cache_issues_ids(count: 3)
        rebalance_caching.cache_current_index(123)
        rebalance_caching.track_new_running_rebalance
      end

      it 'removes cache keys' do
        expect(check_existing_keys).to eq(3)

        rebalance_caching.cleanup_cache

        expect(check_existing_keys).to eq(1)
      end
    end
  end

  context 'rebalancing issues in namespace' do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:project) { create(:project, namespace: group) }

    subject(:rebalance_caching) { described_class.new(group, group.projects) }

    it { expect(rebalance_caching.send(:rebalanced_container_type)).to eq(described_class::NAMESPACE) }

    it_behaves_like 'issues rebalance caching'

    describe '.fetch_rebalancing_groups_and_projects' do
      before do
        rebalance_caching.track_new_running_rebalance
      end

      it 'caches recently finished rebalance key' do
        expect(described_class.fetch_rebalancing_groups_and_projects).to eq([[group.id], []])
      end
    end
  end

  context 'rebalancing issues in a project' do
    let_it_be(:project) { create(:project) }

    subject(:rebalance_caching) { described_class.new(project.namespace, Project.where(id: project)) }

    it { expect(rebalance_caching.send(:rebalanced_container_type)).to eq(described_class::PROJECT) }

    it_behaves_like 'issues rebalance caching'

    describe '.fetch_rebalancing_groups_and_projects' do
      before do
        rebalance_caching.track_new_running_rebalance
      end

      it 'caches recently finished rebalance key' do
        expect(described_class.fetch_rebalancing_groups_and_projects).to eq([[], [project.id]])
      end
    end
  end

  # count - how many issue ids to generate, issue ids will start at 1
  # position_offset - if you'd want to offset generated relative_position for the issue ids,
  # relative_position is generated as = issue id * 10 + position_offset
  # position_direction - (1) for positive relative_positions, (-1) for negative relative_positions
  def generate_and_cache_issues_ids(count:, position_offset: 0, position_direction: 1)
    issues = []

    count.times do |idx|
      id = idx + 1
      issues << double(relative_position: position_direction * ((id * 10) + position_offset), id: id)
    end

    rebalance_caching.cache_issue_ids(issues)
  end

  def check_existing_keys
    index = 0
    cursor = '0'
    recently_finished_keys_count = 0

    # loop to scan since it may run against a Redis Cluster
    loop do
      # spec only, we do not actually scan keys in the code
      cursor, items = Gitlab::Redis::SharedState.with { |redis| redis.scan(cursor, match: "#{described_class::RECENTLY_FINISHED_REBALANCE_PREFIX}:*") }
      recently_finished_keys_count += items.count
      break if cursor == '0'
    end

    index += 1 if rebalance_caching.get_current_index > 0
    index += 1 if rebalance_caching.get_current_project_id.present?
    index += 1 if rebalance_caching.get_cached_issue_ids(0, 100).present?
    index += 1 if rebalance_caching.rebalance_in_progress?
    index += 1 if recently_finished_keys_count > 0

    index
  end
end
