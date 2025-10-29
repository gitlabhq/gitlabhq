# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSystemNoteMetadataNamespaceId, feature_category: :team_planning do
  # rubocop:disable RSpec/MultipleMemoizedHelpers -- Necessary for backfill setup
  let(:namespaces) { table(:namespaces) }
  let(:notes) { table(:notes) }
  let(:projects) { table(:projects) }
  let(:system_note_metadata) { table(:system_note_metadata) }
  let(:users) { table(:users) }
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
    users.create!(
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

  let(:note_metadata1) { system_note_metadata.create!(note_id: note1.id) }
  let(:note2) do
    notes.create!(
      project_id: project2.id,
      namespace_id: group_namespace2.id, # Wrong namespace so we can test precedence with project_id column
      noteable_type: 'Issue',
      noteable_id: 2,
      author_id: user.id
    )
  end

  let(:note_metadata2) { system_note_metadata.create!(note_id: note2.id) }
  let(:note3) do
    notes.create!(
      project_id: nil,
      namespace_id: group_namespace1.id,
      noteable_type: 'Issue',
      noteable_id: 3,
      author_id: user.id
    )
  end

  let(:note_metadata3) { system_note_metadata.create!(note_id: note3.id) }
  let(:note4) do
    notes.create!(
      project_id: nil,
      namespace_id: group_namespace2.id,
      noteable_type: 'Issue',
      noteable_id: 4,
      author_id: user.id
    )
  end

  let(:note_metadata4) { system_note_metadata.create!(note_id: note4.id) }
  let(:note5) do
    notes.create!(
      project_id: project1.id,
      namespace_id: project_namespace1.id,
      noteable_type: 'Issue',
      noteable_id: 5,
      author_id: user.id
    )
  end

  let(:note_metadata5) { system_note_metadata.create!(note_id: note5.id, namespace_id: project_namespace1.id) }

  let(:note6) do
    notes.create!(
      project_id: project2.id,
      namespace_id: group_namespace2.id,
      noteable_type: 'Issue',
      noteable_id: 6,
      author_id: user.id
    )
  end

  let(:note_metadata6) { system_note_metadata.create!(note_id: note6.id, namespace_id: group_namespace2.id) }

  describe '#perform' do
    let(:migration) do
      start_id, end_id = system_note_metadata.pick('MIN(id), MAX(id)')

      described_class.new(
        start_id: start_id,
        end_id: end_id,
        batch_table: :system_note_metadata,
        batch_column: :id,
        sub_batch_size: 2,
        pause_ms: 0,
        job_arguments: [],
        connection: ApplicationRecord.connection
      )
    end

    subject(:migrate) { migration.perform }

    before do
      system_note_metadata.connection.execute(<<~SQL)
        -- Necessary as the constraint won't allow new invalid records to be created
        ALTER TABLE system_note_metadata DROP CONSTRAINT check_9135b6f0b6;
        -- Also disabling the trigger that will set the correct value in the column
        ALTER TABLE system_note_metadata DISABLE TRIGGER ALL;
      SQL

      note_metadata1
      note_metadata2
      note_metadata3
      note_metadata4
      note_metadata5

      system_note_metadata.connection.execute(<<~SQL)
        ALTER TABLE system_note_metadata
          ADD CONSTRAINT check_9135b6f0b6 CHECK (namespace_id IS NOT NULL) NOT VALID;

        ALTER TABLE system_note_metadata ENABLE TRIGGER ALL;
      SQL
    end

    it 'updates records in batches' do
      expect do
        migrate
      end.to make_queries_matching(/UPDATE\s+"system_note_metadata"/, 3)
    end

    it 'sets correct namespace_id in every record' do
      expect { migrate }.to change { note_metadata1.reload.namespace_id }.from(nil).to(project_namespace1.id).and(
        change { note_metadata2.reload.namespace_id }.from(nil).to(project_namespace2.id)
      ).and(
        change { note_metadata3.reload.namespace_id }.from(nil).to(group_namespace1.id)
      ).and(
        change { note_metadata4.reload.namespace_id }.from(nil).to(group_namespace2.id)
      ).and(
        not_change { note_metadata5.reload.namespace_id }.from(project_namespace1.id)
      ).and(
        change { note_metadata6.reload.namespace_id }.from(group_namespace2.id).to(project_namespace2.id)
      )
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
