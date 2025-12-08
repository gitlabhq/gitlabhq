# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillNoteMetadataNamespaceId, feature_category: :code_review_workflow do
  let(:constraint_name) { 'check_67a890ebba' }
  let(:trigger_name) { 'set_sharding_key_for_note_metadata_on_insert_and_update' }
  let(:email) { 'user@example.com' }

  let(:notes) { table(:notes) }
  let(:note_metadata) { table(:note_metadata) }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:project_namespace1) do
    table(:namespaces).create!(name: 'project1', path: 'project1', organization_id: organization.id)
  end

  let(:project_namespace2) do
    table(:namespaces).create!(name: 'project2', path: 'project2', organization_id: organization.id)
  end

  let(:group_namespace1) do
    table(:namespaces).create!(name: 'group1', path: 'group1', organization_id: organization.id)
  end

  let(:group_namespace2) do
    table(:namespaces).create!(name: 'group2', path: 'group2', organization_id: organization.id)
  end

  let(:project1) do
    table(:projects).create!(
      namespace_id: group_namespace1.id,
      project_namespace_id: project_namespace1.id,
      organization_id: organization.id
    )
  end

  let(:project2) do
    table(:projects).create!(
      namespace_id: group_namespace2.id,
      project_namespace_id: project_namespace2.id,
      organization_id: organization.id
    )
  end

  let(:user) do
    table(:users).create!(
      username: 'john_doe', email: 'johndoe@gitlab.com', projects_limit: 10, organization_id: organization.id
    )
  end

  let(:note1) do
    notes.create!(
      project_id: project1.id,
      namespace_id: nil,
      noteable_type: 'Issue',
      noteable_id: 1,
      author_id: user.id
    )
  end

  let(:note_metadata1) { note_metadata.create!(note_id: note1.id, email_participant: email) }
  let(:note2) do
    notes.create!(
      project_id: project2.id,
      namespace_id: group_namespace2.id, # Wrong namespace so we can test precedence with project_id column
      noteable_type: 'Issue',
      noteable_id: 2,
      author_id: user.id
    )
  end

  let(:note_metadata2) { note_metadata.create!(note_id: note2.id, email_participant: email) }
  let(:note3) do
    notes.create!(
      project_id: nil,
      namespace_id: group_namespace1.id,
      noteable_type: 'Issue',
      noteable_id: 3,
      author_id: user.id
    )
  end

  let(:note_metadata3) { note_metadata.create!(note_id: note3.id, email_participant: email) }
  let(:note4) do
    notes.create!(
      project_id: nil,
      namespace_id: group_namespace2.id,
      noteable_type: 'Issue',
      noteable_id: 4,
      author_id: user.id
    )
  end

  let(:note_metadata4) { note_metadata.create!(note_id: note4.id, email_participant: email) }
  let(:note5) do
    notes.create!(
      project_id: project1.id,
      namespace_id: project_namespace1.id,
      noteable_type: 'Issue',
      noteable_id: 5,
      author_id: user.id
    )
  end

  let(:note_metadata5) do
    note_metadata.create!(note_id: note5.id, email_participant: email, namespace_id: project_namespace1.id)
  end

  describe '#perform' do
    let(:migration) do
      start_id, end_id = note_metadata.pick('MIN(note_id), MAX(note_id)')

      described_class.new(
        start_id: start_id,
        end_id: end_id,
        batch_table: :note_metadata,
        batch_column: :note_id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      )
    end

    subject(:migrate) { migration.perform }

    before do
      # Necessary as the constraint won't allow new invalid records to be created
      # Also disabling the trigger that will set the correct value in the column
      ApplicationRecord.connection.execute("ALTER TABLE note_metadata DROP CONSTRAINT #{constraint_name}")
      ApplicationRecord.connection.execute("ALTER TABLE note_metadata DISABLE TRIGGER #{trigger_name}")

      note_metadata1
      note_metadata2
      note_metadata3
      note_metadata4
      note_metadata5

      ApplicationRecord.connection.execute(
        "ALTER TABLE note_metadata ADD CONSTRAINT #{constraint_name} CHECK (namespace_id IS NOT NULL) NOT VALID"
      )
      ApplicationRecord.connection.execute("ALTER TABLE note_metadata ENABLE TRIGGER #{trigger_name}")
    end

    it 'updates records in batches' do
      expect do
        migrate
      end.to make_queries_matching(/UPDATE\s+"note_metadata"/, 3)
    end

    it 'sets correct namespace_id in every record' do
      expect { migrate }
        .to change { note_metadata1.reload.namespace_id }.from(nil).to(project_namespace1.id)
        .and change { note_metadata2.reload.namespace_id }.from(nil).to(project_namespace2.id)
        .and change { note_metadata3.reload.namespace_id }.from(nil).to(group_namespace1.id)
        .and change { note_metadata4.reload.namespace_id }.from(nil).to(group_namespace2.id)
        .and not_change { note_metadata5.reload.namespace_id }.from(project_namespace1.id)
    end
  end
end
