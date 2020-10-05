# frozen_string_literal: true

require 'spec_helper'
RSpec.shared_examples 'search recent items' do
  let_it_be(:user) { create(:user) }
  let_it_be(:recent_items) { described_class.new(user: user) }
  let(:item) { create_item(content: 'hello world 1', parent: parent) }
  let(:parent) { create(parent_type, :public) }

  describe '#log_view', :clean_gitlab_redis_shared_state do
    it 'adds the item to the recent items' do
      recent_items.log_view(item)

      results = recent_items.search('hello')

      expect(results).to eq([item])
    end

    it 'removes an item when it exceeds the size items_limit' do
      recent_items = described_class.new(user: user, items_limit: 3)

      4.times do |i|
        recent_items.log_view(create_item(content: "item #{i}", parent: parent))
      end

      results = recent_items.search('item')

      expect(results.map(&:title)).to contain_exactly('item 3', 'item 2', 'item 1')
    end

    it 'expires the items after expires_after' do
      recent_items = described_class.new(user: user, expires_after: 0)

      recent_items.log_view(item)

      results = recent_items.search('hello')

      expect(results).to be_empty
    end

    it 'does not include results logged for another user' do
      another_user = create(:user)
      another_item = create_item(content: 'hello world 2', parent: parent)
      described_class.new(user: another_user).log_view(another_item)
      recent_items.log_view(item)

      results = recent_items.search('hello')

      expect(results).to eq([item])
    end
  end

  describe '#search', :clean_gitlab_redis_shared_state do
    let(:item1) { create_item(content: "matching item 1", parent: parent) }
    let(:item2) { create_item(content: "matching item 2", parent: parent) }
    let(:item3) { create_item(content: "matching item 3", parent: parent) }
    let(:non_matching_item) { create_item(content: "different item", parent: parent) }
    let!(:non_viewed_item) { create_item(content: "matching but not viewed item", parent: parent) }

    before do
      recent_items.log_view(item1)
      recent_items.log_view(item2)
      recent_items.log_view(item3)
      recent_items.log_view(non_matching_item)
    end

    it 'matches partial text in the item title' do
      expect(recent_items.search('matching')).to contain_exactly(item1, item2, item3)
    end

    it 'returns results sorted by recently viewed' do
      recent_items.log_view(item2)

      expect(recent_items.search('matching')).to eq([item2, item3, item1])
    end

    it 'does not leak items you no longer have access to' do
      private_parent = create(parent_type, :public)
      private_item = create_item(content: 'matching item title', parent: private_parent)

      recent_items.log_view(private_item)

      private_parent.update!(visibility_level: ::Gitlab::VisibilityLevel::PRIVATE)

      expect(recent_items.search('matching')).not_to include(private_item)
    end

    it "limits results to #{Gitlab::Search::RecentItems::SEARCH_LIMIT} items" do
      (Gitlab::Search::RecentItems::SEARCH_LIMIT + 1).times do |i|
        recent_items.log_view(create_item(content: "item #{i}", parent: parent))
      end

      results = recent_items.search('item')

      expect(results.count).to eq(Gitlab::Search::RecentItems::SEARCH_LIMIT)
    end
  end
end
