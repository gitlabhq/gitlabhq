# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Search::RecentMergeRequests do
  let(:parent_type) { :project }

  def create_item(content:, parent:)
    create(:merge_request, :unique_branches, title: content, target_project: parent, source_project: parent)
  end

  it_behaves_like 'search recent items'
end
