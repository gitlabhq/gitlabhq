# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/merge_requests/_commits.html.haml', :sidekiq_might_not_need_inline do
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
    assign(:commits, merge_request.commits(load_from_gitaly: true))
    assign(:hidden_commit_count, 0)
  end

  it 'shows commits from source project' do
    render

    commit = merge_request.commits.first # HEAD
    href = diffs_project_merge_request_path(target_project, merge_request, commit_id: commit)

    expect(rendered).to have_link(href: href)
  end

  it 'shows signature verification badge' do
    render

    expect(rendered).to have_css('.js-loading-signature-badge')
  end

  context 'when MR has no commits' do
    let(:merge_request) { create(:merge_request, source_project: create(:project, :custom_repo)) }

    it 'renders empty state' do
      assign(:context_commits, [])

      render

      expect(rendered).to have_css('.gl-empty-state')
    end

    it 'renders the svg' do
      assign(:context_commits, [])

      render

      expect(rendered).to include('empty-commit-md')
    end
  end
end
