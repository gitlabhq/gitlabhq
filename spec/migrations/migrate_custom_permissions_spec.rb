# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateCustomPermissions, feature_category: :permissions do
  let(:member_roles) { table(:member_roles) }
  let!(:member_role_a) { member_roles.create!(name: 'a', base_access_level: 10, read_code: true) }
  let!(:member_role_b) { member_roles.create!(name: 'b', base_access_level: 10, archive_project: true) }
  let(:boolean_permissions_where) { { read_code: true } }
  let(:jsonb_permissions_where) { "member_roles.permissions @> ('{\"read_code\":true}')::jsonb" }

  it 'correctly migrates up and down' do
    disable_migrations_output do
      reversible_migration do |migration|
        migration.before -> {
          expect(member_roles.where(boolean_permissions_where).pluck(:id)).to contain_exactly(member_role_a.id)
        }

        migration.after -> {
          expect(member_roles.where(jsonb_permissions_where).pluck(:id)).to contain_exactly(member_role_a.id)
        }
      end
    end
  end
end
