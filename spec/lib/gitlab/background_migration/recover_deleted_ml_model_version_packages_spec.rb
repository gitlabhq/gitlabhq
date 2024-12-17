# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RecoverDeletedMlModelVersionPackages, feature_category: :mlops do
  let(:ml_model_package_type) { 14 }
  let(:organizations_table) { table(:organizations) }
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:packages_table) { table(:packages_packages) }
  let(:ml_models_table) { table(:ml_models) }
  let(:ml_model_versions_table) { table(:ml_model_versions) }

  let(:organization) { organizations_table.create!(name: 'organization', path: 'organization') }
  let(:namespace) { namespaces_table.create!(name: 'namespace', path: 'namespace-1', organization_id: organization.id) }
  let(:project_namespace) do
    namespaces_table.create!(name: 'namespace', path: 'namespace-2', type: 'Project', organization_id: organization.id)
  end

  let!(:project) do
    projects_table
      .create!(
        name: 'project1',
        path: 'path1',
        namespace_id: namespace.id,
        project_namespace_id: project_namespace.id,
        organization_id: organization.id,
        visibility_level: 0
      )
  end

  let!(:ml_model_1) { ml_models_table.create!(project_id: project.id, name: 'FooModel1') }
  let!(:package_1) do
    packages_table.create!(project_id: project.id, name: 'FooModel1', version: '1.2.3',
      package_type: ml_model_package_type)
  end

  let!(:ml_model_version_1) do
    ml_model_versions_table.create!(project_id: project.id, model_id: ml_model_1.id, version: '1.2.3',
      package_id: package_1.id)
  end

  let!(:ml_model_version_2) do
    ml_model_versions_table.create!(project_id: project.id, model_id: ml_model_1.id, version: '1.2.4', package_id: nil)
  end

  let!(:ml_model_version_3) do
    ml_model_versions_table.create!(project_id: project.id, model_id: ml_model_1.id, version: '3.2.4', package_id: nil)
  end

  subject(:perform_migration) do
    described_class.new(
      start_id: ml_model_versions_table.minimum(:id),
      end_id: ml_model_versions_table.maximum(:id),
      batch_table: :ml_model_versions,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ml_model_versions_table.connection
    ).perform
  end

  it 'creates packages for ml model versions without' do
    expect { perform_migration }.to change { packages_table.count }.from(1).to(3)
  end

  it 'creates packages with correct values' do
    perform_migration

    ml_model_versions_table.all.find_each do |ml_version|
      package = packages_table.find(ml_version.package_id)
      expect(package.version).to eq(ml_version.version)
      expect(package.name).to eq('FooModel1')
    end
  end
end
