# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillMemberRolesWithAllShardingColumnsSet, migration: :gitlab_main_org, feature_category: :groups_and_projects do
  let(:member_roles) { table(:member_roles) }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace', organization_id: organization.id) }

  describe '#up' do
    before do
      # Temporarily remove the multi-column not null constraint to create test data
      # The constraint check_ae96d7c575 ensures exactly one of namespace_id or organization_id is set
      execute_sql("ALTER TABLE member_roles DROP CONSTRAINT IF EXISTS check_ae96d7c575")

      # Create member roles with both sharding columns set
      member_roles.create!(
        name: 'role 1',
        namespace_id: namespace.id,
        organization_id: organization.id,
        base_access_level: 30
      )
      member_roles.create!(
        name: 'role 2',
        namespace_id: namespace.id,
        organization_id: organization.id,
        base_access_level: 40
      )
      # Create member role with only namespace_id set (should not be affected)
      member_roles.create!(
        name: 'role 3',
        namespace_id: namespace.id,
        organization_id: nil,
        base_access_level: 30
      )
      # Create member role with only organization_id set (should not be affected)
      member_roles.create!(
        name: 'role 4',
        namespace_id: nil,
        organization_id: organization.id,
        base_access_level: 30
      )

      # Re-apply the constraint as NOT VALID to mirror the state in the MR
      execute_sql(<<~SQL)
        ALTER TABLE member_roles ADD CONSTRAINT check_ae96d7c575
          CHECK ((num_nonnulls(namespace_id, organization_id) = 1)) NOT VALID
      SQL
    end

    it 'clears organization_id for records with both sharding columns set' do
      expect do
        migrate!
      end.to change {
        member_roles.where.not(organization_id: nil).where.not(namespace_id: nil).count
      }.from(2).to(0)
    end

    it 'preserves namespace_id for records with both sharding columns set' do
      migrate!

      records_with_both_set = member_roles.where.not(namespace_id: nil).where(organization_id: nil)
      expect(records_with_both_set.count).to eq(3)
      expect(records_with_both_set.pluck(:namespace_id)).to all(eq(namespace.id))
    end

    it 'does not affect records with only namespace_id set' do
      migrate!

      record = member_roles.where(namespace_id: namespace.id, organization_id: nil).first
      expect(record).to be_present
    end

    it 'does not affect records with only organization_id set' do
      migrate!

      record = member_roles.where(namespace_id: nil, organization_id: organization.id).first
      expect(record).to be_present
    end
  end

  private

  def execute_sql(sql)
    ActiveRecord::Base.connection.execute(sql)
  end
end
