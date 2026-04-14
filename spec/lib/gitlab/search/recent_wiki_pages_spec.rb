# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Search::RecentWikiPages, feature_category: :wiki do
  let(:parent_type) { :project }

  def create_item(content:, parent:)
    create(:wiki_page_meta, title: content, project: parent)
  end

  it_behaves_like 'search recent items'
end
