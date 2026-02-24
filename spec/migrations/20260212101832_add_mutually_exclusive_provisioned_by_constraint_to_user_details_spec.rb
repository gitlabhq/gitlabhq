# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe AddMutuallyExclusiveProvisionedByConstraintToUserDetails, feature_category: :system_access do
  let(:constraint_name) { 'check_user_details_provisioned_by_mutually_exclusive' }
  let(:user_details) { table(:user_details) }

  describe '#up' do
    before do
      # Remove the constraint if it exists to test adding it
      connection.execute("ALTER TABLE user_details DROP CONSTRAINT IF EXISTS #{constraint_name}")
    end

    it 'adds the check constraint' do
      expect(constraint_exists?).to be_falsey

      migrate!

      expect(constraint_exists?).to be_truthy
      expect(constraint_validated?).to be_truthy
    end

    context 'when constraint is in place' do
      before do
        migrate!
      end

      it 'allows record with both columns null' do
        user = create_user

        expect { user_details.create!(user_id: user.id) }.not_to raise_error
      end

      it 'allows record with only provisioned_by_group_id set' do
        user = create_user
        group = create_group

        expect { user_details.create!(user_id: user.id, provisioned_by_group_id: group.id) }.not_to raise_error
      end

      it 'allows record with only provisioned_by_project_id set' do
        user = create_user
        project = create_project

        expect { user_details.create!(user_id: user.id, provisioned_by_project_id: project.id) }.not_to raise_error
      end

      it 'prevents record with both columns populated' do
        user = create_user
        group = create_group
        project = create_project

        expect do
          user_details.create!(user_id: user.id, provisioned_by_group_id: group.id,
            provisioned_by_project_id: project.id)
        end.to raise_error(ActiveRecord::StatementInvalid, /check_user_details_provisioned_by_mutually_exclusive/)
      end
    end
  end

  describe '#down' do
    before do
      # Ensure constraint exists before testing removal
      connection.execute("ALTER TABLE user_details DROP CONSTRAINT IF EXISTS #{constraint_name}")
      migrate!
    end

    it 'removes the check constraint' do
      expect(constraint_exists?).to be_truthy

      schema_migrate_down!

      expect(constraint_exists?).to be_falsey
    end
  end

  private

  def constraint_exists?
    connection.select_value(<<~SQL)
      SELECT true
      FROM pg_catalog.pg_constraint
      WHERE pg_constraint.conrelid = 'user_details'::regclass
        AND pg_constraint.contype = 'c'
        AND pg_constraint.conname = '#{constraint_name}'
    SQL
  end

  def constraint_validated?
    connection.select_value(<<~SQL)
      SELECT convalidated
      FROM pg_catalog.pg_constraint
      WHERE pg_constraint.conrelid = 'user_details'::regclass
        AND pg_constraint.contype = 'c'
        AND pg_constraint.conname = '#{constraint_name}'
    SQL
  end

  def connection
    ApplicationRecord.connection
  end

  def create_user
    organizations = table(:organizations)
    users = table(:users)

    org = organizations.find_by(name: 'Default') || organizations.create!(name: 'Default', path: 'default')
    users.create!(email: "user_#{SecureRandom.hex(4)}@example.com", projects_limit: 10, organization_id: org.id)
  end

  def create_group
    organizations = table(:organizations)
    namespaces = table(:namespaces)

    org = organizations.find_by(name: 'Default') || organizations.create!(name: 'Default', path: 'default')
    namespaces.create!(name: "group_#{SecureRandom.hex(4)}", path: "group_#{SecureRandom.hex(4)}", type: 'Group',
      organization_id: org.id)
  end

  def create_project
    organizations = table(:organizations)
    namespaces = table(:namespaces)
    projects = table(:projects)

    org = organizations.find_by(name: 'Default') || organizations.create!(name: 'Default', path: 'default')
    group = namespaces.create!(name: "group_#{SecureRandom.hex(4)}", path: "group_#{SecureRandom.hex(4)}",
      type: 'Group', organization_id: org.id)
    project_namespace = namespaces.create!(name: "project_#{SecureRandom.hex(4)}",
      path: "project_#{SecureRandom.hex(4)}", type: 'Project', organization_id: org.id)
    projects.create!(name: "project_#{SecureRandom.hex(4)}", path: "project_#{SecureRandom.hex(4)}",
      namespace_id: group.id, project_namespace_id: project_namespace.id, organization_id: org.id)
  end
end
