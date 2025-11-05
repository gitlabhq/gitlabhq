# frozen_string_literal: true

# This shared example requires the following variables:
# - table_name: The name of the table being migrated
# - constraint_name: The name of the migrated column constraint to be added/removed
# - trigger_name: The name of the trigger column constraint to be disabled/enabled
# - record_attrs: Base attributes for creating migration records
# - note_fk: Foreign key column name for the note association

RSpec.shared_examples 'backfill migration for notes children sharding key' do
  describe '#perform' do
    let(:migration_table) { table(table_name) }
    let(:connection) { migration_table.connection }
    let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

    let(:namespace1) do
      table(:namespaces).create!(name: 'namespace1', path: 'namespace1', organization_id: organization.id)
    end

    let(:namespace2) do
      table(:namespaces).create!(name: 'namespace2', path: 'namespace2', organization_id: organization.id)
    end

    let(:project1) do
      table(:projects).create!(
        namespace_id: namespace1.id,
        project_namespace_id: namespace1.id,
        organization_id: organization.id
      )
    end

    let(:project2) do
      table(:projects).create!(
        namespace_id: namespace2.id,
        project_namespace_id: namespace2.id,
        organization_id: organization.id
      )
    end

    let!(:user) do
      table(:users).create!(
        username: 'john_doe', email: 'johndoe@gitlab.com', projects_limit: 10, organization_id: organization.id
      )
    end

    let(:note1) { create_note(project1, 1) }
    let(:note2) { create_note(project2, 2) }
    let(:note3) { create_note(project1, 3) }
    let(:note4) { create_note(project2, 4) }

    let(:record1) { create_migration_record(note1, record_attrs) }
    let(:record2) { create_migration_record(note2, record_attrs) }
    # namespace_id is already set
    let(:record3) { create_migration_record(note3, record_attrs.merge(namespace_id: namespace1.id)) }
    # namespace_id is incorrect
    let(:record4) { create_migration_record(note4, record_attrs.merge(namespace_id: namespace1.id)) }

    let(:migration) do
      start_id, end_id = migration_table.pick('MIN(id), MAX(id)')

      described_class.new(
        start_id: start_id,
        end_id: end_id,
        batch_table: table_name,
        batch_column: :id,
        sub_batch_size: 2,
        pause_ms: 0,
        job_arguments: [],
        connection: ApplicationRecord.connection
      )
    end

    subject(:migrate) { migration.perform }

    before do
      # Necessary as the constraint won't allow new invalid records to be created
      # Also disabling the trigger that will set the correct value in the column
      connection.execute("ALTER TABLE #{table_name} DROP CONSTRAINT #{constraint_name}")
      connection.execute("ALTER TABLE #{table_name} DISABLE TRIGGER #{trigger_name}")

      record1
      record2
      record3
      record4
    end

    after do
      connection.execute(
        "ALTER TABLE #{table_name} ADD CONSTRAINT #{constraint_name} CHECK (namespace_id IS NOT NULL) NOT VALID"
      )
      connection.execute("ALTER TABLE #{table_name} ENABLE TRIGGER #{trigger_name}")
    end

    it 'updates records in batches' do
      expect do
        migrate
      end.to make_queries_matching(/UPDATE\s+"#{table_name}"/, 2)
    end

    it 'sets correct namespace_id in every record' do
      expect { migrate }
        .to change { record1.reload.namespace_id }.from(nil).to(namespace1.id)
        .and(change { record2.reload.namespace_id }.from(nil).to(namespace2.id))
        .and(not_change { record3.reload.namespace_id }.from(namespace1.id))
        .and(change { record4.reload.namespace_id }.from(namespace1.id).to(namespace2.id))
    end

    private

    def create_migration_record(note, attrs)
      attrs = attrs.dup
      attrs[note_fk] = note.id
      migration_table.insert_all([attrs])
      migration_table.find_by(attrs)
    end

    def create_note(project, noteable_id)
      table(:notes).create!(
        project_id: project.id,
        noteable_type: 'Commit',
        noteable_id: noteable_id,
        author_id: user.id
      )
    end
  end
end
