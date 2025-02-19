# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemovePackageProtectionRulesOnDownMigration, migration: :gitlab_main, feature_category: :package_registry do
  let(:migration) { described_class.new }

  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) do
    table(:namespaces).create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id)
  end

  let(:project) do
    table(:projects).create!(namespace_id: namespace.id, project_namespace_id: namespace.id,
      organization_id: organization.id)
  end

  let(:packages_protection_rules) { table(:packages_protection_rules) }

  describe '#down' do
    before do
      packages_protection_rules.create!(project_id: project.id, package_type: 2,
        package_name_pattern: '@group/package-1', minimum_access_level_for_push: nil)

      packages_protection_rules.create!(project_id: project.id, package_type: 2,
        package_name_pattern: '@group/package-2', minimum_access_level_for_push: nil)

      packages_protection_rules.create!(project_id: project.id, package_type: 2,
        package_name_pattern: '@group/package-3', minimum_access_level_for_push: 30)

      packages_protection_rules.create!(project_id: project.id, package_type: 2,
        package_name_pattern: '@group/package-4', minimum_access_level_for_push: 40)
    end

    it 'removes records with nil minimum_access_level_for_push' do
      expect { migration.down }
        .to change { packages_protection_rules.count }.from(4).to(2)
        .and change { packages_protection_rules.where(minimum_access_level_for_push: nil).count }.from(2).to(0)
        .and not_change { packages_protection_rules.where.not(minimum_access_level_for_push: nil).count }
    end

    it 'preserves records with non-nil minimum_access_level_for_push' do
      migration.down

      expect(packages_protection_rules.where(
        package_name_pattern: '@group/package-3',
        minimum_access_level_for_push: 30
      )).to exist
      expect(packages_protection_rules.where(
        package_name_pattern: '@group/package-4',
        minimum_access_level_for_push: 40
      )).to exist
    end
  end
end
