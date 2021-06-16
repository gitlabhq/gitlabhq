# frozen_string_literal: true

# In order to test the CleanupGroupImportStatesWithNullUserId migration, we need
#  to first create GroupImportState with NULL user_id
#  and then run the migration to check that user_id was populated or record removed
#
# The problem is that the CleanupGroupImportStatesWithNullUserId migration comes
#  after the NOT NULL constraint has been added with a previous migration (AddNotNullConstraintToUserOnGroupImportStates)
# That means that while testing the current class we can not insert GroupImportState records with an
#  invalid user_id as constraint is blocking it from doing so
#
# To solve this problem, use SchemaVersionFinder to set schema one version prior to AddNotNullConstraintToUserOnGroupImportStates

require 'spec_helper'
require_migration!('add_not_null_constraint_to_user_on_group_import_states')
require_migration!

RSpec.describe CleanupGroupImportStatesWithNullUserId, :migration,
               schema: MigrationHelpers::SchemaVersionFinder.migration_prior(AddNotNullConstraintToUserOnGroupImportStates) do
  let(:namespaces_table) { table(:namespaces) }
  let(:users_table) { table(:users) }
  let(:group_import_states_table) { table(:group_import_states) }
  let(:members_table) { table(:members) }

  describe 'Group import states clean up' do
    context 'when user_id is present' do
      it 'does not update group_import_state record' do
        user_1 = users_table.create!(name: 'user1', email: 'user1@example.com', projects_limit: 1)
        group_1 = namespaces_table.create!(name: 'group_1', path: 'group_1', type: 'Group')
        create_member(user_id: user_1.id, type: 'GroupMember', source_type: 'Namespace', source_id: group_1.id, access_level: described_class::Group::OWNER)
        group_import_state_1 = group_import_states_table.create!(group_id: group_1.id, user_id: user_1.id, status: 0)

        expect(group_import_state_1.user_id).to eq(user_1.id)

        disable_migrations_output { migrate! }

        expect(group_import_state_1.reload.user_id).to eq(user_1.id)
      end
    end

    context 'when user_id is missing' do
      it 'updates user_id with group default owner id' do
        user_2 = users_table.create!(name: 'user2', email: 'user2@example.com', projects_limit: 1)
        group_2 = namespaces_table.create!(name: 'group_2', path: 'group_2', type: 'Group')
        create_member(user_id: user_2.id, type: 'GroupMember', source_type: 'Namespace', source_id: group_2.id, access_level: described_class::Group::OWNER)
        group_import_state_2 = group_import_states_table.create!(group_id: group_2.id, user_id: nil, status: 0)

        disable_migrations_output { migrate! }

        expect(group_import_state_2.reload.user_id).to eq(user_2.id)
      end
    end

    context 'when group does not contain any owners' do
      it 'removes group_import_state record' do
        group_3 = namespaces_table.create!(name: 'group_3', path: 'group_3', type: 'Group')
        group_import_state_3 = group_import_states_table.create!(group_id: group_3.id, user_id: nil, status: 0)

        disable_migrations_output { migrate! }

        expect { group_import_state_3.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when group has parent' do
      it 'updates user_id with parent group default owner id' do
        user = users_table.create!(name: 'user4', email: 'user4@example.com', projects_limit: 1)
        group_1 = namespaces_table.create!(name: 'group_1', path: 'group_1', type: 'Group')
        create_member(user_id: user.id, type: 'GroupMember', source_type: 'Namespace', source_id: group_1.id, access_level: described_class::Group::OWNER)
        group_2 = namespaces_table.create!(name: 'group_2', path: 'group_2', type: 'Group', parent_id: group_1.id)
        group_import_state = group_import_states_table.create!(group_id: group_2.id, user_id: nil, status: 0)

        disable_migrations_output { migrate! }

        expect(group_import_state.reload.user_id).to eq(user.id)
      end
    end

    context 'when group has owner_id' do
      it 'updates user_id with owner_id' do
        user = users_table.create!(name: 'user', email: 'user@example.com', projects_limit: 1)
        group = namespaces_table.create!(name: 'group', path: 'group', type: 'Group', owner_id: user.id)
        group_import_state = group_import_states_table.create!(group_id: group.id, user_id: nil, status: 0)

        disable_migrations_output { migrate! }

        expect(group_import_state.reload.user_id).to eq(user.id)
      end
    end
  end

  def create_member(options)
    members_table.create!(
      {
        notification_level: 0,
        ldap: false,
        override: false
      }.merge(options)
    )
  end
end
