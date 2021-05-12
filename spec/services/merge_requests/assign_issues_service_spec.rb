# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::AssignIssuesService do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:issue) { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, :simple, source_project: project, author: user, description: "fixes #{issue.to_reference}") }
  let(:service) { described_class.new(project: project, current_user: user, params: { merge_request: merge_request }) }

  before do
    project.add_developer(user)
  end

  it 'finds unassigned issues fixed in merge request' do
    expect(service.assignable_issues.map(&:id)).to include(issue.id)
  end

  it 'ignores issues the user cannot update assignee on' do
    project.team.truncate

    expect(service.assignable_issues).to be_empty
  end

  it 'ignores issues already assigned to any user' do
    issue.assignees = [create(:user)]

    expect(service.assignable_issues).to be_empty
  end

  it 'ignores all issues unless current_user is merge_request.author' do
    merge_request.update!(author: create(:user))

    expect(service.assignable_issues).to be_empty
  end

  it 'accepts precomputed data for closes_issues' do
    issue2 = create(:issue, project: project)
    service2 = described_class.new(project: project,
                                   current_user: user,
                                   params: {
                                     merge_request: merge_request,
                                     closes_issues: [issue, issue2]
                                   })

    expect(service2.assignable_issues.count).to eq 2
  end

  it 'assigns these to the merge request owner' do
    expect { service.execute }.to change { issue.assignees.first }.to(user)
  end

  it 'ignores external issues' do
    external_issue = ExternalIssue.new('JIRA-123', project)
    service = described_class.new(
      project: project,
      current_user: user,
      params: {
        merge_request: merge_request,
        closes_issues: [external_issue]
      }
    )

    expect(service.assignable_issues.count).to eq 0
  end
end
