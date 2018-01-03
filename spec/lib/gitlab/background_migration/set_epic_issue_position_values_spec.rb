require 'spec_helper'

describe Gitlab::BackgroundMigration::SetEpicIssuesPositionValues, :migration, schema: 20171221154744 do
  let(:groups) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:issues) { table(:issues) }
  let(:epics) { table(:epics) }
  let(:epic_issues) { table(:epic_issues) }

  let(:group) { groups.create(name: 'group', path: 'group') }
  let(:project) { projects.create(name: 'group', namespace_id: group.id) }
  let(:user) { users.create(username: 'User') }

  describe '#perform' do
    context 'when there are some epics in the db' do
      let(:epic1) { epics.create(id: 1, title: 'Epic 1', title_html: 'Epic 1', group_id: group.id, author_id: user.id, iid: 1) }
      let(:epic2) { epics.create(id: 2, title: 'Epic 2', title_html: 'Epic 2', group_id: group.id, author_id: user.id, iid: 2) }
      let!(:epic3) { epics.create(id: 3, title: 'Epic 3', title_html: 'Epic 3', group_id: group.id, author_id: user.id, iid: 3) }

      let(:issue1) { issues.create(title: 'Issue 1', title_html: 'Issue 1', project_id: project.id, author_id: user.id) }
      let(:issue2) { issues.create(title: 'Issue 2', title_html: 'Issue 2', project_id: project.id, author_id: user.id) }
      let(:issue3) { issues.create(title: 'Issue 3', title_html: 'Issue 3', project_id: project.id, author_id: user.id) }
      let(:issue4) { issues.create(title: 'Issue 4', title_html: 'Issue 4', project_id: project.id, author_id: user.id) }
      let(:issue5) { issues.create(title: 'Issue 5', title_html: 'Issue 5', project_id: project.id, author_id: user.id) }

      let!(:epic_issue1) { epic_issues.create!(epic_id: epic1.id, issue_id: issue1.id) }
      let!(:epic_issue2) { epic_issues.create!(epic_id: epic1.id, issue_id: issue2.id) }
      let!(:epic_issue3) { epic_issues.create!(epic_id: epic2.id, issue_id: issue3.id) }
      let!(:epic_issue4) { epic_issues.create!(epic_id: epic2.id, issue_id: issue4.id) }
      let!(:epic_issue5) { epic_issues.create!(epic_id: epic2.id, issue_id: issue5.id) }

      it 'sets the position value correctly' do
        subject.perform(1, 3)

        expect(epic_issue1.reload.position).to eq(1)
        expect(epic_issue2.reload.position).to eq(2)
        expect(epic_issue3.reload.position).to eq(1)
        expect(epic_issue4.reload.position).to eq(2)
        expect(epic_issue5.reload.position).to eq(3)
      end
    end

    context 'when there are no epics in the db' do
      it 'runs the migration without errors' do
        expect(subject.perform(1, 2)).to be_nil
      end
    end
  end
end
