# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::OpenWorkItemsCountService, :use_clean_rails_memory_store_caching,
  feature_category: :team_planning do
  let_it_be(:group)       { create(:group, :public) }
  let_it_be(:project)     { create(:project, :public, namespace: group) }
  let_it_be(:user)        { create(:user) }
  let_it_be(:banned_user) { create(:user, :banned) }

  let_it_be(:work_item)    { create(:work_item, :opened, project: project) }
  let_it_be(:confidential) { create(:work_item, :confidential, :opened, project: project) }
  let_it_be(:closed)       { create(:work_item, :closed, project: project) }
  let_it_be(:hidden)       { create(:work_item, :opened, project: project, author: banned_user) }

  subject(:service) { described_class.new(group, user) }

  describe '#relation_for_count' do
    before do
      allow(WorkItems::WorkItemsFinder).to receive(:new).and_call_original
    end

    it 'uses WorkItems::WorkItemsFinder with confidential: false when user cannot read confidential' do
      expect(WorkItems::WorkItemsFinder).to receive(:new).with(
        user,
        hash_including(
          group_id: group.id,
          state: 'opened',
          non_archived: true,
          include_descendants: true,
          confidential: false
        )
      )

      service.send(:relation_for_count)
    end

    it 'limits results to WorkItem::MAX_OPEN_WORK_ITEMS_COUNT' do
      expect(service.send(:relation_for_count).limit_value).to eq(WorkItem::MAX_OPEN_WORK_ITEMS_COUNT)
    end

    context 'when user can read confidential issues' do
      before do
        group.add_planner(user)
      end

      it 'uses WorkItems::WorkItemsFinder with confidential: nil' do
        expect(WorkItems::WorkItemsFinder).to receive(:new).with(
          user,
          hash_including(
            group_id: group.id,
            confidential: nil
          )
        )

        service.send(:relation_for_count)
      end
    end
  end

  describe '#count' do
    context 'when user is nil' do
      it 'does not include confidential work items' do
        expect(described_class.new(group).count).to eq(1)
      end
    end

    context 'when user is provided' do
      context 'when user can read confidential issues' do
        before_all do
          group.add_planner(user)
        end

        it 'returns count including confidential work items and excludes hidden work items (from banned users)' do
          expect(service.count).to eq(2) # work_item + confidential; hidden excluded
        end
      end

      context 'when user cannot read confidential issues' do
        before_all do
          group.add_guest(user)
        end

        it 'does not include confidential work items' do
          expect(service.count).to eq(1)
        end
      end

      it_behaves_like 'a counter caching service with threshold'
    end

    context 'when fast_timeout is enabled' do
      subject(:fast_service) { described_class.new(group, fast_timeout: true) }

      it 'executes the query with a fast timeout' do
        expect(ApplicationRecord).to receive(:with_fast_read_statement_timeout).and_call_original

        expect(fast_service.count).to eq(1)
      end
    end
  end

  describe '#clear_all_cache_keys' do
    it 'calls Rails.cache.delete with both cache keys' do
      expect(Rails.cache).to receive(:delete)
        .with(['groups', 'open_work_items_count_service', 1, group.id, described_class::PUBLIC_COUNT_KEY])
      expect(Rails.cache).to receive(:delete)
        .with(['groups', 'open_work_items_count_service', 1, group.id, described_class::TOTAL_COUNT_KEY])

      service.clear_all_cache_keys
    end
  end
end
