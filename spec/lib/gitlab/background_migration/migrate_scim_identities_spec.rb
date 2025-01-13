# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateScimIdentities, feature_category: :system_access do
  let(:migration_attrs) do
    {
      start_id: identities.minimum(:id),
      end_id: identities.maximum(:id),
      batch_table: :scim_identities,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  let!(:migration) { described_class.new(**migration_attrs) }

  let(:connection) { migration.connection }
  let(:organizations) { table(:organizations) }
  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:identities) { table(:scim_identities) }
  let(:group_scim_identities) { table(:group_scim_identities) }

  let(:group) do
    namespaces.create!(name: 'test-group', path: 'test-group', type: 'Group', organization_id: organization.id)
  end

  let(:user) { users.create!(email: 'test@example.com', username: 'test_user', projects_limit: 0) }

  let(:identity_with_group) do
    identities.create!(
      extern_uid: 'test-uid-1',
      user_id: user.id,
      group_id: group.id,
      created_at: 2.days.ago,
      updated_at: 1.day.ago
    )
  end

  let(:identity_without_group) do
    identities.create!(
      extern_uid: 'test-uid-2',
      user_id: user.id,
      group_id: nil,
      created_at: 2.days.ago,
      updated_at: 1.day.ago
    )
  end

  describe '#perform' do
    it 'migrates only identities with group_id' do
      identity_with_group # Reference to ensure creation
      identity_without_group # Reference to ensure creation

      expect { migration.perform }.to change { group_scim_identities.count }.by(1)

      migrated_identity = group_scim_identities.first
      expect(migrated_identity).to have_attributes(
        temp_source_id: identity_with_group.id,
        group_id: group.id,
        user_id: user.id,
        extern_uid: identity_with_group.extern_uid
      )
    end

    it 'does not migrate identities without group_id' do
      identity_without_group # Reference to ensure creation

      migration.perform

      expect(group_scim_identities.where(temp_source_id: identity_without_group.id)).to be_empty
    end

    it 'handles duplicate records gracefully' do
      # Create a duplicate record in the target table
      group_scim_identities.create!(
        temp_source_id: identity_with_group.id,
        group_id: group.id,
        user_id: user.id,
        extern_uid: identity_with_group.extern_uid,
        created_at: identity_with_group.created_at,
        updated_at: identity_with_group.updated_at
      )

      # Should not raise an error due to ON CONFLICT DO NOTHING
      expect { migration.perform }.not_to raise_error
    end

    it 'preserves timestamps' do
      identity_with_group # Reference to ensure creation

      migration.perform

      migrated_identity = group_scim_identities.first
      expect(migrated_identity.created_at).to be_within(1.second).of(identity_with_group.created_at)
      expect(migrated_identity.updated_at).to be_within(1.second).of(identity_with_group.updated_at)
    end
  end
end
