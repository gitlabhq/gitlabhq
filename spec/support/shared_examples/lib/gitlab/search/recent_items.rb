# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'search recent items' do
  let_it_be(:user) { create(:user) }
  let_it_be(:recent_items) { described_class.new(user: user, items_limit: 5) }
  let(:item) { create_item(content: 'hello world 1', project: project) }
  let(:project) { create(:project, :public) }

  describe '#log_view', :clean_gitlab_redis_shared_state do
    it 'adds the item to the recent items' do
      recent_items.log_view(item)

      results = recent_items.search('hello')

      expect(results).to eq([item])
    end

    it 'removes an item when it exceeds the size items_limit' do
      (1..6).each do |i|
        recent_items.log_view(create_item(content: "item #{i}", project: project))
      end

      results = recent_items.search('item')

      expect(results.map(&:title)).to contain_exactly('item 6', 'item 5', 'item 4', 'item 3', 'item 2')
    end

    it 'expires the items after expires_after' do
      recent_items = described_class.new(user: user, expires_after: 0)

      recent_items.log_view(item)

      results = recent_items.search('hello')

      expect(results).to be_empty
    end

    it 'does not include results logged for another user' do
      another_user = create(:user)
      another_item = create_item(content: 'hello world 2', project: project)
      described_class.new(user: another_user).log_view(another_item)
      recent_items.log_view(item)

      results = recent_items.search('hello')

      expect(results).to eq([item])
    end
  end

  describe '#search', :clean_gitlab_redis_shared_state do
    let(:item1) { create_item(content: "matching item 1", project: project) }
    let(:item2) { create_item(content: "matching item 2", project: project) }
    let(:item3) { create_item(content: "matching item 3", project: project) }
    let(:non_matching_item) { create_item(content: "different item", project: project) }
    let!(:non_viewed_item) { create_item(content: "matching but not viewed item", project: project) }

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
      private_project = create(:project, :public, namespace: create(:group))
      private_item = create_item(content: 'matching item title', project: private_project)

      recent_items.log_view(private_item)

      private_project.update!(visibility_level: Project::PRIVATE)

      expect(recent_items.search('matching')).not_to include(private_item)
    end
  end
end
