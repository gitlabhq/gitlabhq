# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::RemoveRestrictedTodos, :migration, schema: 20180704204006 do
  let(:projects)               { table(:projects) }
  let(:users)                  { table(:users) }
  let(:todos)                  { table(:todos) }
  let(:issues)                 { table(:issues) }
  let(:assignees)              { table(:issue_assignees) }
  let(:project_authorizations) { table(:project_authorizations) }
  let(:project_features)       { table(:project_features) }

  let(:todo_params) { { author_id: 1, target_type: 'Issue', action: 1, state: :pending } }

  before do
    users.create(id: 1, email: 'user@example.com', projects_limit: 10)
    users.create(id: 2, email: 'reporter@example.com', projects_limit: 10)
    users.create(id: 3, email: 'guest@example.com', projects_limit: 10)

    projects.create!(id: 1, name: 'project-1', path: 'project-1', visibility_level: 0, namespace_id: 1)
    projects.create!(id: 2, name: 'project-2', path: 'project-2', visibility_level: 0, namespace_id: 1)

    issues.create(id: 1, project_id: 1)
    issues.create(id: 2, project_id: 2)

    project_authorizations.create(user_id: 2, project_id: 2, access_level: 20) # reporter
    project_authorizations.create(user_id: 3, project_id: 2, access_level: 10) # guest

    todos.create(todo_params.merge(user_id: 1, project_id: 1, target_id: 1)) # out of project ids range
    todos.create(todo_params.merge(user_id: 1, project_id: 2, target_id: 2)) # non member
    todos.create(todo_params.merge(user_id: 2, project_id: 2, target_id: 2)) # reporter
    todos.create(todo_params.merge(user_id: 3, project_id: 2, target_id: 2)) # guest
  end

  subject { described_class.new.perform(2, 5) }

  context 'when a project is private' do
    it 'removes todos of users without project access' do
      expect { subject }.to change { Todo.count }.from(4).to(3)
    end

    context 'with a confidential issue' do
      it 'removes todos of users without project access and guests for confidential issues' do
        issues.create(id: 3, project_id: 2, confidential: true)
        issues.create(id: 4, project_id: 1, confidential: true) # not in the batch
        todos.create(todo_params.merge(user_id: 3, project_id: 2, target_id: 3))
        todos.create(todo_params.merge(user_id: 2, project_id: 2, target_id: 3))
        todos.create(todo_params.merge(user_id: 1, project_id: 1, target_id: 4))

        expect { subject }.to change { Todo.count }.from(7).to(5)
      end
    end
  end

  context 'when a project is public' do
    before do
      projects.find(2).update_attribute(:visibility_level, 20)
    end

    context 'when all features have the same visibility as the project, no confidential issues' do
      it 'does not remove any todos' do
        expect { subject }.not_to change { Todo.count }
      end
    end

    context 'with confidential issues' do
      before do
        users.create(id: 4, email: 'author@example.com', projects_limit: 10)
        users.create(id: 5, email: 'assignee@example.com', projects_limit: 10)
        issues.create(id: 3, project_id: 2, confidential: true, author_id: 4)
        assignees.create(user_id: 5, issue_id: 3)

        todos.create(todo_params.merge(user_id: 1, project_id: 2, target_id: 3)) # to be deleted
        todos.create(todo_params.merge(user_id: 2, project_id: 2, target_id: 3)) # authorized user
        todos.create(todo_params.merge(user_id: 3, project_id: 2, target_id: 3)) # to be deleted guest
        todos.create(todo_params.merge(user_id: 4, project_id: 2, target_id: 3)) # conf issue author
        todos.create(todo_params.merge(user_id: 5, project_id: 2, target_id: 3)) # conf issue assignee
      end

      it 'removes confidential issue todos for non authorized users' do
        expect { subject }.to change { Todo.count }.from(9).to(7)
      end
    end

    context 'features visibility restrictions' do
      before do
        todo_params.merge!(project_id: 2, user_id: 1, target_id: 3)
        todos.create(todo_params.merge(user_id: 1, target_id: 3, target_type: 'MergeRequest'))
        todos.create(todo_params.merge(user_id: 1, target_id: 3, target_type: 'Commit'))
      end

      context 'when issues are restricted to project members' do
        before do
          project_features.create(issues_access_level: 10, project_id: 2)
        end

        it 'removes non members issue todos' do
          expect { subject }.to change { Todo.count }.from(6).to(5)
        end
      end

      context 'when merge requests are restricted to project members' do
        before do
          project_features.create(merge_requests_access_level: 10, project_id: 2)
        end

        it 'removes non members issue todos' do
          expect { subject }.to change { Todo.count }.from(6).to(5)
        end
      end

      context 'when repository and merge requests are restricted to project members' do
        before do
          project_features.create(repository_access_level: 10, merge_requests_access_level: 10, project_id: 2)
        end

        it 'removes non members commit and merge requests todos' do
          expect { subject }.to change { Todo.count }.from(6).to(4)
        end
      end
    end
  end
end
