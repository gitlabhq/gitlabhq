# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProjectIdForProjectsWithPipelineVariables,
  feature_category: :ci_variables do
  let(:projects_table) { table(:projects) }
  let(:namespaces_table) { table(:namespaces) }
  let(:organizations_table) { table(:organizations) }
  let(:project_with_pipeline_variables) { table(:projects_with_pipeline_variables, database: :main) }
  let(:pipelines_table) { partitioned_table(:p_ci_pipelines, database: :ci) }
  let(:variables_table) { partitioned_table(:p_ci_pipeline_variables, database: :ci) }

  let!(:organization) { organizations_table.create!(id: 1, name: 'organization', path: 'organization') }
  let!(:namespace1) { namespaces_table.create!(id: 1, name: 'Namespace 1', path: 'namespace-1', organization_id: 1) }
  let!(:namespace2) { namespaces_table.create!(id: 2, name: 'Namespace 2', path: 'namespace-2', organization_id: 1) }
  let!(:namespace3) { namespaces_table.create!(id: 3, name: 'Namespace 3', path: 'namespace-3', organization_id: 1) }
  let!(:project1) { projects_table.create!(build_test_project_attributes(1)) }
  let!(:project2) { projects_table.create!(build_test_project_attributes(2)) }
  let!(:project3) { projects_table.create!(build_test_project_attributes(3)) }

  let!(:regular_pipeline) { pipelines_table.create!(project_id: 600, partition_id: 100) }
  let(:default_attributes) { { pipeline_id: regular_pipeline.id, partition_id: 100 } }

  let(:args) do
    {
      batch_table: :p_ci_pipeline_variables,
      batch_column: :project_id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ::Ci::ApplicationRecord.connection
    }
  end

  subject(:perform_migration) { described_class.new(**args).perform }

  context 'when multiple pipeline variables are present' do
    let!(:variable1) { variables_table.create!(project_id: 1, key: :key1, **default_attributes) }
    let!(:variable2) { variables_table.create!(project_id: 2, key: :key2, **default_attributes) }
    let!(:variable3) { variables_table.create!(project_id: 3, key: :key3, **default_attributes) }

    it 'upserts corresponding project_ids' do
      expect { perform_migration }.to change { project_with_pipeline_variables.count }.from(0).to(3)
      expect(project_with_pipeline_variables.pluck(:project_id)).to match_array([1, 2, 3])
    end

    context 'when project ids already backfilled' do
      before do
        perform_migration
      end

      it 'does not introduce new records' do
        expect { perform_migration }.not_to change { project_with_pipeline_variables.count }
      end
    end
  end

  private

  def build_test_project_attributes(id)
    { id: id,
      name: "Project #{id}",
      path: "project-#{id}",
      namespace_id: 1,
      organization_id: 1,
      project_namespace_id: id }
  end
end
