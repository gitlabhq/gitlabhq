# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixNamespaceState, feature_category: :groups_and_projects do
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

  let!(:group) { create_namespace(type: 'Group') }
  let!(:project_namespace) { create_namespace(type: 'Project', parent_id: group.id) }

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
        before do
          namespace_settings.create!(namespace_id: group.id, archived: true)
        end

        it 'sets state to archived' do
          migration.perform

          expect(namespaces.find(group.id).state).to eq(described_class::STATES[:archived])
        end

        it 'does not populate state_metadata' do
          migration.perform

          expect(fetch_metadata(group.id)).to be_empty
        end
      end

      context 'when project namespace is archived via projects.archived' do
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

        it 'populates deletion info' do
          migration.perform

          details = namespace_details.find_by(namespace_id: group.id)
          metadata = details.state_metadata

          expect(details.deletion_scheduled_at).to eq(scheduled_date.beginning_of_day)
          expect(metadata['deletion_scheduled_by_user_id']).to eq(user.id)
        end

        it 'preserves ancestor_inherited as previous state' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata['preserved_states']).to eq({ 'schedule_deletion' => 'ancestor_inherited' })
        end
      end

      context 'when project namespace has marked_for_deletion_at', :freeze_time do
        let(:deletion_time) { Time.current.beginning_of_day }

        before do
          create_project(
            namespace_id: group.id,
            project_namespace_id: project_namespace.id,
            marked_for_deletion_at: deletion_time,
            marked_for_deletion_by_user_id: user.id
          )
        end

        it 'sets state to deletion_scheduled' do
          migration.perform

          expect(namespaces.find(project_namespace.id).state).to eq(described_class::STATES[:deletion_scheduled])
        end

        it 'populates deletion info' do
          migration.perform

          details = namespace_details.find_by(namespace_id: project_namespace.id)
          metadata = details.state_metadata

          expect(details.deletion_scheduled_at).to eq(deletion_time)
          expect(metadata['deletion_scheduled_by_user_id']).to eq(user.id)
        end

        it 'preserves ancestor_inherited as previous state' do
          migration.perform

          metadata = fetch_metadata(project_namespace.id)

          expect(metadata['preserved_states']).to eq({ 'schedule_deletion' => 'ancestor_inherited' })
        end
      end
    end

    describe 'state priority and preservation' do
      context 'when group is archived AND has deletion_scheduled' do
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

      context 'when project namespace is archived AND has marked_for_deletion_at' do
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
    end

    describe 'fixing drifted state' do
      context 'when state is 0 (ancestor_inherited) but group is archived' do
        before do
          namespace_settings.create!(namespace_id: group.id, archived: true)
        end

        it 'fixes state to archived' do
          migration.perform

          expect(namespaces.find(group.id).state).to eq(described_class::STATES[:archived])
        end
      end

      context 'when state is 0 (ancestor_inherited) but group has deletion_scheduled' do
        before do
          group_deletion_schedules.create!(
            group_id: group.id,
            marked_for_deletion_on: Date.current,
            user_id: user.id
          )
        end

        it 'fixes state to deletion_scheduled' do
          migration.perform

          expect(namespaces.find(group.id).state).to eq(described_class::STATES[:deletion_scheduled])
        end

        it 'populates deletion info and state_metadata' do
          migration.perform

          details = namespace_details.find_by(namespace_id: group.id)
          metadata = details.state_metadata

          expect(details.deletion_scheduled_at).to be_present
          expect(metadata['deletion_scheduled_by_user_id']).to eq(user.id)
          expect(metadata['preserved_states']).to eq({ 'schedule_deletion' => 'ancestor_inherited' })
        end
      end

      context 'when state is NULL but group is archived' do
        before do
          without_not_null_constraint do
            group.update!(state: nil)
          end
          namespace_settings.create!(namespace_id: group.id, archived: true)
        end

        it 'fixes state to archived' do
          migration.perform

          expect(namespaces.find(group.id).state).to eq(described_class::STATES[:archived])
        end
      end

      context 'when state does not match attributes (state is archived but should be deletion_scheduled)' do
        before do
          group.update!(state: described_class::STATES[:archived])
          group_deletion_schedules.create!(
            group_id: group.id,
            marked_for_deletion_on: Date.current,
            user_id: user.id
          )
        end

        it 'fixes state to deletion_scheduled' do
          migration.perform

          expect(namespaces.find(group.id).state).to eq(described_class::STATES[:deletion_scheduled])
        end

        it 'populates deletion info and state_metadata' do
          migration.perform

          details = namespace_details.find_by(namespace_id: group.id)
          metadata = details.state_metadata

          expect(details.deletion_scheduled_at).to be_present
          expect(metadata['deletion_scheduled_by_user_id']).to eq(user.id)
          expect(metadata['preserved_states']).to eq({ 'schedule_deletion' => 'ancestor_inherited' })
        end
      end

      context 'when state does not match attributes (state is deletion_scheduled but no attributes match)' do
        before do
          group.update!(state: described_class::STATES[:deletion_scheduled])
          namespace_details.find_by(namespace_id: group.id).update!(
            state_metadata: { 'preserved_states' => { 'schedule_deletion' => 'ancestor_inherited' } },
            deletion_scheduled_at: Date.current.beginning_of_day
          )
        end

        it 'fixes state to ancestor_inherited' do
          migration.perform

          expect(namespaces.find(group.id).state).to eq(described_class::STATES[:ancestor_inherited])
        end

        it 'clears stale state_metadata' do
          migration.perform

          expect(fetch_metadata(group.id)).to be_empty
        end

        it 'clears stale deletion_scheduled_at' do
          migration.perform

          details = namespace_details.find_by(namespace_id: group.id)

          expect(details.deletion_scheduled_at).to be_nil
        end
      end

      context 'when state does not match attributes (state is deletion_scheduled but should be archived)' do
        before do
          group.update!(state: described_class::STATES[:deletion_scheduled])
          namespace_settings.create!(namespace_id: group.id, archived: true)
          namespace_details.find_by(namespace_id: group.id).update!(
            state_metadata: {
              'deletion_scheduled_by_user_id' => user.id,
              'preserved_states' => { 'schedule_deletion' => 'ancestor_inherited' }
            },
            deletion_scheduled_at: Date.current.beginning_of_day
          )
        end

        it 'fixes state to archived' do
          migration.perform

          expect(namespaces.find(group.id).state).to eq(described_class::STATES[:archived])
        end

        it 'clears stale deletion metadata from state_metadata' do
          migration.perform

          metadata = fetch_metadata(group.id)

          expect(metadata).not_to have_key('deletion_scheduled_by_user_id')
          expect(metadata).not_to have_key('preserved_states')
        end

        it 'clears stale deletion_scheduled_at' do
          migration.perform

          details = namespace_details.find_by(namespace_id: group.id)

          expect(details.deletion_scheduled_at).to be_nil
        end
      end

      context 'when state does not match attributes (state is archived but no attributes match)' do
        before do
          group.update!(state: described_class::STATES[:archived])
          namespace_details.find_by(namespace_id: group.id).update!(
            state_metadata: { 'some_stale_key' => 'some_value' }
          )
        end

        it 'fixes state to ancestor_inherited' do
          migration.perform

          expect(namespaces.find(group.id).state).to eq(described_class::STATES[:ancestor_inherited])
        end

        it 'clears stale state_metadata' do
          migration.perform

          expect(fetch_metadata(group.id)).to be_empty
        end
      end

      context 'when project namespace state is deletion_scheduled but no attributes match' do
        before do
          project_namespace.update!(state: described_class::STATES[:deletion_scheduled])
          create_project(
            namespace_id: group.id,
            project_namespace_id: project_namespace.id
          )
          namespace_details.find_by(namespace_id: project_namespace.id).update!(
            state_metadata: { 'preserved_states' => { 'schedule_deletion' => 'ancestor_inherited' } },
            deletion_scheduled_at: Date.current.beginning_of_day
          )
        end

        it 'fixes state to ancestor_inherited' do
          migration.perform

          expect(namespaces.find(project_namespace.id).state).to eq(described_class::STATES[:ancestor_inherited])
        end

        it 'clears stale state_metadata' do
          migration.perform

          expect(fetch_metadata(project_namespace.id)).to be_empty
        end

        it 'clears stale deletion_scheduled_at' do
          migration.perform

          details = namespace_details.find_by(namespace_id: project_namespace.id)

          expect(details.deletion_scheduled_at).to be_nil
        end
      end

      context 'when project namespace state is deletion_scheduled but should be archived' do
        before do
          project_namespace.update!(state: described_class::STATES[:deletion_scheduled])
          create_project(
            namespace_id: group.id,
            project_namespace_id: project_namespace.id,
            archived: true
          )
          namespace_details.find_by(namespace_id: project_namespace.id).update!(
            state_metadata: {
              'deletion_scheduled_by_user_id' => user.id,
              'preserved_states' => { 'schedule_deletion' => 'ancestor_inherited' }
            },
            deletion_scheduled_at: Date.current.beginning_of_day
          )
        end

        it 'fixes state to archived' do
          migration.perform

          expect(namespaces.find(project_namespace.id).state).to eq(described_class::STATES[:archived])
        end

        it 'clears stale deletion metadata from state_metadata' do
          migration.perform

          metadata = fetch_metadata(project_namespace.id)

          expect(metadata).not_to have_key('deletion_scheduled_by_user_id')
          expect(metadata).not_to have_key('preserved_states')
        end

        it 'clears stale deletion_scheduled_at' do
          migration.perform

          details = namespace_details.find_by(namespace_id: project_namespace.id)

          expect(details.deletion_scheduled_at).to be_nil
        end
      end

      context 'when project namespace state is archived but no attributes match' do
        before do
          project_namespace.update!(state: described_class::STATES[:archived])
          create_project(
            namespace_id: group.id,
            project_namespace_id: project_namespace.id
          )
          namespace_details.find_by(namespace_id: project_namespace.id).update!(
            state_metadata: { 'some_stale_key' => 'some_value' }
          )
        end

        it 'fixes state to ancestor_inherited' do
          migration.perform

          expect(namespaces.find(project_namespace.id).state).to eq(described_class::STATES[:ancestor_inherited])
        end

        it 'clears stale state_metadata' do
          migration.perform

          expect(fetch_metadata(project_namespace.id)).to be_empty
        end
      end

      context 'when project namespace state is archived but should be deletion_scheduled' do
        before do
          project_namespace.update!(state: described_class::STATES[:archived])
          create_project(
            namespace_id: group.id,
            project_namespace_id: project_namespace.id,
            marked_for_deletion_at: Time.current,
            marked_for_deletion_by_user_id: user.id
          )
        end

        it 'fixes state to deletion_scheduled' do
          migration.perform

          expect(namespaces.find(project_namespace.id).state).to eq(described_class::STATES[:deletion_scheduled])
        end

        it 'populates deletion info and state_metadata' do
          migration.perform

          details = namespace_details.find_by(namespace_id: project_namespace.id)
          metadata = details.state_metadata

          expect(details.deletion_scheduled_at).to be_present
          expect(metadata['deletion_scheduled_by_user_id']).to eq(user.id)
          expect(metadata['preserved_states']).to eq({ 'schedule_deletion' => 'ancestor_inherited' })
        end
      end

      context 'when namespace has state deletion_in_progress (already managed by state machine)' do
        before do
          group.update!(state: described_class::STATES[:deletion_in_progress])
          namespace_settings.create!(namespace_id: group.id, archived: true)
        end

        it 'does not change the state' do
          expect { migration.perform }.not_to change { namespaces.find(group.id).state }
        end
      end

      context 'when project namespace has state deletion_in_progress (already managed by state machine)' do
        before do
          project_namespace.update!(state: described_class::STATES[:deletion_in_progress])
          create_project(
            namespace_id: group.id,
            project_namespace_id: project_namespace.id,
            archived: true
          )
        end

        it 'does not change the state' do
          expect { migration.perform }.not_to change { namespaces.find(project_namespace.id).state }
        end
      end
    end

    describe 'metadata backfilling for namespaces with existing correct state' do
      let!(:group) { create_namespace(type: 'Group', state: described_class::STATES[:deletion_scheduled]) }

      context 'when group has correct deletion_scheduled state but missing metadata' do
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

          details = namespace_details.find_by(namespace_id: group.id)

          expect(details.deletion_scheduled_at).to eq(Time.current.beginning_of_day)
          expect(details.state_metadata['deletion_scheduled_by_user_id']).to eq(user.id)
        end
      end

      context 'when namespace has state and partial metadata (missing preserved_states)' do
        before do
          group_deletion_schedules.create!(
            group_id: group.id,
            marked_for_deletion_on: Date.current,
            user_id: user.id
          )
          namespace_details.find_by(namespace_id: group.id).update!(
            deletion_scheduled_at: Date.current.beginning_of_day
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

        it 'preserves existing deletion_scheduled_at' do
          migration.perform

          details = namespace_details.find_by(namespace_id: group.id)

          expect(details.deletion_scheduled_at).to eq(Date.current.beginning_of_day)
        end
      end
    end

    describe 'idempotency' do
      context 'when namespace_details already exists with state_metadata' do
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

      context 'when run multiple times' do
        let!(:group) { create_namespace(type: 'Group', state: 0) }

        before do
          namespace_settings.create!(namespace_id: group.id, archived: true)
        end

        it 'produces the same result' do
          migration.perform
          expect(namespaces.find(group.id).state).to eq(described_class::STATES[:archived])

          migration.perform
          expect(namespaces.find(group.id).state).to eq(described_class::STATES[:archived])
        end
      end
    end

    describe 'batch processing' do
      let!(:archived_group) { create_namespace(type: 'Group') }
      let!(:deletion_scheduled_group) { create_namespace(type: 'Group') }
      let!(:normal_group) { create_namespace(type: 'Group') }
      let!(:parent_group) { create_namespace(type: 'Group') }
      let!(:archived_project_namespace) { create_namespace(type: 'Project', parent_id: parent_group.id) }
      let!(:deletion_scheduled_project_namespace) { create_namespace(type: 'Project', parent_id: parent_group.id) }
      let!(:normal_project_namespace) { create_namespace(type: 'Project', parent_id: parent_group.id) }
      let!(:drifted_group) { create_namespace(type: 'Group', state: 0) }
      let!(:drifted_project_namespace) do
        create_namespace(type: 'Project', parent_id: parent_group.id, state: 0)
      end

      before do
        namespace_settings.create!(namespace_id: archived_group.id, archived: true)
        group_deletion_schedules.create!(
          group_id: deletion_scheduled_group.id,
          marked_for_deletion_on: Date.current,
          user_id: user.id
        )

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
          project_namespace_id: normal_project_namespace.id
        )

        namespace_settings.create!(namespace_id: drifted_group.id, archived: true)
        create_project(
          namespace_id: parent_group.id,
          project_namespace_id: drifted_project_namespace.id,
          marked_for_deletion_at: Time.current,
          marked_for_deletion_by_user_id: user.id
        )
      end

      it 'processes groups and projects correctly in the same batch' do
        migration.perform

        expect(namespaces.find(archived_group.id).state).to eq(described_class::STATES[:archived])
        expect(namespaces.find(deletion_scheduled_group.id).state).to eq(described_class::STATES[:deletion_scheduled])
        expect(namespaces.find(normal_group.id).state).to eq(described_class::STATES[:ancestor_inherited])
        expect(namespaces.find(parent_group.id).state).to eq(described_class::STATES[:ancestor_inherited])

        expect(namespaces.find(archived_project_namespace.id).state).to eq(described_class::STATES[:archived])
        expect(namespaces.find(deletion_scheduled_project_namespace.id).state)
          .to eq(described_class::STATES[:deletion_scheduled])
        expect(namespaces.find(normal_project_namespace.id).state).to eq(described_class::STATES[:ancestor_inherited])
      end

      it 'fixes drifted namespaces' do
        migration.perform

        expect(namespaces.find(drifted_group.id).state).to eq(described_class::STATES[:archived])
        expect(namespaces.find(drifted_project_namespace.id).state)
          .to eq(described_class::STATES[:deletion_scheduled])
      end

      it 'populates metadata correctly for both groups and projects' do
        migration.perform

        group_metadata = fetch_metadata(deletion_scheduled_group.id)
        expect(group_metadata['deletion_scheduled_by_user_id']).to eq(user.id)
        expect(group_metadata['preserved_states']).to eq({ 'schedule_deletion' => 'ancestor_inherited' })

        project_metadata = fetch_metadata(deletion_scheduled_project_namespace.id)
        expect(project_metadata['deletion_scheduled_by_user_id']).to eq(user.id)
        expect(project_metadata['preserved_states']).to eq({ 'schedule_deletion' => 'ancestor_inherited' })
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

  def create_namespace(type:, parent_id: nil, state: 0)
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

  def without_not_null_constraint
    connection = ApplicationRecord.connection
    connection.execute('ALTER TABLE namespaces DROP CONSTRAINT IF EXISTS check_9d490f2140')

    yield
  ensure
    connection.execute(
      'ALTER TABLE namespaces ADD CONSTRAINT check_9d490f2140 CHECK (state IS NOT NULL) NOT VALID'
    )
  end
end
