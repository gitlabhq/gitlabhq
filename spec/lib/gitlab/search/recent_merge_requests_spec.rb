# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Search::RecentMergeRequests do
  def create_item(content:, project:)
    create(:merge_request, :unique_branches, title: content, target_project: project, source_project: project)
  end

  it_behaves_like 'search recent items'
end
