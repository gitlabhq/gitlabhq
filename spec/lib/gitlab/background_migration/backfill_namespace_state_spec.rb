# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillNamespaceState, feature_category: :groups_and_projects do
  let(:namespaces) { table(:namespaces) }
  let(:namespace_details) { table(:namespace_details) }
  let(:namespace_settings) { table(:namespace_settings) }
  let(:group_deletion_schedules) { table(:group_deletion_schedules) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:organizations) { table(:organizations) }

  let!(:organization) { organizations.create!(name: 'Test Organization', path: 'test-org') }
  let!(:user) do
    users.create!(email: 'test@example.com', projects_limit: 10, username: 'testuser', organization_id: organization.id)
  end

  let(:migration_attrs) do
    {
      start_id: namespaces.minimum(:id),
      end_id: namespaces.maximum(:id),
      batch_table: :namespaces,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  subject(:migration) { described_class.new(**migration_attrs) }

  describe '#perform' do
    context 'when namespace has no special state' do
      let!(:group) { create_namespace(type: 'Group') }

      it 'does not update the state' do
        expect { migration.perform }.not_to change { namespaces.find(group.id).state }
      end

      it 'does not populate state_metadata' do
        migration.perform

        expect(fetch_metadata(group.id)).to be_empty
      end
    end

    describe 'archived state' do
      context 'when group is archived via namespace_settings' do
        let!(:group) { create_namespace(type: 'Group') }

        before do
          namespace_settings.create!(namespace_id: group.id, archived: true)
        end

        it 'sets state to archived' do
          migration.perform

          expect(namespaces.find(group.id).state).to eq(described_class::STATES[:archived])
        end

        it 'does not populate state_metadata (no metadata to store)' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata).to be_empty
        end
      end

      context 'when project namespace is archived via projects.archived' do
        let!(:group) { create_namespace(type: 'Group') }
        let!(:project_namespace) { create_namespace(type: 'Project', parent_id: group.id) }

        before do
          create_project(namespace_id: group.id, project_namespace_id: project_namespace.id, archived: true)
        end

        it 'sets state to archived' do
          migration.perform

          expect(namespaces.find(project_namespace.id).state).to eq(described_class::STATES[:archived])
        end
      end
    end

    describe 'deletion_scheduled state' do
      context 'when group has deletion scheduled via group_deletion_schedules' do
        let!(:group) { create_namespace(type: 'Group') }
        let(:scheduled_date) { Date.current }

        before do
          group_deletion_schedules.create!(
            group_id: group.id,
            marked_for_deletion_on: scheduled_date,
            user_id: user.id
          )
        end

        it 'sets state to deletion_scheduled' do
          migration.perform

          expect(namespaces.find(group.id).state).to eq(described_class::STATES[:deletion_scheduled])
        end

        it 'populates state_metadata with deletion info' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['deletion_scheduled_at']).to eq(scheduled_date.beginning_of_day.iso8601)
          expect(metadata['deletion_scheduled_by_user_id']).to eq(user.id)
        end

        it 'preserves ancestor_inherited as previous state' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['preserved_states']).to eq({ 'schedule_deletion' => 'ancestor_inherited' })
        end
      end

      context 'when project namespace has marked_for_deletion_at', :freeze_time do
        let!(:group) { create_namespace(type: 'Group') }
        let!(:project_namespace) { create_namespace(type: 'Project', parent_id: group.id) }
        let(:deletion_time) { Time.current.beginning_of_day }

        before do
          create_project(
            namespace_id: group.id,
            project_namespace_id: project_namespace.id,
            marked_for_deletion_at: deletion_time,
            marked_for_deletion_by_user_id: user.id,
            delete_error: 'Some error'
          )
        end

        it 'sets state to deletion_scheduled' do
          migration.perform

          expect(namespaces.find(project_namespace.id).state).to eq(described_class::STATES[:deletion_scheduled])
        end

        it 'populates state_metadata including delete_error' do
          migration.perform

          metadata = fetch_metadata(project_namespace.id)

          expect(metadata['deletion_scheduled_at']).to eq(deletion_time.iso8601)
          expect(metadata['deletion_scheduled_by_user_id']).to eq(user.id)
          expect(metadata['last_error']).to eq('Some error')
        end

        it 'preserves ancestor_inherited as previous state' do
          migration.perform

          metadata = fetch_metadata(project_namespace.id)

          expect(metadata['preserved_states']).to eq({ 'schedule_deletion' => 'ancestor_inherited' })
        end
      end
    end

    describe 'deletion_in_progress state' do
      context 'when group has namespace_details.deleted_at set' do
        let!(:group) { create_namespace(type: 'Group') }

        before do
          namespace_details.find_by(namespace_id: group.id).update!(deleted_at: Time.current)
        end

        it 'sets state to deletion_in_progress' do
          migration.perform

          expect(namespaces.find(group.id).state).to eq(described_class::STATES[:deletion_in_progress])
        end

        it 'preserves ancestor_inherited as previous state' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['preserved_states']).to eq({ 'start_deletion' => 'ancestor_inherited' })
        end
      end

      context 'when project namespace has pending_delete' do
        let!(:group) { create_namespace(type: 'Group') }
        let!(:project_namespace) { create_namespace(type: 'Project', parent_id: group.id) }

        before do
          create_project(
            namespace_id: group.id,
            project_namespace_id: project_namespace.id,
            pending_delete: true
          )
        end

        it 'sets state to deletion_in_progress' do
          migration.perform

          expect(namespaces.find(project_namespace.id).state).to eq(described_class::STATES[:deletion_in_progress])
        end

        it 'preserves ancestor_inherited as previous state' do
          migration.perform

          metadata = fetch_metadata(project_namespace.id)

          expect(metadata['preserved_states']).to eq({ 'start_deletion' => 'ancestor_inherited' })
        end
      end
    end

    describe 'state priority and preservation' do
      context 'when group is archived AND has deletion_scheduled' do
        let!(:group) { create_namespace(type: 'Group') }

        before do
          namespace_settings.create!(namespace_id: group.id, archived: true)
          group_deletion_schedules.create!(
            group_id: group.id,
            marked_for_deletion_on: Date.current,
            user_id: user.id
          )
        end

        it 'sets state to deletion_scheduled (higher priority)' do
          migration.perform

          expect(namespaces.find(group.id).state).to eq(described_class::STATES[:deletion_scheduled])
        end

        it 'preserves archived state for restoration via cancel_deletion' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['preserved_states']).to eq({ 'schedule_deletion' => 'archived' })
        end
      end

      context 'when group is archived AND in deletion_in_progress' do
        let!(:group) { create_namespace(type: 'Group') }

        before do
          namespace_settings.create!(namespace_id: group.id, archived: true)
          namespace_details.find_by(namespace_id: group.id).update!(deleted_at: Time.current)
        end

        it 'sets state to deletion_in_progress (highest priority)' do
          migration.perform

          expect(namespaces.find(group.id).state).to eq(described_class::STATES[:deletion_in_progress])
        end

        it 'preserves archived state for restoration via reschedule_deletion' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['preserved_states']).to eq({ 'start_deletion' => 'archived' })
        end
      end

      context 'when group is deletion_scheduled AND in deletion_in_progress' do
        let!(:group) { create_namespace(type: 'Group') }

        before do
          group_deletion_schedules.create!(
            group_id: group.id,
            marked_for_deletion_on: Date.current,
            user_id: user.id
          )
          namespace_details.find_by(namespace_id: group.id).update!(deleted_at: Time.current)
        end

        it 'sets state to deletion_in_progress (highest priority)' do
          migration.perform

          expect(namespaces.find(group.id).state).to eq(described_class::STATES[:deletion_in_progress])
        end

        it 'preserves deletion_scheduled state for restoration via reschedule_deletion' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['preserved_states']).to eq({ 'start_deletion' => 'deletion_scheduled' })
        end

        it 'retains deletion_scheduled metadata' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['deletion_scheduled_by_user_id']).to eq(user.id)
          expect(metadata['deletion_scheduled_at']).to be_present
        end
      end

      context 'when group has all three states: archived, deletion_scheduled, AND deletion_in_progress' do
        let!(:group) { create_namespace(type: 'Group') }

        before do
          namespace_settings.create!(namespace_id: group.id, archived: true)
          group_deletion_schedules.create!(
            group_id: group.id,
            marked_for_deletion_on: Date.current,
            user_id: user.id
          )
          namespace_details.find_by(namespace_id: group.id).update!(deleted_at: Time.current)
        end

        it 'sets state to deletion_in_progress (highest priority)' do
          migration.perform

          expect(namespaces.find(group.id).state).to eq(described_class::STATES[:deletion_in_progress])
        end

        it 'preserves both archived and deletion_scheduled states for full restoration chain' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['preserved_states']).to eq({
            'schedule_deletion' => 'archived',
            'start_deletion' => 'deletion_scheduled'
          })
        end
      end

      context 'when project namespace is archived AND has marked_for_deletion_at' do
        let!(:group) { create_namespace(type: 'Group') }
        let!(:project_namespace) { create_namespace(type: 'Project', parent_id: group.id) }

        before do
          create_project(
            namespace_id: group.id,
            project_namespace_id: project_namespace.id,
            archived: true,
            marked_for_deletion_at: Time.current,
            marked_for_deletion_by_user_id: user.id
          )
        end

        it 'sets state to deletion_scheduled (higher priority)' do
          migration.perform

          expect(namespaces.find(project_namespace.id).state).to eq(described_class::STATES[:deletion_scheduled])
        end

        it 'preserves archived state' do
          migration.perform

          metadata = fetch_metadata(project_namespace.id)

          expect(metadata['preserved_states']).to eq({ 'schedule_deletion' => 'archived' })
        end
      end

      context 'when project namespace is archived AND has pending_delete' do
        let!(:group) { create_namespace(type: 'Group') }
        let!(:project_namespace) { create_namespace(type: 'Project', parent_id: group.id) }

        before do
          create_project(
            namespace_id: group.id,
            project_namespace_id: project_namespace.id,
            archived: true,
            pending_delete: true
          )
        end

        it 'sets state to deletion_in_progress (highest priority)' do
          migration.perform

          expect(namespaces.find(project_namespace.id).state).to eq(described_class::STATES[:deletion_in_progress])
        end

        it 'preserves archived state' do
          migration.perform

          metadata = fetch_metadata(project_namespace.id)

          expect(metadata['preserved_states']).to eq({ 'start_deletion' => 'archived' })
        end
      end

      context 'when project namespace has marked_for_deletion_at AND pending_delete' do
        let!(:group) { create_namespace(type: 'Group') }
        let!(:project_namespace) { create_namespace(type: 'Project', parent_id: group.id) }

        before do
          create_project(
            namespace_id: group.id,
            project_namespace_id: project_namespace.id,
            marked_for_deletion_at: Time.current,
            marked_for_deletion_by_user_id: user.id,
            pending_delete: true
          )
        end

        it 'sets state to deletion_in_progress (highest priority)' do
          migration.perform

          expect(namespaces.find(project_namespace.id).state).to eq(described_class::STATES[:deletion_in_progress])
        end

        it 'preserves deletion_scheduled state' do
          migration.perform

          metadata = fetch_metadata(project_namespace.id)

          expect(metadata['preserved_states']).to eq({ 'start_deletion' => 'deletion_scheduled' })
        end

        it 'retains deletion_scheduled metadata' do
          migration.perform

          metadata = fetch_metadata(project_namespace.id)

          expect(metadata['deletion_scheduled_by_user_id']).to eq(user.id)
          expect(metadata['deletion_scheduled_at']).to be_present
        end
      end

      context 'when project namespace has all three states: archived, marked_for_deletion_at, AND pending_delete' do
        let!(:group) { create_namespace(type: 'Group') }
        let!(:project_namespace) { create_namespace(type: 'Project', parent_id: group.id) }

        before do
          create_project(
            namespace_id: group.id,
            project_namespace_id: project_namespace.id,
            archived: true,
            marked_for_deletion_at: Time.current,
            marked_for_deletion_by_user_id: user.id,
            pending_delete: true
          )
        end

        it 'sets state to deletion_in_progress (highest priority)' do
          migration.perform

          expect(namespaces.find(project_namespace.id).state).to eq(described_class::STATES[:deletion_in_progress])
        end

        it 'preserves both archived and deletion_scheduled states for full restoration chain' do
          migration.perform

          metadata = fetch_metadata(project_namespace.id)

          expect(metadata['preserved_states']).to eq({
            'schedule_deletion' => 'archived',
            'start_deletion' => 'deletion_scheduled'
          })
        end
      end
    end

    describe 'metadata backfilling for namespaces with existing state' do
      context 'when group has deletion_in_progress state but missing metadata' do
        let!(:group) { create_namespace(type: 'Group', state: described_class::STATES[:deletion_in_progress]) }

        before do
          namespace_details.find_by(namespace_id: group.id).update!(deleted_at: Time.current)
        end

        it 'does not change the state' do
          expect { migration.perform }.not_to change { namespaces.find(group.id).state }
        end

        it 'backfills preserved_states metadata' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['preserved_states']).to eq({ 'start_deletion' => 'ancestor_inherited' })
        end
      end

      context 'when group has deletion_in_progress state with archived indicator but missing preserved_states' do
        let!(:group) { create_namespace(type: 'Group', state: described_class::STATES[:deletion_in_progress]) }

        before do
          namespace_settings.create!(namespace_id: group.id, archived: true)
          namespace_details.find_by(namespace_id: group.id).update!(deleted_at: Time.current)
        end

        it 'does not change the state' do
          expect { migration.perform }.not_to change { namespaces.find(group.id).state }
        end

        it 'backfills preserved_states with archived' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['preserved_states']).to eq({ 'start_deletion' => 'archived' })
        end
      end

      context 'when group has deletion_in_progress state with deletion_scheduled indicator but missing metadata' do
        let!(:group) { create_namespace(type: 'Group', state: described_class::STATES[:deletion_in_progress]) }

        before do
          group_deletion_schedules.create!(
            group_id: group.id,
            marked_for_deletion_on: Date.current,
            user_id: user.id
          )
          namespace_details.find_by(namespace_id: group.id).update!(deleted_at: Time.current)
        end

        it 'does not change the state' do
          expect { migration.perform }.not_to change { namespaces.find(group.id).state }
        end

        it 'backfills preserved_states with deletion_scheduled' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['preserved_states']).to eq({ 'start_deletion' => 'deletion_scheduled' })
        end

        it 'backfills deletion_scheduled metadata' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['deletion_scheduled_at']).to eq(Time.current.beginning_of_day.iso8601)
          expect(metadata['deletion_scheduled_by_user_id']).to eq(user.id)
        end
      end

      context 'when group has deletion_in_progress state with all indicators but missing metadata' do
        let!(:group) { create_namespace(type: 'Group', state: described_class::STATES[:deletion_in_progress]) }

        before do
          namespace_settings.create!(namespace_id: group.id, archived: true)
          group_deletion_schedules.create!(
            group_id: group.id,
            marked_for_deletion_on: Date.current,
            user_id: user.id
          )
          namespace_details.find_by(namespace_id: group.id).update!(deleted_at: Time.current)
        end

        it 'does not change the state' do
          expect { migration.perform }.not_to change { namespaces.find(group.id).state }
        end

        it 'backfills full preservation chain' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['preserved_states']).to eq({
            'schedule_deletion' => 'archived',
            'start_deletion' => 'deletion_scheduled'
          })
        end

        it 'backfills deletion_scheduled metadata' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['deletion_scheduled_at']).to eq(Time.current.beginning_of_day.iso8601)
          expect(metadata['deletion_scheduled_by_user_id']).to eq(user.id)
        end
      end

      context 'when group has deletion_scheduled state but missing metadata' do
        let!(:group) { create_namespace(type: 'Group', state: described_class::STATES[:deletion_scheduled]) }

        before do
          group_deletion_schedules.create!(
            group_id: group.id,
            marked_for_deletion_on: Date.current,
            user_id: user.id
          )
        end

        it 'does not change the state' do
          expect { migration.perform }.not_to change { namespaces.find(group.id).state }
        end

        it 'backfills preserved_states metadata' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['preserved_states']).to eq({ 'schedule_deletion' => 'ancestor_inherited' })
        end

        it 'backfills deletion_scheduled metadata' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['deletion_scheduled_at']).to eq(Time.current.beginning_of_day.iso8601)
          expect(metadata['deletion_scheduled_by_user_id']).to eq(user.id)
        end
      end

      context 'when group has deletion_scheduled state with archived indicator but missing preserved_states' do
        let!(:group) { create_namespace(type: 'Group', state: described_class::STATES[:deletion_scheduled]) }

        before do
          namespace_settings.create!(namespace_id: group.id, archived: true)
          group_deletion_schedules.create!(
            group_id: group.id,
            marked_for_deletion_on: Date.current,
            user_id: user.id
          )
        end

        it 'does not change the state' do
          expect { migration.perform }.not_to change { namespaces.find(group.id).state }
        end

        it 'backfills preserved_states with archived' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['preserved_states']).to eq({ 'schedule_deletion' => 'archived' })
        end
      end

      context 'when project namespace has deletion_in_progress state but missing metadata' do
        let!(:group) { create_namespace(type: 'Group') }
        let!(:project_namespace) do
          create_namespace(type: 'Project', parent_id: group.id, state: described_class::STATES[:deletion_in_progress])
        end

        before do
          create_project(
            namespace_id: group.id,
            project_namespace_id: project_namespace.id,
            pending_delete: true
          )
        end

        it 'does not change the state' do
          expect { migration.perform }.not_to change { namespaces.find(project_namespace.id).state }
        end

        it 'backfills preserved_states metadata' do
          migration.perform

          metadata = fetch_metadata(project_namespace.id)

          expect(metadata['preserved_states']).to eq({ 'start_deletion' => 'ancestor_inherited' })
        end
      end

      context 'when project namespace has deletion_in_progress state with all indicators but missing metadata' do
        let!(:group) { create_namespace(type: 'Group') }
        let!(:project_namespace) do
          create_namespace(type: 'Project', parent_id: group.id, state: described_class::STATES[:deletion_in_progress])
        end

        before do
          create_project(
            namespace_id: group.id,
            project_namespace_id: project_namespace.id,
            archived: true,
            marked_for_deletion_at: Time.current,
            marked_for_deletion_by_user_id: user.id,
            pending_delete: true
          )
        end

        it 'does not change the state' do
          expect { migration.perform }.not_to change { namespaces.find(project_namespace.id).state }
        end

        it 'backfills full preservation chain' do
          migration.perform

          metadata = fetch_metadata(project_namespace.id)

          expect(metadata['preserved_states']).to eq({
            'schedule_deletion' => 'archived',
            'start_deletion' => 'deletion_scheduled'
          })
        end

        it 'backfills deletion_scheduled metadata' do
          migration.perform

          metadata = fetch_metadata(project_namespace.id)

          expect(metadata['deletion_scheduled_by_user_id']).to eq(user.id)
          expect(metadata['deletion_scheduled_at']).to be_present
        end
      end

      context 'when namespace has state and partial metadata (missing preserved_states)' do
        let!(:group) { create_namespace(type: 'Group', state: described_class::STATES[:deletion_scheduled]) }

        before do
          group_deletion_schedules.create!(
            group_id: group.id,
            marked_for_deletion_on: Date.current,
            user_id: user.id
          )
          # Simulate partial metadata - has deletion info but no preserved_states
          namespace_details.find_by(namespace_id: group.id).update!(
            state_metadata: { 'deletion_scheduled_at' => Date.current.beginning_of_day.iso8601 }
          )
        end

        it 'does not change the state' do
          expect { migration.perform }.not_to change { namespaces.find(group.id).state }
        end

        it 'backfills missing preserved_states' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['preserved_states']).to eq({ 'schedule_deletion' => 'ancestor_inherited' })
        end

        it 'preserves existing metadata' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['deletion_scheduled_at']).to eq(Time.current.beginning_of_day.iso8601)
        end
      end

      context 'when namespace has state and partial metadata (missing deletion_scheduled_at)' do
        let!(:group) { create_namespace(type: 'Group', state: described_class::STATES[:deletion_scheduled]) }

        before do
          group_deletion_schedules.create!(
            group_id: group.id,
            marked_for_deletion_on: Date.current,
            user_id: user.id
          )
          # Simulate partial metadata - has preserved_states but no deletion info
          namespace_details.find_by(namespace_id: group.id).update!(
            state_metadata: { 'preserved_states' => { 'schedule_deletion' => 'ancestor_inherited' } }
          )
        end

        it 'does not change the state' do
          expect { migration.perform }.not_to change { namespaces.find(group.id).state }
        end

        it 'backfills missing deletion_scheduled_at' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['deletion_scheduled_at']).to eq(Time.current.beginning_of_day.iso8601)
          expect(metadata['deletion_scheduled_by_user_id']).to eq(user.id)
        end

        it 'preserves existing preserved_states' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['preserved_states']).to eq({ 'schedule_deletion' => 'ancestor_inherited' })
        end
      end

      context 'when namespace has state and complete metadata' do
        let!(:group) { create_namespace(type: 'Group', state: described_class::STATES[:deletion_scheduled]) }
        let(:existing_metadata) do
          {
            'deletion_scheduled_at' => Date.current.beginning_of_day.iso8601,
            'deletion_scheduled_by_user_id' => user.id,
            'preserved_states' => { 'schedule_deletion' => 'ancestor_inherited' }
          }
        end

        before do
          group_deletion_schedules.create!(
            group_id: group.id,
            marked_for_deletion_on: Date.current,
            user_id: user.id
          )
          namespace_details.find_by(namespace_id: group.id).update!(state_metadata: existing_metadata)
        end

        it 'does not change the state' do
          expect { migration.perform }.not_to change { namespaces.find(group.id).state }
        end

        it 'does not modify existing complete metadata' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata).to eq(existing_metadata)
        end
      end
    end

    describe 'idempotency' do
      context 'when namespace already has a non-nil state' do
        let!(:group) { create_namespace(type: 'Group', state: described_class::STATES[:archived]) }

        before do
          group_deletion_schedules.create!(
            group_id: group.id,
            marked_for_deletion_on: Date.current,
            user_id: user.id
          )
        end

        it 'does not overwrite existing state' do
          migration.perform

          expect(namespaces.find(group.id).state).to eq(described_class::STATES[:archived])
        end
      end

      context 'when namespace_details already exists with state_metadata' do
        let!(:group) { create_namespace(type: 'Group') }

        before do
          namespace_details.find_by(namespace_id: group.id).update!(state_metadata: { existing_key: 'existing_value' })
          group_deletion_schedules.create!(
            group_id: group.id,
            marked_for_deletion_on: Date.current,
            user_id: user.id
          )
        end

        it 'merges new metadata with existing metadata' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['existing_key']).to eq('existing_value')
          expect(metadata['deletion_scheduled_by_user_id']).to eq(user.id)
          expect(metadata['preserved_states']).to eq({ 'schedule_deletion' => 'ancestor_inherited' })
        end
      end
    end

    describe 'batch processing' do
      let!(:archived_group) { create_namespace(type: 'Group') }
      let!(:deletion_scheduled_group) { create_namespace(type: 'Group') }
      let!(:deletion_in_progress_group) { create_namespace(type: 'Group') }
      let!(:normal_group) { create_namespace(type: 'Group') }
      let!(:parent_group) { create_namespace(type: 'Group') }
      let!(:archived_project_namespace) { create_namespace(type: 'Project', parent_id: parent_group.id) }
      let!(:deletion_scheduled_project_namespace) { create_namespace(type: 'Project', parent_id: parent_group.id) }
      let!(:pending_delete_project_namespace) { create_namespace(type: 'Project', parent_id: parent_group.id) }
      let!(:normal_project_namespace) { create_namespace(type: 'Project', parent_id: parent_group.id) }
      # Namespaces with existing state but missing metadata
      let!(:existing_state_group) do
        create_namespace(type: 'Group', state: described_class::STATES[:deletion_in_progress])
      end

      let!(:existing_state_project_namespace) do
        create_namespace(
          type: 'Project',
          parent_id: parent_group.id,
          state: described_class::STATES[:deletion_scheduled]
        )
      end

      before do
        # Group states
        namespace_settings.create!(namespace_id: archived_group.id, archived: true)
        group_deletion_schedules.create!(
          group_id: deletion_scheduled_group.id,
          marked_for_deletion_on: Date.current,
          user_id: user.id
        )
        namespace_details.find_by(namespace_id: deletion_in_progress_group.id).update!(deleted_at: Time.current)

        # Project states
        create_project(
          namespace_id: parent_group.id,
          project_namespace_id: archived_project_namespace.id,
          archived: true
        )
        create_project(
          namespace_id: parent_group.id,
          project_namespace_id: deletion_scheduled_project_namespace.id,
          marked_for_deletion_at: Time.current,
          marked_for_deletion_by_user_id: user.id
        )
        create_project(
          namespace_id: parent_group.id,
          project_namespace_id: pending_delete_project_namespace.id,
          pending_delete: true
        )
        create_project(
          namespace_id: parent_group.id,
          project_namespace_id: normal_project_namespace.id
        )

        # Existing state namespaces with indicators
        namespace_settings.create!(namespace_id: existing_state_group.id, archived: true)
        namespace_details.find_by(namespace_id: existing_state_group.id).update!(deleted_at: Time.current)

        create_project(
          namespace_id: parent_group.id,
          project_namespace_id: existing_state_project_namespace.id,
          archived: true,
          marked_for_deletion_at: Time.current,
          marked_for_deletion_by_user_id: user.id
        )
      end

      it 'processes groups and projects correctly in the same batch' do
        migration.perform

        # Groups
        expect(namespaces.find(archived_group.id).state).to eq(described_class::STATES[:archived])
        expect(namespaces.find(deletion_scheduled_group.id).state).to eq(described_class::STATES[:deletion_scheduled])
        expect(namespaces.find(deletion_in_progress_group.id).state)
          .to eq(described_class::STATES[:deletion_in_progress])
        expect(namespaces.find(normal_group.id).state).to be_nil
        expect(namespaces.find(parent_group.id).state).to be_nil

        # Projects
        expect(namespaces.find(archived_project_namespace.id).state).to eq(described_class::STATES[:archived])
        expect(namespaces.find(deletion_scheduled_project_namespace.id).state)
          .to eq(described_class::STATES[:deletion_scheduled])
        expect(namespaces.find(pending_delete_project_namespace.id).state)
          .to eq(described_class::STATES[:deletion_in_progress])
        expect(namespaces.find(normal_project_namespace.id).state).to be_nil

        # Existing state namespaces should not have state changed
        expect(namespaces.find(existing_state_group.id).state)
          .to eq(described_class::STATES[:deletion_in_progress])
        expect(namespaces.find(existing_state_project_namespace.id).state)
          .to eq(described_class::STATES[:deletion_scheduled])
      end

      it 'populates metadata correctly for both groups and projects' do
        migration.perform

        # Group metadata
        group_metadata = fetch_metadata(deletion_scheduled_group.id)
        expect(group_metadata['deletion_scheduled_by_user_id']).to eq(user.id)
        expect(group_metadata['preserved_states']).to eq({ 'schedule_deletion' => 'ancestor_inherited' })

        deletion_in_progress_group_metadata = fetch_metadata(deletion_in_progress_group.id)
        expect(deletion_in_progress_group_metadata['preserved_states'])
          .to eq({ 'start_deletion' => 'ancestor_inherited' })

        # Project metadata
        project_metadata = fetch_metadata(deletion_scheduled_project_namespace.id)
        expect(project_metadata['deletion_scheduled_by_user_id']).to eq(user.id)
        expect(project_metadata['preserved_states']).to eq({ 'schedule_deletion' => 'ancestor_inherited' })

        pending_delete_metadata = fetch_metadata(pending_delete_project_namespace.id)
        expect(pending_delete_metadata['preserved_states']).to eq({ 'start_deletion' => 'ancestor_inherited' })
      end

      it 'backfills metadata for namespaces with existing state' do
        migration.perform

        # Group with existing deletion_in_progress state and archived indicator
        existing_group_metadata = fetch_metadata(existing_state_group.id)
        expect(existing_group_metadata['preserved_states']).to eq({ 'start_deletion' => 'archived' })

        # Project with existing deletion_scheduled state and archived indicator
        existing_project_metadata = fetch_metadata(existing_state_project_namespace.id)
        expect(existing_project_metadata['preserved_states']).to eq({ 'schedule_deletion' => 'archived' })
        expect(existing_project_metadata['deletion_scheduled_by_user_id']).to eq(user.id)
      end

      it 'does not populate metadata for namespaces without state changes' do
        migration.perform

        expect(fetch_metadata(normal_group.id)).to be_empty
        expect(fetch_metadata(parent_group.id)).to be_empty
        expect(fetch_metadata(normal_project_namespace.id)).to be_empty
        expect(fetch_metadata(archived_group.id)).to be_empty
        expect(fetch_metadata(archived_project_namespace.id)).to be_empty
      end
    end
  end

  private

  def create_namespace(type:, parent_id: nil, state: nil)
    path = "namespace_#{SecureRandom.hex(4)}"
    namespace = namespaces.create!(
      name: path,
      path: path,
      type: type,
      parent_id: parent_id,
      state: state,
      organization_id: organization.id
    )
    namespace_details.insert({
      namespace_id: namespace.id,
      created_at: Time.current,
      updated_at: Time.current
    })
    namespace
  end

  def create_project(namespace_id:, project_namespace_id:, **attrs)
    path = "project_#{SecureRandom.hex(4)}"
    projects.create!(
      name: path,
      path: path,
      namespace_id: namespace_id,
      project_namespace_id: project_namespace_id,
      organization_id: organization.id,
      **attrs
    )
  end

  def fetch_metadata(namespace_id)
    details = namespace_details.find_by(namespace_id: namespace_id)
    details&.state_metadata || {}
  end
end
