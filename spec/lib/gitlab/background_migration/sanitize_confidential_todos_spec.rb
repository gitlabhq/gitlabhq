# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::SanitizeConfidentialTodos, :migration, feature_category: :team_planning do
  let!(:issue_type_id) { table(:work_item_types).find_by(base_type: 0).id }

  let(:todos) { table(:todos) }
  let(:notes) { table(:notes) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_features) { table(:project_features) }
  let(:users) { table(:users) }
  let(:issues) { table(:issues) }
  let(:members) { table(:members) }
  let(:project_authorizations) { table(:project_authorizations) }

  let(:user) { users.create!(first_name: 'Test', last_name: 'User', email: 'test@user.com', projects_limit: 1) }
  let(:project_namespace1) { namespaces.create!(path: 'pns1', name: 'pns1') }
  let(:project_namespace2) { namespaces.create!(path: 'pns2', name: 'pns2') }

  let(:project1) do
    projects.create!(namespace_id: project_namespace1.id,
                     project_namespace_id: project_namespace1.id, visibility_level: 20)
  end

  let(:project2) do
    projects.create!(namespace_id: project_namespace2.id,
                     project_namespace_id: project_namespace2.id)
  end

  let(:issue1) do
    issues.create!(
      project_id: project1.id, namespace_id: project_namespace1.id, issue_type: 1, title: 'issue1', author_id: user.id,
      work_item_type_id: issue_type_id
    )
  end

  let(:issue2) do
    issues.create!(
      project_id: project2.id, namespace_id: project_namespace2.id, issue_type: 1, title: 'issue2',
      work_item_type_id: issue_type_id
    )
  end

  let(:public_note) { notes.create!(note: 'text', project_id: project1.id) }

  let(:confidential_note) do
    notes.create!(note: 'text', project_id: project1.id, confidential: true,
                  noteable_id: issue1.id, noteable_type: 'Issue')
  end

  let(:other_confidential_note) do
    notes.create!(note: 'text', project_id: project2.id, confidential: true,
                  noteable_id: issue2.id, noteable_type: 'Issue')
  end

  let(:common_params) { { user_id: user.id, author_id: user.id, action: 1, state: 'pending', target_type: 'Note' } }
  let!(:ignored_todo1) { todos.create!(**common_params) }
  let!(:ignored_todo2) { todos.create!(**common_params, target_id: public_note.id, note_id: public_note.id) }
  let!(:valid_todo) { todos.create!(**common_params, target_id: confidential_note.id, note_id: confidential_note.id) }
  let!(:invalid_todo) do
    todos.create!(**common_params, target_id: other_confidential_note.id, note_id: other_confidential_note.id)
  end

  describe '#perform' do
    before do
      project_features.create!(project_id: project1.id, issues_access_level: 20, pages_access_level: 20)
      members.create!(state: 0, source_id: project1.id, source_type: 'Project',
                      type: 'ProjectMember', user_id: user.id, access_level: 50, notification_level: 0,
                      member_namespace_id: project_namespace1.id)
      project_authorizations.create!(project_id: project1.id, user_id: user.id, access_level: 50)
    end

    subject(:perform) do
      described_class.new(
        start_id: notes.minimum(:id),
        end_id: notes.maximum(:id),
        batch_table: :notes,
        batch_column: :id,
        sub_batch_size: 1,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      ).perform
    end

    it 'deletes todos where user can not read its note and logs deletion', :aggregate_failures do
      expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |logger|
        expect(logger).to receive(:info).with(
          hash_including(
            message: "#{described_class.name} deleting invalid todo",
            attributes: hash_including(invalid_todo.attributes.slice(:id, :user_id, :target_id, :target_type))
          )
        ).once
      end

      expect { perform }.to change(todos, :count).by(-1)

      expect(todos.all).to match_array([ignored_todo1, ignored_todo2, valid_todo])
    end
  end
end
