# frozen_string_literal: true

require 'spec_helper'

describe Todos::Destroy::EntityLeaveService do
  let(:group)   { create(:group, :private) }
  let(:project) { create(:project, group: group) }
  let(:user)    { create(:user) }
  let(:user2)   { create(:user) }
  let(:issue)   { create(:issue, project: project, confidential: true) }
  let(:mr)      { create(:merge_request, source_project: project) }

  let!(:todo_mr_user)     { create(:todo, user: user, target: mr, project: project) }
  let!(:todo_issue_user)  { create(:todo, user: user, target: issue, project: project) }
  let!(:todo_group_user)  { create(:todo, user: user, group: group) }
  let!(:todo_issue_user2) { create(:todo, user: user2, target: issue, project: project) }
  let!(:todo_group_user2) { create(:todo, user: user2, group: group) }

  describe '#execute' do
    context 'when a user leaves a project' do
      subject { described_class.new(user.id, project.id, 'Project').execute }

      context 'when project is private' do
        it 'removes project todos for the provided user' do
          expect { subject }.to change { Todo.count }.from(5).to(3)

          expect(user.todos).to match_array([todo_group_user])
          expect(user2.todos).to match_array([todo_issue_user2, todo_group_user2])
        end

        context 'when the user is member of the project' do
          before do
            project.add_developer(user)
          end

          it 'does not remove any todos' do
            expect { subject }.not_to change { Todo.count }
          end
        end

        context 'when the user is a project guest' do
          before do
            project.add_guest(user)
          end

          it 'removes only confidential issues todos' do
            expect { subject }.to change { Todo.count }.from(5).to(4)
          end
        end

        context 'when the user is member of a parent group' do
          before do
            group.add_developer(user)
          end

          it 'does not remove any todos' do
            expect { subject }.not_to change { Todo.count }
          end
        end

        context 'when the user is guest of a parent group' do
          before do
            project.add_guest(user)
          end

          it 'removes only confidential issues todos' do
            expect { subject }.to change { Todo.count }.from(5).to(4)
          end
        end
      end

      context 'when project is not private' do
        before do
          group.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
          project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
        end

        it 'enqueues the PrivateFeaturesWorker' do
          expect(TodosDestroyer::PrivateFeaturesWorker)
            .to receive(:perform_async).with(project.id, user.id)

          subject
        end

        context 'confidential issues' do
          context 'when a user is not an author of confidential issue' do
            it 'removes only confidential issues todos' do
              expect { subject }.to change { Todo.count }.from(5).to(4)
            end
          end

          context 'when a user is an author of confidential issue' do
            before do
              issue.update!(author: user)
            end

            it 'does not remove any todos' do
              expect { subject }.not_to change { Todo.count }
            end
          end

          context 'when a user is an assignee of confidential issue' do
            before do
              issue.assignees << user
            end

            it 'does not remove any todos' do
              expect { subject }.not_to change { Todo.count }
            end
          end

          context 'when a user is a project guest' do
            before do
              project.add_guest(user)
            end

            it 'removes only confidential issues todos' do
              expect { subject }.to change { Todo.count }.from(5).to(4)
            end
          end

          context 'when a user is a project guest but group developer' do
            before do
              project.add_guest(user)
              group.add_developer(user)
            end

            it 'does not remove any todos' do
              expect { subject }.not_to change { Todo.count }
            end
          end
        end

        context 'feature visibility check' do
          context 'when issues are visible only to project members' do
            before do
              project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
            end

            it 'removes only users issue todos' do
              expect { subject }.to change { Todo.count }.from(5).to(4)
            end
          end
        end
      end
    end

    context 'when a user leaves a group' do
      subject { described_class.new(user.id, group.id, 'Group').execute }

      context 'when group is private' do
        it 'removes group and subproject todos for the user' do
          expect { subject }.to change { Todo.count }.from(5).to(2)

          expect(user.todos).to be_empty
          expect(user2.todos).to match_array([todo_issue_user2, todo_group_user2])
        end

        context 'when the user is member of the group' do
          before do
            group.add_developer(user)
          end

          it 'does not remove any todos' do
            expect { subject }.not_to change { Todo.count }
          end
        end

        context 'when the user is member of the group project but not the group' do
          before do
            project.add_developer(user)
          end

          it 'does not remove any todos' do
            expect { subject }.not_to change { Todo.count }
          end
        end

        context 'with nested groups', :nested_groups do
          let(:subgroup) { create(:group, :private, parent: group) }
          let(:subgroup2) { create(:group, :private, parent: group) }
          let(:subproject) { create(:project, group: subgroup) }
          let(:subproject2) { create(:project, group: subgroup2) }

          let!(:todo_subproject_user) { create(:todo, user: user, project: subproject) }
          let!(:todo_subproject2_user) { create(:todo, user: user, project: subproject2) }
          let!(:todo_subgroup_user) { create(:todo, user: user, group: subgroup) }
          let!(:todo_subgroup2_user) { create(:todo, user: user, group: subgroup2) }
          let!(:todo_subproject_user2) { create(:todo, user: user2, project: subproject) }
          let!(:todo_subpgroup_user2)  { create(:todo, user: user2, group: subgroup) }

          context 'when the user is not a member of any groups/projects' do
            it 'removes todos for the user including subprojects todos' do
              expect { subject }.to change { Todo.count }.from(11).to(4)

              expect(user.todos).to be_empty
              expect(user2.todos)
                .to match_array(
                  [todo_issue_user2, todo_group_user2, todo_subproject_user2, todo_subpgroup_user2]
                )
            end
          end

          context 'when the user is member of a parent group' do
            before do
              parent_group = create(:group)
              group.update!(parent: parent_group)
              parent_group.add_developer(user)
            end

            it 'does not remove any todos' do
              expect { subject }.not_to change { Todo.count }
            end
          end

          context 'when the user is member of a subgroup' do
            before do
              subgroup.add_developer(user)
            end

            it 'does not remove group and subproject todos' do
              expect { subject }.to change { Todo.count }.from(11).to(7)

              expect(user.todos).to match_array([todo_group_user, todo_subgroup_user, todo_subproject_user])
              expect(user2.todos)
                .to match_array(
                  [todo_issue_user2, todo_group_user2, todo_subproject_user2, todo_subpgroup_user2]
                )
            end
          end

          context 'when the user is member of a child project' do
            before do
              subproject.add_developer(user)
            end

            it 'does not remove subproject and group todos' do
              expect { subject }.to change { Todo.count }.from(11).to(7)

              expect(user.todos).to match_array([todo_subgroup_user, todo_group_user, todo_subproject_user])
              expect(user2.todos)
                .to match_array(
                  [todo_issue_user2, todo_group_user2, todo_subproject_user2, todo_subpgroup_user2]
                )
            end
          end
        end
      end

      context 'when group is not private' do
        before do
          group.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
          project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
        end

        it 'enqueues the PrivateFeaturesWorker' do
          expect(TodosDestroyer::PrivateFeaturesWorker)
            .to receive(:perform_async).with(project.id, user.id)

          subject
        end

        context 'when user is not member' do
          it 'removes only confidential issues todos' do
            expect { subject }.to change { Todo.count }.from(5).to(4)
          end
        end

        context 'when user is a project guest' do
          before do
            project.add_guest(user)
          end

          it 'removes only confidential issues todos' do
            expect { subject }.to change { Todo.count }.from(5).to(4)
          end
        end

        context 'when user is a project guest & group developer' do
          before do
            project.add_guest(user)
            group.add_developer(user)
          end

          it 'does not remove any todos' do
            expect { subject }.not_to change { Todo.count }
          end
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
