# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::EnableDescendantsCacheCronWorker, '#perform', :clean_gitlab_redis_shared_state, feature_category: :source_code_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:subsubgroup) { create(:group, parent: subgroup) }
  let_it_be(:project1) { create(:project, group: subsubgroup) }
  let_it_be(:project2) { create(:project, group: subsubgroup) }

  let_it_be(:other_group) { create(:group) }
  let_it_be(:other_project) { create(:project, group: group) }

  subject(:worker) { described_class.new }

  context 'when periodical_namespace_descendants_cache_worker feature is enabled' do
    before do
      stub_feature_flags(periodical_namespace_descendants_cache_worker: true)

      stub_const("#{described_class}::CACHE_THRESHOLD", 4)
      stub_const("#{described_class}::GROUP_BATCH_SIZE", 1)
      stub_const("#{described_class}::NAMESPACE_BATCH_SIZE", 1)
    end

    it 'creates the cache record for the top level group and the subgroup' do
      metadata = worker.perform

      ids = Namespaces::Descendants.pluck(:namespace_id)
      expect(ids).to match_array([group.id, subgroup.id])

      expect(metadata).to eq({ over_time: false, last_id: nil, cache_count: 2 })
    end

    context 'when cached record already exist' do
      it 'does not fail' do
        create(:namespace_descendants, namespace: group)

        worker.perform

        ids = Namespaces::Descendants.pluck(:namespace_id)
        expect(ids).to match_array([group.id, subgroup.id])
      end
    end

    context 'when time limit is reached' do
      it 'stores the last processed group id as the cursor' do
        # Reach the limit after finishing counting the first group's descendants:
        # group, subgroup, subsubgroup, project1
        allow_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |limiter|
          call_count = 0
          allow(limiter).to receive(:over_time?).and_wrap_original do |_, _name|
            # on the 4th call, we reach over time
            call_count += 1
            if call_count >= 4
              limiter.instance_variable_set(:@last_check, true)
              true
            else
              false
            end
          end
        end

        metadata = worker.perform

        ids = Namespaces::Descendants.pluck(:namespace_id)
        expect(ids).to match_array([group.id])

        value = Gitlab::Redis::SharedState.with { |redis| redis.get(described_class::CURSOR_KEY) }
        expect(Integer(value)).to eq(group.id)

        expect(metadata).to eq({ over_time: true, last_id: group.id, cache_count: 1 })
      end
    end

    context 'when cursor is present' do
      it 'continues processing from the cursor' do
        # Assume that the first group was already processed
        Gitlab::Redis::SharedState.with { |redis| redis.set(described_class::CURSOR_KEY, group.id) }

        worker.perform

        ids = Namespaces::Descendants.pluck(:namespace_id)
        expect(ids).to match_array([subgroup.id])
      end
    end

    context 'when reaching the end of the table' do
      it 'clears the cursor' do
        Gitlab::Redis::SharedState.with { |redis| redis.set(described_class::CURSOR_KEY, group.id) }

        metadata = worker.perform

        value = Gitlab::Redis::SharedState.with { |redis| redis.get(described_class::CURSOR_KEY) }
        expect(value).to be_nil

        expect(metadata).to eq({ over_time: false, last_id: nil, cache_count: 1 })
      end
    end
  end

  it_behaves_like 'an idempotent worker' do
    it 'does nothing' do
      expect(Namespaces::Descendants.count).to eq(0)
    end
  end
end
