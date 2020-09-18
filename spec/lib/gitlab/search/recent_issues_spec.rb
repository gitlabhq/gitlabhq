# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Search::RecentIssues do
  def create_item(content:, project:)
    create(:issue, title: content, project: project)
  end

  it_behaves_like 'search recent items'
end
