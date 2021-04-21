# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MoveContainerRegistryEnabledToProjectFeature, :migration, schema: 2021_02_26_120851 do
  let(:enabled) { 20 }
  let(:disabled) { 0 }

  let(:namespaces) { table(:namespaces) }
  let(:project_features) { table(:project_features) }
  let(:projects) { table(:projects) }

  let(:namespace) { namespaces.create!(name: 'user', path: 'user') }
  let!(:project1) { projects.create!(namespace_id: namespace.id) }
  let!(:project2) { projects.create!(namespace_id: namespace.id) }
  let!(:project3) { projects.create!(namespace_id: namespace.id) }
  let!(:project4) { projects.create!(namespace_id: namespace.id) }

  # pages_access_level cannot be null.
  let(:non_null_project_features) { { pages_access_level: enabled } }
  let!(:project_feature1) { project_features.create!(project_id: project1.id, **non_null_project_features) }
  let!(:project_feature2) { project_features.create!(project_id: project2.id, **non_null_project_features) }
  let!(:project_feature3) { project_features.create!(project_id: project3.id, **non_null_project_features) }

  describe '#perform' do
    before do
      project1.update!(container_registry_enabled: true)
      project2.update!(container_registry_enabled: false)
      project3.update!(container_registry_enabled: nil)
      project4.update!(container_registry_enabled: true)
    end

    it 'copies values to project_features' do
      table(:background_migration_jobs).create!(
        class_name: 'MoveContainerRegistryEnabledToProjectFeature',
        arguments: [project1.id, project4.id]
      )
      table(:background_migration_jobs).create!(
        class_name: 'MoveContainerRegistryEnabledToProjectFeature',
        arguments: [-1, -3]
      )

      expect(project1.container_registry_enabled).to eq(true)
      expect(project2.container_registry_enabled).to eq(false)
      expect(project3.container_registry_enabled).to eq(nil)
      expect(project4.container_registry_enabled).to eq(true)

      expect(project_feature1.container_registry_access_level).to eq(disabled)
      expect(project_feature2.container_registry_access_level).to eq(disabled)
      expect(project_feature3.container_registry_access_level).to eq(disabled)

      expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |logger|
        expect(logger).to receive(:info)
          .with(message: "#{described_class}: Copied container_registry_enabled values for projects with IDs between #{project1.id}..#{project4.id}")

        expect(logger).not_to receive(:info)
      end

      subject.perform(project1.id, project4.id)

      expect(project1.reload.container_registry_enabled).to eq(true)
      expect(project2.reload.container_registry_enabled).to eq(false)
      expect(project3.reload.container_registry_enabled).to eq(nil)
      expect(project4.container_registry_enabled).to eq(true)

      expect(project_feature1.reload.container_registry_access_level).to eq(enabled)
      expect(project_feature2.reload.container_registry_access_level).to eq(disabled)
      expect(project_feature3.reload.container_registry_access_level).to eq(disabled)

      expect(table(:background_migration_jobs).first.status).to eq(1) # succeeded
      expect(table(:background_migration_jobs).second.status).to eq(0) # pending
    end

    context 'when no projects exist in range' do
      it 'does not fail' do
        expect(project1.container_registry_enabled).to eq(true)
        expect(project_feature1.container_registry_access_level).to eq(disabled)

        expect { subject.perform(-1, -2) }.not_to raise_error

        expect(project1.container_registry_enabled).to eq(true)
        expect(project_feature1.container_registry_access_level).to eq(disabled)
      end
    end

    context 'when projects in range all have nil container_registry_enabled' do
      it 'does not fail' do
        expect(project3.container_registry_enabled).to eq(nil)
        expect(project_feature3.container_registry_access_level).to eq(disabled)

        expect { subject.perform(project3.id, project3.id) }.not_to raise_error

        expect(project3.container_registry_enabled).to eq(nil)
        expect(project_feature3.container_registry_access_level).to eq(disabled)
      end
    end
  end
end
