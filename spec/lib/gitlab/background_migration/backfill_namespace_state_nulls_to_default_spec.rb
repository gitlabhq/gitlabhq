# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillNamespaceStateNullsToDefault, feature_category: :groups_and_projects do
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }

  let!(:organization) { organizations.create!(name: 'Test Organization', path: 'test-org') }

  let(:migration_attrs) do
    {
      start_cursor: [namespaces.minimum(:id)],
      end_cursor: [namespaces.maximum(:id)],
      batch_table: :namespaces,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  subject(:migration) { described_class.new(**migration_attrs) }

  describe '#perform' do
    context 'when namespace has NULL state' do
      let!(:group_with_null_state) { create_namespace(type: 'Group', state: nil) }
      let!(:project_namespace_with_null_state) do
        create_namespace(type: 'Project', parent_id: group_with_null_state.id, state: nil)
      end

      it 'updates state to 0 (ancestor_inherited)' do
        migration.perform

        expect(namespaces.find(group_with_null_state.id).state).to eq(0)
        expect(namespaces.find(project_namespace_with_null_state.id).state).to eq(0)
      end
    end

    context 'when namespace has non-NULL state' do
      let!(:archived_group) { create_namespace(type: 'Group', state: 1) }
      let!(:deletion_scheduled_group) { create_namespace(type: 'Group', state: 2) }
      let!(:deletion_in_progress_group) { create_namespace(type: 'Group', state: 4) }

      it 'does not change existing state values' do
        migration.perform

        expect(namespaces.find(archived_group.id).state).to eq(1)
        expect(namespaces.find(deletion_scheduled_group.id).state).to eq(2)
        expect(namespaces.find(deletion_in_progress_group.id).state).to eq(4)
      end
    end

    context 'with mixed state values' do
      let!(:group_with_null) { create_namespace(type: 'Group', state: nil) }
      let!(:group_with_state) { create_namespace(type: 'Group', state: 1) }
      let!(:another_group_with_null) { create_namespace(type: 'Group', state: nil) }

      it 'only updates NULL states to 0' do
        migration.perform

        expect(namespaces.find(group_with_null.id).state).to eq(0)
        expect(namespaces.find(group_with_state.id).state).to eq(1)
        expect(namespaces.find(another_group_with_null.id).state).to eq(0)
      end
    end

    context 'when called multiple times (idempotent)' do
      let!(:group) { create_namespace(type: 'Group', state: nil) }

      it 'can be run multiple times safely' do
        migration.perform
        expect(namespaces.find(group.id).state).to eq(0)

        migration.perform
        expect(namespaces.find(group.id).state).to eq(0)
      end
    end
  end

  private

  def create_namespace(type:, parent_id: nil, state: nil)
    path = "namespace_#{SecureRandom.hex(4)}"
    namespaces.create!(
      name: path,
      path: path,
      type: type,
      parent_id: parent_id,
      state: state,
      organization_id: organization.id
    )
  end
end
