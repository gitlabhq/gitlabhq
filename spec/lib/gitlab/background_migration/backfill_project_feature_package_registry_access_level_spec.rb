# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProjectFeaturePackageRegistryAccessLevel do
  let(:non_null_project_features) { { pages_access_level: 20 } }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_features) { table(:project_features) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  let(:namespace1) { namespaces.create!(name: 'namespace 1', path: 'namespace1', organization_id: organization.id) }
  let(:namespace2) { namespaces.create!(name: 'namespace 2', path: 'namespace2', organization_id: organization.id) }
  let(:namespace3) { namespaces.create!(name: 'namespace 3', path: 'namespace3', organization_id: organization.id) }
  let(:namespace4) { namespaces.create!(name: 'namespace 4', path: 'namespace4', organization_id: organization.id) }
  let(:namespace5) { namespaces.create!(name: 'namespace 5', path: 'namespace5', organization_id: organization.id) }
  let(:namespace6) { namespaces.create!(name: 'namespace 6', path: 'namespace6', organization_id: organization.id) }

  let(:project1) do
    projects.create!(
      namespace_id: namespace1.id,
      project_namespace_id: namespace1.id,
      organization_id: organization.id,
      packages_enabled: false
    )
  end

  let(:project2) do
    projects.create!(
      namespace_id: namespace2.id,
      project_namespace_id: namespace2.id,
      organization_id: organization.id,
      packages_enabled: nil
    )
  end

  let(:project3) do
    projects.create!(
      namespace_id: namespace3.id,
      project_namespace_id: namespace3.id,
      organization_id: organization.id,
      packages_enabled: true,
      visibility_level: Gitlab::VisibilityLevel::PRIVATE
    )
  end

  let(:project4) do
    projects.create!(
      namespace_id: namespace4.id,
      project_namespace_id: namespace4.id,
      organization_id: organization.id,
      packages_enabled: true, visibility_level: Gitlab::VisibilityLevel::INTERNAL)
  end

  let(:project5) do
    projects.create!(
      namespace_id: namespace5.id,
      project_namespace_id: namespace5.id,
      organization_id: organization.id,
      packages_enabled: true,
      visibility_level: Gitlab::VisibilityLevel::PUBLIC
    )
  end

  let(:project6) do
    projects.create!(
      namespace_id: namespace6.id,
      project_namespace_id: namespace6.id,
      organization_id: organization.id,
      packages_enabled: false
    )
  end

  let!(:project_feature1) do
    project_features.create!(
      project_id: project1.id,
      package_registry_access_level: ProjectFeature::ENABLED,
      **non_null_project_features
    )
  end

  let!(:project_feature2) do
    project_features.create!(
      project_id: project2.id,
      package_registry_access_level: ProjectFeature::ENABLED,
      **non_null_project_features
    )
  end

  let!(:project_feature3) do
    project_features.create!(
      project_id: project3.id,
      package_registry_access_level: ProjectFeature::DISABLED,
      **non_null_project_features
    )
  end

  let!(:project_feature4) do
    project_features.create!(
      project_id: project4.id,
      package_registry_access_level: ProjectFeature::DISABLED,
      **non_null_project_features
    )
  end

  let!(:project_feature5) do
    project_features.create!(
      project_id: project5.id,
      package_registry_access_level: ProjectFeature::DISABLED,
      **non_null_project_features
    )
  end

  let!(:project_feature6) do
    project_features.create!(
      project_id: project6.id,
      package_registry_access_level: ProjectFeature::ENABLED,
      **non_null_project_features
    )
  end

  subject(:perform_migration) do
    described_class.new(
      start_id: project1.id,
      end_id: project5.id,
      batch_table: :projects,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  it 'backfills project_features.package_registry_access_level', :aggregate_failures do
    perform_migration

    expect(project_feature1.reload.package_registry_access_level).to eq(ProjectFeature::DISABLED)
    expect(project_feature2.reload.package_registry_access_level).to eq(ProjectFeature::DISABLED)
    expect(project_feature3.reload.package_registry_access_level).to eq(ProjectFeature::PRIVATE)
    expect(project_feature4.reload.package_registry_access_level).to eq(ProjectFeature::ENABLED)
    expect(project_feature5.reload.package_registry_access_level).to eq(ProjectFeature::PUBLIC)
    expect(project_feature6.reload.package_registry_access_level).to eq(ProjectFeature::ENABLED)
  end
end
