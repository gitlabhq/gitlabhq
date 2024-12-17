# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProjectIdToDependencyListExports, feature_category: :dependency_management do
  let(:dependency_list_exports) { table(:dependency_list_exports) }
  let(:pipelines) { partitioned_table(:p_ci_pipelines, database: :ci) }
  let(:organizations) { table(:organizations) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }

  let!(:pipeline) { create_ci_pipeline('pipeline-1') }

  let(:args) do
    min, max = dependency_list_exports.pick('MIN(id)', 'MAX(id)')

    {
      start_id: min,
      end_id: max,
      batch_table: 'dependency_list_exports',
      batch_column: 'id',
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  subject(:perform_migration) { described_class.new(**args).perform }

  context 'when export is missing project_id' do
    let!(:export) { dependency_list_exports.create!(pipeline_id: pipeline.id) }
    let!(:other_pipeline) { create_ci_pipeline('pipeline-2') }
    let!(:export_on_same_pipeline) { dependency_list_exports.create!(pipeline_id: pipeline.id) }
    let!(:export_on_different_pipeline) { dependency_list_exports.create!(pipeline_id: other_pipeline.id) }

    it 'sets the project_id to build.project_id' do
      expect { perform_migration }.to change { export.reload.project_id }.from(nil).to(pipeline.project_id)
        .and change { export_on_same_pipeline.reload.project_id }.from(nil).to(pipeline.project_id)
        .and change { export_on_different_pipeline.reload.project_id }.from(nil).to(other_pipeline.project_id)
    end
  end

  context 'when export pipeline does not exist' do
    let!(:export) { dependency_list_exports.create!(pipeline_id: non_existing_record_id) }

    it 'deletes the export' do
      expect { perform_migration }.to change { dependency_list_exports.count }.from(1).to(0)
    end
  end

  context 'when export is dangling' do
    let!(:export) { dependency_list_exports.create!(pipeline_id: pipeline.id, status: 2, updated_at: 1.month.ago) }

    it 'deletes the export' do
      expect { perform_migration }.to change { dependency_list_exports.count }.from(1).to(0)
    end
  end

  context 'when export finished recently' do
    let!(:export) { dependency_list_exports.create!(pipeline_id: pipeline.id, status: 2, updated_at: 5.minutes.ago) }

    it 'does not delete the export' do
      expect { perform_migration }.not_to change { dependency_list_exports.count }
    end
  end

  context 'when export is not completed' do
    let!(:export) { dependency_list_exports.create!(pipeline_id: pipeline.id, status: 1, updated_at: 2.hours.ago) }

    it 'does not delete the export' do
      expect { perform_migration }.not_to change { dependency_list_exports.count }
    end
  end

  def create_ci_pipeline(name)
    organization = organizations.create!(name: "organization-#{name}", path: "organization-#{name}")
    namespace = namespaces.create!(name: "group-#{name}", path: "group-#{name}", organization_id: organization.id)

    project_namespace = namespaces.create!(
      name: "project-#{name}",
      path: "project-#{name}",
      organization_id: organization.id
    )

    project = projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id,
      name: "project-#{name}",
      path: "project-#{name}"
    )
    pipelines.create!(project_id: project.id, partition_id: 100)
  end
end
