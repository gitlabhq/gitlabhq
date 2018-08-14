require 'spec_helper'

describe 'projects/merge_requests/_commits.html.haml' do
  include Devise::Test::ControllerHelpers
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:target_project) { create(:project, :public, :repository) }
  let(:source_project) { fork_project(target_project, user, repository: true) }

  let(:merge_request) do
    create(:merge_request, :simple,
      source_project: source_project,
      target_project: target_project,
      author: user)
  end

  before do
    controller.prepend_view_path('app/views/projects')

    assign(:merge_request, merge_request)
    assign(:commits, merge_request.commits)
  end

  it 'shows commits from source project' do
    render

    commit = merge_request.commits.first # HEAD
    href = diffs_project_merge_request_path(target_project, merge_request, commit_id: commit)

    expect(rendered).to have_link(href: href)
  end
end
