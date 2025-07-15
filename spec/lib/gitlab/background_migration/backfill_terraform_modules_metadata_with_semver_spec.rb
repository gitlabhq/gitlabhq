# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillTerraformModulesMetadataWithSemver, feature_category: :package_registry do
  describe '#perform' do
    let(:projects_table) { table(:projects) }
    let(:packages_table) { table(:packages_packages) }

    let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
    let(:namespace) do
      table(:namespaces).create!(name: 'project', path: 'project', type: 'Project', organization_id: organization.id)
    end

    let(:project) do
      projects_table.create!(
        namespace_id: namespace.id,
        project_namespace_id: namespace.id,
        organization_id: organization.id
      )
    end

    let!(:package1) do
      packages_table.create!(
        project_id: project.id,
        name: 'aws/terraform-module',
        version: '1.0.0',
        package_type: described_class::TERRAFORM_MODULE_PACKAGE_TYPE
      )
    end

    let!(:package2) do
      packages_table.create!(
        project_id: project.id,
        name: 'gitlab/terraform-module',
        version: '1.55.9-rc1',
        package_type: described_class::TERRAFORM_MODULE_PACKAGE_TYPE
      )
    end

    let!(:package3) do
      packages_table.create!(
        project_id: project.id,
        name: 'goog/terraform-module',
        version: '1.25.223',
        package_type: described_class::TERRAFORM_MODULE_PACKAGE_TYPE
      ).tap do |package|
        table(:packages_terraform_module_metadata).create!(
          package_id: package.id,
          project_id: project.id,
          fields: {},
          semver_major: 1,
          semver_minor: 25,
          semver_patch: 223
        )
      end
    end

    let!(:package4) do
      packages_table.create!(
        project_id: project.id,
        name: 'xyz/terraform-module',
        version: '5.6.7-beta',
        package_type: described_class::TERRAFORM_MODULE_PACKAGE_TYPE
      ).tap do |package|
        table(:packages_terraform_module_metadata).create!(
          package_id: package.id,
          project_id: project.id,
          fields: { root: { readme: 'README' } },
          semver_major: nil,
          semver_minor: nil,
          semver_patch: nil,
          semver_prerelease: nil
        )
      end
    end

    let!(:package5) do
      packages_table.create!(
        project_id: project.id,
        name: 'abc/terraform-module',
        version: '0.0.9360753695', # patch version is bigint
        package_type: described_class::TERRAFORM_MODULE_PACKAGE_TYPE
      )
    end

    let!(:package6) do
      packages_table.create!(
        project_id: project.id,
        name: 'invalid/terraform-module',
        version: '9360753695.0.0',
        package_type: described_class::TERRAFORM_MODULE_PACKAGE_TYPE
      )
    end

    let(:migration) do
      described_class.new(
        start_id: packages_table.minimum(:project_id),
        end_id: packages_table.maximum(:project_id),
        batch_table: :packages_packages,
        batch_column: :project_id,
        sub_batch_size: 10,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      )
    end

    it 'creates or updates terraform module metadata with semver', :aggregate_failures do
      expect(Gitlab::BackgroundMigration::Logger).to receive(:warn).with(
        message: 'Invalid semver data for terraform module',
        package_id: package6.id,
        version: package6.version,
        error: 'Semver major must be less than 2147483648'
      )

      expect do
        migration.perform
      end.to change { described_class::ModuleMetadatum.count }.by(3)

      expected_metadata = {
        package1.id => { major: 1, minor: 0, patch: 0, prerelease: nil, fields: {} },
        package2.id => { major: 1, minor: 55, patch: 9, prerelease: 'rc1', fields: {} },
        package3.id => { major: 1, minor: 25, patch: 223, prerelease: nil, fields: {} },
        package4.id => { major: 5, minor: 6, patch: 7, prerelease: 'beta',
                         fields: { 'root' => { 'readme' => 'README' } } },
        package5.id => { major: 0, minor: 0, patch: 9360753695, prerelease: nil, fields: {} }
      }

      expected_metadata.each do |package_id, attrs|
        expect(described_class::ModuleMetadatum.find_by(package_id:)).to have_attributes(
          semver_major: attrs[:major],
          semver_minor: attrs[:minor],
          semver_patch: attrs[:patch],
          semver_prerelease: attrs[:prerelease],
          fields: attrs[:fields]
        )
      end
    end
  end
end
