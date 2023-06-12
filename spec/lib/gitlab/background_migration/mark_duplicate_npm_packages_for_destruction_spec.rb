# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MarkDuplicateNpmPackagesForDestruction, schema: 20230524201454, feature_category: :package_registry do # rubocop:disable Layout/LineLength
  describe '#perform' do
    let(:projects_table) { table(:projects) }
    let(:namespaces_table) { table(:namespaces) }
    let(:packages_table) { table(:packages_packages) }

    let!(:namespace) do
      namespaces_table.create!(name: 'project', path: 'project', type: 'Project')
    end

    let!(:project) do
      projects_table.create!(
        namespace_id: namespace.id,
        name: 'project',
        path: 'project',
        project_namespace_id: namespace.id
      )
    end

    let!(:package_1) do
      packages_table.create!(
        project_id: project.id,
        name: 'test1',
        version: '1.0.0',
        package_type: described_class::NPM_PACKAGE_TYPE
      )
    end

    let!(:package_2) do
      packages_table.create!(
        project_id: project.id,
        name: 'test2',
        version: '1.0.0',
        package_type: described_class::NPM_PACKAGE_TYPE
      )
    end

    let!(:package_3) do
      packages_table.create!(
        project_id: project.id,
        name: 'test3',
        version: '1.0.0',
        package_type: described_class::NPM_PACKAGE_TYPE
      )
    end

    let(:migration) do
      described_class.new(
        start_id: projects_table.minimum(:id),
        end_id: projects_table.maximum(:id),
        batch_table: :packages_packages,
        batch_column: :project_id,
        sub_batch_size: 10,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      )
    end

    before do
      # create a duplicated package without triggering model validation errors
      package_2.update_column(:name, package_1.name)
      package_3.update_column(:name, package_1.name)
    end

    it 'marks duplicate npm packages for destruction', :aggregate_failures do
      packages_marked_for_destruction = described_class::Package
                                        .where(status: described_class::PENDING_DESTRUCTION_STATUS)

      expect { migration.perform }
        .to change { packages_marked_for_destruction.count }.from(0).to(2)
      expect(package_3.reload.status).not_to eq(described_class::PENDING_DESTRUCTION_STATUS)
    end
  end
end
