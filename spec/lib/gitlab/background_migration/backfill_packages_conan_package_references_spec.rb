# frozen_string_literal: true

require 'spec_helper'
require 'digest'

RSpec.describe Gitlab::BackgroundMigration::BackfillPackagesConanPackageReferences, feature_category: :package_registry do
  let(:tables) do
    {
      package_files: table(:packages_package_files),
      conan_package_references: table(:packages_conan_package_references),
      conan_file_metadata: table(:packages_conan_file_metadata),
      packages: table(:packages_packages),
      projects: table(:projects),
      namespaces: table(:namespaces),
      organizations: table(:organizations)
    }
  end

  let(:sha_attribute) { Gitlab::Database::ShaAttribute.new }

  let!(:organization) { tables[:organizations].create!(name: 'organization', path: 'organization') }
  let!(:namespace) { tables[:namespaces].create!(name: 'name', path: 'path', organization_id: organization.id) }
  let!(:project) do
    tables[:projects].create!(namespace_id: namespace.id, project_namespace_id: namespace.id,
      organization_id: organization.id)
  end

  let!(:namespace2) { tables[:namespaces].create!(name: 'name2', path: 'path2', organization_id: organization.id) }
  let!(:project2) do
    tables[:projects].create!(namespace_id: namespace2.id, project_namespace_id: namespace2.id,
      organization_id: organization.id)
  end

  let!(:package) { tables[:packages].create!(name: 'Test Package', project_id: project.id, package_type: 3) }
  let!(:package2) { tables[:packages].create!(name: 'Test Package 2', project_id: project2.id, package_type: 3) }

  let(:sha1_reference) { Digest::SHA1.hexdigest('some_unique_value') } # rubocop:disable Fips/SHA1 -- The conan registry is not FIPS compliant
  let!(:package_file) do
    tables[:package_files].create!(package_id: package.id, project_id: project.id,
      file_name: 'file_with_shared_reference_1', file: 'content_with_shared_reference_1')
  end

  let!(:conan_file_metadata1) do
    tables[:conan_file_metadata].create!(package_file_id: package_file.id, conan_file_type: 2,
      conan_package_reference: sha1_reference)
  end

  let!(:package_file2) do
    tables[:package_files].create!(package_id: package.id, project_id: project.id,
      file_name: 'file_with_shared_reference_2', file: 'content_with_shared_reference_2')
  end

  let!(:conan_file_metadata2) do
    tables[:conan_file_metadata].create!(package_file_id: package_file2.id, conan_file_type: 2,
      conan_package_reference: sha1_reference)
  end

  let(:sha1_reference2) { Digest::SHA1.hexdigest('another_unique_value') } # rubocop:disable Fips/SHA1 -- The conan registry is not FIPS compliant
  let!(:package_file3) do
    tables[:package_files].create!(package_id: package.id, project_id: project.id,
      file_name: 'file_with_unique_reference', file: 'content_with_unique_reference_for_package_1')
  end

  let!(:conan_file_metadata3) do
    tables[:conan_file_metadata].create!(package_file_id: package_file3.id, conan_file_type: 2,
      conan_package_reference: sha1_reference2)
  end

  let!(:package_file4) do
    tables[:package_files].create!(package_id: package2.id, project_id: project2.id,
      file_name: 'file_with_unique_reference', file: 'content_with_unique_reference_for_package_2')
  end

  let!(:conan_file_metadata4) do
    tables[:conan_file_metadata].create!(package_file_id: package_file4.id, conan_file_type: 2,
      conan_package_reference: sha1_reference2)
  end

  let!(:package_file_without_reference) do
    tables[:package_files].create!(package_id: package.id, project_id: project.id,
      file_name: 'file_without_reference', file: 'content_without_reference')
  end

  let!(:conan_file_metadata_without_reference) do
    tables[:conan_file_metadata].create!(package_file_id: package_file_without_reference.id, conan_file_type: 1,
      conan_package_reference: nil)
  end

  describe '#perform' do
    subject(:perform_migration) do
      described_class.new(
        start_id: tables[:conan_file_metadata].minimum(:id),
        end_id: tables[:conan_file_metadata].maximum(:id),
        batch_table: :packages_conan_file_metadata,
        batch_column: :id,
        sub_batch_size: 1,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      ).perform
    end

    it 'creates or finds the package reference and updates the metadata file', :aggregate_failures do
      expect { perform_migration }
        .to change { tables[:conan_package_references].count }.by(3)
        .and not_change { conan_file_metadata_without_reference.reload.package_reference_id }

      package_reference1 = tables[:conan_package_references].find_by(id: conan_file_metadata1.reload
        .package_reference_id)
      package_reference2 = tables[:conan_package_references].find_by(id: conan_file_metadata3.reload
        .package_reference_id)
      package_reference3 = tables[:conan_package_references].find_by(id: conan_file_metadata4.reload
        .package_reference_id)
      expect(conan_file_metadata1.package_reference_id).to eq(package_reference1.id)
      expect(conan_file_metadata2.reload.package_reference_id).to eq(package_reference1.id)
      expect(conan_file_metadata3.package_reference_id).to eq(package_reference2.id)
      expect(conan_file_metadata4.package_reference_id).to eq(package_reference3.id)
      # Can't specify that the reference is a sha attribute, so we need deserialize it manually
      expect(sha_attribute.deserialize(package_reference1.reference)).to eq(sha1_reference)
      expect(sha_attribute.deserialize(package_reference2.reference)).to eq(sha1_reference2)
      expect(sha_attribute.deserialize(package_reference3.reference)).to eq(sha1_reference2)
      expect(package_reference1.package_id).to eq(package.id)
      expect(package_reference2.package_id).to eq(package.id)
      expect(package_reference3.package_id).to eq(package2.id)
      expect(package_reference1.project_id).to eq(project.id)
      expect(package_reference2.project_id).to eq(project.id)
      expect(package_reference3.project_id).to eq(project2.id)
    end
  end
end
