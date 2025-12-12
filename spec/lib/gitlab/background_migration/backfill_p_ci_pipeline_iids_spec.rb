# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPCiPipelineIids, feature_category: :continuous_integration do
  let(:connection) { Ci::ApplicationRecord.connection }
  let(:organizations_table) { table(:organizations, database: :main) }
  let(:namespaces_table) { table(:namespaces, database: :main) }
  let(:projects_table) { table(:projects, database: :main) }
  let(:pipelines_table) { ci_partitioned_table(:p_ci_pipelines) }
  let(:pipeline_iids_table) { table(:p_ci_pipeline_iids, database: :ci) }

  let(:organization) { organizations_table.create!(name: 'organization', path: 'organization') }
  let(:namespace1) { namespaces_table.create!(organization_id: organization.id, name: 'name1', path: 'namespace1') }
  let(:namespace2) { namespaces_table.create!(organization_id: organization.id, name: 'name2', path: 'namespace2') }

  let(:project1) do
    projects_table.create!(
      organization_id: organization.id,
      namespace_id: namespace1.id,
      project_namespace_id: namespace1.id
    )
  end

  let(:project2) do
    projects_table.create!(
      organization_id: organization.id,
      namespace_id: namespace2.id,
      project_namespace_id: namespace2.id
    )
  end

  around do |example|
    # The testing env might initialize the first partition as `ci_pipelines FOR VALUES IN ('100', '101', '102')`
    # instead of ci_pipelines_100, so we'll start from partition_id 103 to avoid a partition overlap error.
    connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_pipelines_103"
        PARTITION OF "p_ci_pipelines" FOR VALUES IN (103);
      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_pipelines_104"
        PARTITION OF "p_ci_pipelines" FOR VALUES IN (104);
    SQL

    # Disable the pipeline iid triggers on p_ci_pipelines so that we can set up duplicate iids for testing
    connection.transaction do
      connection.execute(<<~SQL)
        ALTER TABLE p_ci_pipelines DISABLE TRIGGER trigger_ensure_pipeline_iid_uniqueness_before_insert;
        ALTER TABLE p_ci_pipelines DISABLE TRIGGER trigger_ensure_pipeline_iid_uniqueness_before_update_iid;
        ALTER TABLE p_ci_pipelines DISABLE TRIGGER trigger_cleanup_pipeline_iid_after_delete;
      SQL

      example.run

      # Re-enable triggers after test
      connection.execute(<<~SQL)
        ALTER TABLE p_ci_pipelines ENABLE TRIGGER trigger_ensure_pipeline_iid_uniqueness_before_insert;
        ALTER TABLE p_ci_pipelines ENABLE TRIGGER trigger_ensure_pipeline_iid_uniqueness_before_update_iid;
        ALTER TABLE p_ci_pipelines ENABLE TRIGGER trigger_cleanup_pipeline_iid_after_delete;
      SQL
    end
  end

  describe '#perform' do
    before do
      # Data on partition 103
      pipelines_table.create!(project_id: project1.id, partition_id: 103, iid: 1)
      pipelines_table.create!(project_id: project1.id, partition_id: 103, iid: 2)
      pipelines_table.create!(project_id: project1.id, partition_id: 103, iid: nil)
      pipelines_table.create!(project_id: project2.id, partition_id: 103, iid: 1)
      pipelines_table.create!(project_id: project2.id, partition_id: 103, iid: 2)

      # Data on partition 104
      pipelines_table.create!(project_id: project1.id, partition_id: 104, iid: 2) # duplicate
      pipelines_table.create!(project_id: project1.id, partition_id: 104, iid: nil)
      pipelines_table.create!(project_id: project2.id, partition_id: 104, iid: 3)
    end

    it 'copies (project_id, iid) to p_ci_pipeline_iids, ignoring duplicates and null ids' do
      # Ensure initial state
      expect(pipelines_table.pluck(:project_id, :iid))
        .to match_array([
          [project1.id, 1], [project1.id, 2], [project1.id, 2], [project1.id, nil], [project1.id, nil],
          [project2.id, 1], [project2.id, 2], [project2.id, 3]
        ])

      # First perform on partition 103
      expect { perform(migration_attrs(partition_id: 103)) }
        .to change { pipeline_iids_table.pluck(:project_id, :iid) }
        .to match_array([
          [project1.id, 1], [project1.id, 2],
          [project2.id, 1], [project2.id, 2]
        ])

      # Then perform on partition 104
      expect { perform(migration_attrs(partition_id: 104)) }
        .to change { pipeline_iids_table.pluck(:project_id, :iid) }
        .to match_array([
          [project1.id, 1], [project1.id, 2],
          [project2.id, 1], [project2.id, 2], [project2.id, 3]
        ])
    end
  end

  private

  def migration_attrs(partition_id:)
    {
      start_id: pipelines_table.where(partition_id: partition_id).minimum(:id),
      end_id: pipelines_table.where(partition_id: partition_id).maximum(:id),
      batch_table: "gitlab_partitions_dynamic.ci_pipelines_#{partition_id}",
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: connection,
      job_arguments: []
    }
  end

  def perform(migration_attrs)
    described_class.new(**migration_attrs).perform
  end
end
