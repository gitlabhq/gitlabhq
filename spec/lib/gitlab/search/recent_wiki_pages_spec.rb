# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Search::RecentWikiPages, feature_category: :wiki do
  let(:parent_type) { :project }

  def create_item(content:, parent:)
    create(:wiki_page_meta, title: content, project: parent)
  end

  it_behaves_like 'search recent items'

  describe 'deleted wiki pages', :clean_gitlab_redis_shared_state do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:recent_items) { described_class.new(user: user) }

    it 'does not return deleted wiki pages in search results' do
      item = create(:wiki_page_meta, title: 'matching item', project: project)
      recent_items.log_view(item)

      item.update_column(:deleted_at, Time.current)

      expect(recent_items.search('matching')).to be_empty
    end

    it 'does not return deleted wiki pages in latest_with_timestamps' do
      item = create(:wiki_page_meta, title: 'viewed page', project: project)
      recent_items.log_view(item)

      item.update_column(:deleted_at, Time.current)

      expect(recent_items.latest_with_timestamps).to be_empty
    end
  end
end
