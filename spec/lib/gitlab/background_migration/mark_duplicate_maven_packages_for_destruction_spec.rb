# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MarkDuplicateMavenPackagesForDestruction, feature_category: :package_registry do
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

    let!(:package_1) do
      packages_table.create!(
        project_id: project.id,
        name: 'foo/bar/mypkg1',
        version: '1.0.0',
        package_type: described_class::MAVEN_PACKAGE_TYPE
      )
    end

    let!(:package_2) do
      packages_table.create!(
        project_id: project.id,
        name: 'foo/bar/mypkg2',
        version: '1.0.0',
        package_type: described_class::MAVEN_PACKAGE_TYPE
      )
    end

    let!(:package_3) do
      packages_table.create!(
        project_id: project.id,
        name: 'foo/bar/mypkg3',
        version: '1.0.0',
        package_type: described_class::MAVEN_PACKAGE_TYPE
      )
    end

    let!(:package_4) do
      packages_table.create!(
        project_id: project.id,
        name: 'foo/bar/mypkg4',
        package_type: described_class::MAVEN_PACKAGE_TYPE
      )
    end

    let!(:package_5) do
      packages_table.create!(
        project_id: project.id,
        name: 'foo/bar/mypkg5',
        package_type: described_class::MAVEN_PACKAGE_TYPE
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

    before do
      packages_table.update_all(name: package_1.name)
    end

    it 'marks duplicate maven packages for destruction', :aggregate_failures do
      packages_marked_for_destruction = packages_table.where(status: described_class::PENDING_DESTRUCTION_STATUS)

      expect { migration.perform }.to change { packages_marked_for_destruction.count }.from(0).to(3)
      expect(package_3.reload.status).not_to eq(described_class::PENDING_DESTRUCTION_STATUS)
      expect(package_5.reload.status).not_to eq(described_class::PENDING_DESTRUCTION_STATUS)
    end
  end
end
