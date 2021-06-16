# frozen_string_literal: true

require 'spec_helper'
require_migration!('cleanup_move_container_registry_enabled_to_project_feature')

RSpec.describe CleanupMoveContainerRegistryEnabledToProjectFeature, :migration do
  let(:namespace) { table(:namespaces).create!(name: 'gitlab', path: 'gitlab-org') }
  let(:non_null_project_features) { { pages_access_level: 20 } }
  let(:bg_class_name) { 'MoveContainerRegistryEnabledToProjectFeature' }

  let!(:project1) { table(:projects).create!(namespace_id: namespace.id, name: 'project 1', container_registry_enabled: true) }
  let!(:project2) { table(:projects).create!(namespace_id: namespace.id, name: 'project 2', container_registry_enabled: false) }
  let!(:project3) { table(:projects).create!(namespace_id: namespace.id, name: 'project 3', container_registry_enabled: nil) }

  let!(:project4) { table(:projects).create!(namespace_id: namespace.id, name: 'project 4', container_registry_enabled: true) }
  let!(:project5) { table(:projects).create!(namespace_id: namespace.id, name: 'project 5', container_registry_enabled: false) }
  let!(:project6) { table(:projects).create!(namespace_id: namespace.id, name: 'project 6', container_registry_enabled: nil) }

  let!(:project_feature1) { table(:project_features).create!(project_id: project1.id, container_registry_access_level: 20, **non_null_project_features) }
  let!(:project_feature2) { table(:project_features).create!(project_id: project2.id, container_registry_access_level: 0, **non_null_project_features) }
  let!(:project_feature3) { table(:project_features).create!(project_id: project3.id, container_registry_access_level: 0, **non_null_project_features) }

  let!(:project_feature4) { table(:project_features).create!(project_id: project4.id, container_registry_access_level: 0, **non_null_project_features) }
  let!(:project_feature5) { table(:project_features).create!(project_id: project5.id, container_registry_access_level: 20, **non_null_project_features) }
  let!(:project_feature6) { table(:project_features).create!(project_id: project6.id, container_registry_access_level: 20, **non_null_project_features) }

  let!(:background_migration_job1) { table(:background_migration_jobs).create!(class_name: bg_class_name, arguments: [project4.id, project5.id], status: 0) }
  let!(:background_migration_job2) { table(:background_migration_jobs).create!(class_name: bg_class_name, arguments: [project6.id, project6.id], status: 0) }
  let!(:background_migration_job3) { table(:background_migration_jobs).create!(class_name: bg_class_name, arguments: [project1.id, project3.id], status: 1) }

  it 'steals remaining jobs, updates any remaining rows and deletes background_migration_jobs rows' do
    expect(Gitlab::BackgroundMigration).to receive(:steal).with(bg_class_name).and_call_original

    migrate!

    expect(project_feature1.reload.container_registry_access_level).to eq(20)
    expect(project_feature2.reload.container_registry_access_level).to eq(0)
    expect(project_feature3.reload.container_registry_access_level).to eq(0)
    expect(project_feature4.reload.container_registry_access_level).to eq(20)
    expect(project_feature5.reload.container_registry_access_level).to eq(0)
    expect(project_feature6.reload.container_registry_access_level).to eq(0)

    expect(table(:background_migration_jobs).where(class_name: bg_class_name).count).to eq(0)
  end
end
