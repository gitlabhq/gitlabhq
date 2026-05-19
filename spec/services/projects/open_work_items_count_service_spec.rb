# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::OpenWorkItemsCountService, :use_clean_rails_memory_store_caching,
  feature_category: :team_planning do
  let_it_be(:project)     { create(:project, :public) }
  let_it_be(:user)        { create(:user) }
  let_it_be(:banned_user) { create(:user, :banned) }

  let_it_be(:work_item)    { create(:work_item, :opened, project: project) }
  let_it_be(:task)         { create(:work_item, :task, :opened, project: project) }
  let_it_be(:confidential) { create(:work_item, :confidential, :opened, project: project) }
  let_it_be(:closed)       { create(:work_item, :closed, project: project) }
  let_it_be(:hidden)       { create(:work_item, :opened, project: project, author: banned_user) }

  subject(:service) { described_class.new(project, user) }

  it_behaves_like 'a counter caching service'

  describe '.query' do
    it 'returns opened, non-hidden work items' do
      result = described_class.query(project, public_only: false)

      expect(result).to include(work_item, task, confidential)
      expect(result).not_to include(closed)
    end

    it 'excludes confidential work items when public_only is true' do
      result = described_class.query(project, public_only: true)

      expect(result).to include(work_item, task)
      expect(result).not_to include(confidential, closed)
    end

    it 'excludes hidden work items (from banned users)' do
      result = described_class.query(project, public_only: false)

      expect(result).not_to include(hidden)
    end

    context 'when open work items exceed MAX_OPEN_WORK_ITEMS_COUNT' do
      it 'caps the count at WorkItem::MAX_OPEN_WORK_ITEMS_COUNT' do
        allow(described_class).to receive(:base_query).and_return(
          WorkItem.where(id: (1..(WorkItem::MAX_OPEN_WORK_ITEMS_COUNT + 1)).to_a)
        )

        expect(described_class.query(project, public_only: false).count)
          .to be <= WorkItem::MAX_OPEN_WORK_ITEMS_COUNT
      end
    end
  end

  describe '#count' do
    context 'when user cannot read confidential issues' do
      it 'returns public work items count only' do
        expect(service.count).to eq(2) # work_item + task
      end

      it 'uses public_open_work_items_count cache key' do
        expect(service.cache_key_name).to eq('public_open_work_items_count')
      end
    end

    context 'when user can read confidential issues' do
      before do
        project.add_planner(user)
      end

      it 'includes confidential work items in count' do
        expect(service.count).to eq(3) # work_item + task + confidential
      end

      it 'uses total_open_work_items_count cache key' do
        expect(service.cache_key_name).to eq('total_open_work_items_count')
      end
    end
  end

  describe '#relation_for_count' do
    it 'delegates to .query with public_only: true when user cannot read confidential' do
      expect(described_class).to receive(:query).with(project, public_only: true).and_call_original

      service.relation_for_count
    end

    context 'when user can read confidential issues' do
      before do
        project.add_planner(user)
      end

      it 'delegates to .query with public_only: false' do
        expect(described_class).to receive(:query).with(project, public_only: false).and_call_original

        service.relation_for_count
      end
    end
  end

  describe '#delete_cache' do
    it 'clears both public and total cache keys' do
      expect(Rails.cache).to receive(:delete).with(service.public_count_cache_key)
      expect(Rails.cache).to receive(:delete).with(service.total_count_cache_key)

      service.delete_cache
    end
  end
end
