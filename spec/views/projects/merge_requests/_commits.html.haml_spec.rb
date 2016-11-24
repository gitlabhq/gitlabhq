require 'spec_helper'

describe 'projects/merge_requests/show/_commits.html.haml' do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:target_project) { create(:project) }

  let(:source_project) do
    create(:project, forked_from_project: target_project)
  end

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

    commit = source_project.commit(merge_request.source_branch)
    href = namespace_project_commit_path(
      source_project.namespace,
      source_project,
      commit)

    expect(rendered).to have_link(Commit.truncate_sha(commit.sha), href: href)
  end
end
