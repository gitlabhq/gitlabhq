# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/milestones/_issuable.html.haml' do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:milestone) { create(:milestone, project: project) }

  before do
    assign(:project, project)
    assign(:milestone, milestone)
  end

  subject(:rendered) { render 'shared/milestones/issuable', issuable: issuable, show_project_name: true }

  context 'issue' do
    let(:issuable) { create(:issue, project: project, assignees: [user]) }

    it 'links to the page for the issue' do
      expect(rendered).to have_css("a[href='#{project_issue_path(project, issuable)}']", class: 'issue-link')
    end

    it 'links to issues page for user' do
      expect(rendered).to have_css("a[href='#{project_issues_path(project, milestone_title: milestone.title, assignee_id: user.id, state: 'all')}']")
    end
  end

  context 'merge request' do
    let(:issuable) { create(:merge_request, source_project: project, target_project: project, assignees: [user]) }

    it 'links to merge requests page for user' do
      expect(rendered).to have_css("a[href='#{project_merge_requests_path(project, milestone_title: milestone.title, assignee_id: user.id, state: 'all')}']")
    end

    it 'links to the page for the merge request' do
      expect(rendered).to have_css("a[href='#{project_merge_request_path(project, issuable)}']", class: 'issue-link')
    end
  end
end
