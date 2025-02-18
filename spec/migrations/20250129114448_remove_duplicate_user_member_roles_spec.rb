# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveDuplicateUserMemberRoles, feature_category: :system_access do
  let!(:time_now) { Time.zone.now }

  let!(:users) { table(:users) }
  let!(:member_roles) { table(:member_roles) }
  let!(:user_member_roles) { table(:user_member_roles) }

  let(:user_data) do
    {
      name: 'test-user',
      encrypted_password: 'password',
      projects_limit: 5,
      admin: false,
      created_at: time_now,
      updated_at: time_now,
      state: 'active'
    }
  end

  let!(:user_1) { users.create!(user_data.merge(email: 'test_1@example.com', username: 'test-user')) }
  let!(:user_2) { users.create!(user_data.merge(email: 'test_2@example.com', username: 'test-user')) }
  let!(:user_3) { users.create!(user_data.merge(email: 'test_3@example.com', username: 'test-user')) }

  let!(:member_role_1) do
    member_roles.create!(
      name: 'admin 1',
      created_at: time_now,
      updated_at: time_now,
      permissions: { read_admin_dashboard: true }.to_json
    )
  end

  let!(:member_role_2) do
    member_roles.create!(
      name: 'admin 2',
      created_at: time_now,
      updated_at: time_now,
      permissions: { read_admin_dashboard: true }.to_json
    )
  end

  describe '#up' do
    context 'when user has duplicate roles' do
      let!(:user_1_role_1) do
        user_member_roles.create!(
          user_id: user_1.id,
          member_role_id: member_role_1.id,
          created_at: time_now,
          updated_at: time_now
        )
      end

      let!(:user_1_role_1_1) do
        user_member_roles.create!(
          user_id: user_1.id,
          member_role_id: member_role_1.id,
          created_at: time_now,
          updated_at: time_now
        )
      end

      let!(:user_1_role_2) do
        user_member_roles.create!(
          user_id: user_1.id,
          member_role_id: member_role_2.id,
          created_at: time_now,
          updated_at: time_now
        )
      end

      let!(:user_2_role_1) do
        user_member_roles.create!(
          user_id: user_2.id,
          member_role_id: member_role_1.id,
          created_at: time_now,
          updated_at: time_now
        )
      end

      let!(:user_2_role_2) do
        user_member_roles.create!(
          user_id: user_2.id,
          member_role_id: member_role_2.id,
          created_at: time_now,
          updated_at: time_now
        )
      end

      let!(:user_3_role_2) do
        user_member_roles.create!(
          user_id: user_3.id,
          member_role_id: member_role_2.id,
          created_at: time_now,
          updated_at: time_now
        )
      end

      it 'removes duplicate roles keeping only the one with minimum id' do
        expect(user_member_roles.where(user_id: user_1.id).count).to eq(3)
        expect(user_member_roles.where(user_id: user_2.id).count).to eq(2)
        expect(user_member_roles.where(user_id: user_3.id).count).to eq(1)

        schema_migrate_up!

        expect(user_member_roles.where(user_id: user_1.id).count).to eq(1)
        expect(user_member_roles.where(user_id: user_2.id).count).to eq(1)
        expect(user_member_roles.where(user_id: user_3.id).count).to eq(1)
      end
    end
  end
end
