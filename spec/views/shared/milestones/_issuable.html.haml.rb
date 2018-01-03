require 'spec_helper'

describe 'shared/milestones/_issuable.html.haml' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:milestone) { create(:milestone, project: project) }
  let(:issuable) { create(:issue, project: project, assignees: [user]) }

  before do
    assign(:project, project)
    assign(:milestone, milestone)
  end

  it 'avatar links to issues page' do
    render 'shared/milestones/issuable', issuable: issuable, show_project_name: true

    expect(rendered).to have_css("a[href='#{project_issues_path(project, milestone_title: milestone.title, assignee_id: user.id, state: 'all')}']")
  end
end
