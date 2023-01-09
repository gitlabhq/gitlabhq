# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupMrAttentionRequestTodos, :migration, feature_category: :code_review_workflow do
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:todos) { table(:todos) }

  let(:author) { users.create!(projects_limit: 1) }
  let(:namespace) { namespaces.create!(name: 'test', path: 'test') }
  let(:project) do
    projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      name: 'test-project'
    )
  end

  let(:attention_requested) { 10 }
  let(:todo_attrs) do
    {
      project_id: project.id,
      author_id: author.id,
      user_id: author.id,
      target_type: 'TestType',
      state: 'pending'
    }
  end

  let!(:todo1) { todos.create!(todo_attrs.merge(action: Todo::ASSIGNED)) }
  let!(:todo2) { todos.create!(todo_attrs.merge(action: Todo::MENTIONED)) }
  let!(:todo3) { todos.create!(todo_attrs.merge(action: Todo::REVIEW_REQUESTED)) }
  let!(:todo4) { todos.create!(todo_attrs.merge(action: attention_requested)) }
  let!(:todo5) { todos.create!(todo_attrs.merge(action: attention_requested)) }

  describe '#up' do
    it 'clean up attention request todos' do
      expect { migrate! }.to change(todos, :count).by(-2)

      expect(todos.all).to include(todo1, todo2, todo3)
    end
  end
end
