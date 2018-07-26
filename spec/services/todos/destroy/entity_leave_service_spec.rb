require 'spec_helper'

describe Todos::Destroy::EntityLeaveService do
  let(:group)          { create(:group, :private) }
  let(:project)        { create(:project, group: group) }
  let(:user)           { create(:user) }
  let(:project_member) { create(:user) }
  let(:issue)          { create(:issue, :confidential, project: project) }

  let!(:todo_non_member)            { create(:todo, user: user, project: project) }
  let!(:todo_conf_issue_non_member) { create(:todo, user: user, target: issue, project: project) }
  let!(:todo_conf_issue_member)     { create(:todo, user: project_member, target: issue, project: project) }

  describe '#execute' do
    before do
      project.add_developer(project_member)
    end

    context 'when a user leaves a project' do
      subject { described_class.new(user.id, project.id, 'Project').execute }

      context 'when project is private' do
        it 'removes todos for a user who is not a member' do
          expect { subject }.to change { Todo.count }.from(3).to(1)

          expect(user.todos).to be_empty
          expect(project_member.todos).to match_array([todo_conf_issue_member])
        end
      end

      context 'when project is not private' do
        context 'when a user is not an author of confidential issue' do
          before do
            group.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
            project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
          end

          it 'removes only confidential issues todos' do
            expect { subject }.to change { Todo.count }.from(3).to(2)
          end
        end

        context 'when a user is an author of confidential issue' do
          before do
            issue.update!(author: user)

            group.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
            project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
          end

          it 'removes only confidential issues todos' do
            expect { subject }.not_to change { Todo.count }
          end
        end

        context 'when a user is an assignee of confidential issue' do
          before do
            issue.assignees << user

            group.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
            project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
          end

          it 'removes only confidential issues todos' do
            expect { subject }.not_to change { Todo.count }
          end
        end
      end
    end

    context 'when a user leaves a group' do
      subject { described_class.new(user.id, group.id, 'Group').execute }

      context 'when group is private' do
        it 'removes todos for a user who is not a member' do
          expect { subject }.to change { Todo.count }.from(3).to(1)

          expect(user.todos).to be_empty
          expect(project_member.todos).to match_array([todo_conf_issue_member])
        end

        context 'with nested groups', :nested_groups do
          let(:subgroup) { create(:group, :private, parent: group) }
          let(:subproject) { create(:project, group: subgroup) }

          let!(:todo_subproject_non_member) { create(:todo, user: user, project: subproject) }
          let!(:todo_subproject_member) { create(:todo, user: project_member, project: subproject) }

          it 'removes todos for a user who is not a member' do
            expect { subject }.to change { Todo.count }.from(5).to(2)

            expect(user.todos).to be_empty
            expect(project_member.todos)
              .to match_array([todo_conf_issue_member, todo_subproject_member])
          end
        end
      end

      context 'when group is not private' do
        before do
          group.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
        end

        it 'removes only confidential issues todos' do
          expect { subject }.to change { Todo.count }.from(3).to(2)
        end
      end
    end

    context 'when entity type is not valid' do
      it 'raises an exception' do
        expect { described_class.new(user.id, group.id, 'GroupWrongly').execute }
          .to raise_error(ArgumentError)
      end
    end

    context 'when entity was not found' do
      it 'does not remove any todos' do
        expect { described_class.new(user.id, 999999, 'Group').execute }
          .not_to change { Todo.count }
      end
    end
  end
end
