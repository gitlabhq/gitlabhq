# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/milestones/_issuable.html.haml', feature_category: :portfolio_management do
  let_it_be(:project, freeze: false) { create(:project) }
  let_it_be(:user, freeze: false) { create(:user) }
  let_it_be(:milestone, freeze: false) { create(:milestone, project: project) }

  before do
    assign(:project, project)
    assign(:milestone, milestone)
  end

  subject(:rendered) { render 'shared/milestones/issuable', issuable: issuable, show_project_name: true }

  context 'for issue' do
    let(:issuable) { create(:issue, project: project, assignees: [user]) }

    it 'links to the page for the issue' do
      expect(rendered).to have_css("a[href$='#{::Gitlab::UrlBuilder.instance.issue_path(issuable)}']", class: 'issue-link')
    end

    it 'links to issues page for user' do
      expect(rendered).to have_css("a[href='#{project_issues_path(project, milestone_title: milestone.title, assignee_id: user.id, state: 'all')}']")
    end

    it 'renders the work item type icon' do
      expect(rendered).to have_css(%(svg use[href$="#work-item-issue"]))
    end
  end

  context 'for task' do
    let_it_be(:issuable) { create(:work_item, :task, project: project) }

    it 'renders the work item type icon' do
      expect(rendered).to have_css(%(svg use[href$="#work-item-task"]))
    end
  end

  context 'for merge request' do
    let(:issuable) { create(:merge_request, source_project: project, target_project: project, assignees: [user]) }

    it 'links to merge requests page for user' do
      expect(rendered).to have_css("a[href='#{project_merge_requests_path(project, milestone_title: milestone.title, assignee_id: user.id, state: 'all')}']")
    end

    it 'links to the page for the merge request' do
      expect(rendered).to have_css("a[href$='#{project_merge_request_path(project, issuable)}']", class: 'issue-link')
    end

    it 'renders the merge request icon' do
      expect(rendered).to have_css(%(svg use[href$="#merge-request"]))
    end
  end
end
