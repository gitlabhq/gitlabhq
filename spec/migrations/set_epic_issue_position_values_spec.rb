require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20171221154744_set_epic_issue_position_values.rb')

describe SetEpicIssuePositionValues, :migration do
  let(:groups) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:issues) { table(:issues) }
  let(:epics) { table(:epics) }
  let(:epic_issues) { table(:epic_issues) }

  let(:group) { groups.create(name: 'group', path: 'group') }
  let(:project) { projects.create(name: 'group', namespace_id: group.id) }
  let(:user) { users.create(username: 'User') }

  let(:epic1) { epics.create(title: 'Epic 1', title_html: 'Epic 1', group_id: group.id, author_id: user.id, iid: 1) }
  let(:epic2) { epics.create(title: 'Epic 1', title_html: 'Epic 1', group_id: group.id, author_id: user.id, iid: 1) }

  let(:issue1) { issues.create(title: 'Issue 1', title_html: 'Issue 1', project_id: project.id, author_id: user.id) }
  let(:issue2) { issues.create(title: 'Issue 2', title_html: 'Issue 1', project_id: project.id, author_id: user.id) }
  let(:issue3) { issues.create(title: 'Issue 3', title_html: 'Issue 1', project_id: project.id, author_id: user.id) }
  let(:issue4) { issues.create(title: 'Issue 4', title_html: 'Issue 1', project_id: project.id, author_id: user.id) }
  let(:issue5) { issues.create(title: 'Issue 5', title_html: 'Issue 1', project_id: project.id, author_id: user.id) }

  let!(:epic_issue1) { epic_issues.create!(epic_id: epic1.id, issue_id: issue1.id) }
  let!(:epic_issue2) { epic_issues.create!(epic_id: epic1.id, issue_id: issue2.id) }
  let!(:epic_issue3) { epic_issues.create!(epic_id: epic2.id, issue_id: issue3.id) }
  let!(:epic_issue4) { epic_issues.create!(epic_id: epic2.id, issue_id: issue4.id) }
  let!(:epic_issue5) { epic_issues.create!(epic_id: epic2.id, issue_id: issue5.id) }

  it 'sets the position value correctly' do
    migrate!

    expect(epic_issue1.reload.position).to eq(1)
    expect(epic_issue2.reload.position).to eq(2)
    expect(epic_issue3.reload.position).to eq(1)
    expect(epic_issue4.reload.position).to eq(2)
    expect(epic_issue5.reload.position).to eq(3)
  end
end
