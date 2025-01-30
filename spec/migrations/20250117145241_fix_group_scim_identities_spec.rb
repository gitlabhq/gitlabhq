# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixGroupScimIdentities, feature_category: :system_access do
  let(:migration) { described_class.new }
  let(:groups) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:scim_identities) { table(:scim_identities) }
  let(:group_scim_identities) { table(:group_scim_identities) }
  let(:organizations) { table(:organizations) }

  # Set up parent group and users
  let(:organization) { organizations.create!(path: 'org') }
  let(:group) { groups.create!(name: 'test-group', path: 'test-group', organization_id: organization.id) }
  let(:user1) { users.create!(email: 'user1@example.com', username: 'user1', projects_limit: 10) }
  let(:user2) { users.create!(email: 'user2@example.com', username: 'user2', projects_limit: 10) }
  let(:user3) { users.create!(email: 'user3@example.com', username: 'user3', projects_limit: 10) }

  # Test data setup using table helper
  let(:active_scim) { scim_identities.create!(active: true, user_id: user1.id, extern_uid: '1') }
  let(:inactive_scim) { scim_identities.create!(active: false, user_id: user2.id, extern_uid: '2') }
  let(:matching_scim) { scim_identities.create!(active: true, user_id: user3.id, extern_uid: '3') }

  let(:mismatched_active_group_scim) do
    group_scim_identities.create!(
      temp_source_id: active_scim.id,
      active: false,
      group_id: group.id,
      user_id: user1.id,
      extern_uid: '4'
    )
  end

  let(:mismatched_inactive_group_scim) do
    group_scim_identities.create!(
      temp_source_id: inactive_scim.id,
      active: true,
      group_id: group.id,
      user_id: user2.id,
      extern_uid: '5'
    )
  end

  let(:matching_group_scim) do
    group_scim_identities.create!(
      temp_source_id: matching_scim.id,
      active: true,
      group_id: group.id,
      user_id: user3.id,
      extern_uid: '6'
    )
  end

  describe '#up' do
    it 'updates mismatched group_scim_identities active status' do
      # Setup test data
      mismatched_active_group_scim
      mismatched_inactive_group_scim
      matching_group_scim

      migrate!

      expect(group_scim_identities.find(mismatched_active_group_scim.id).active).to be true
      expect(group_scim_identities.find(mismatched_inactive_group_scim.id).active).to be false
      expect(group_scim_identities.find(matching_group_scim.id).active).to be true
    end

    it 'handles orphaned records gracefully' do
      orphaned_user = users.create!(email: 'orphaned@example.com', username: 'orphaned', projects_limit: 10)
      orphaned_record = group_scim_identities.create!(
        temp_source_id: nil,
        active: true,
        group_id: group.id,
        user_id: orphaned_user.id,
        extern_uid: '1'
      )

      migrate!

      expect(group_scim_identities.find(orphaned_record.id).active).to be true
    end
  end
end
