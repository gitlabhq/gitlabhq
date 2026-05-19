# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillPipelinesIdRangeOnCiPartitions, migration: :gitlab_ci, feature_category: :continuous_integration do
  let(:partitions_table) { table(:ci_partitions, database: :ci) }
  let(:pipelines_table)  { table(:p_ci_pipelines, primary_key: :id, database: :ci) }
  let(:builds_table)     { table(:p_ci_builds, primary_key: :id, database: :ci) }

  let!(:partition_100) { partitions_table.create!(id: 100, status: 3) }
  let!(:partition_101) { partitions_table.create!(id: 101, status: 2) }
  let!(:partition_102) { partitions_table.create!(id: 102, status: 1) }

  let!(:pipeline_100_start) { pipelines_table.create!(partition_id: 100, project_id: 1) }
  let!(:pipeline_100_end)   { pipelines_table.create!(partition_id: 100, project_id: 1) }
  let!(:pipeline_101_start) { pipelines_table.create!(partition_id: 101, project_id: 1) }
  let!(:pipeline_101_end)   { pipelines_table.create!(partition_id: 101, project_id: 1) }

  let!(:build_100_a) { builds_table.create!(partition_id: 100, project_id: 1, commit_id: pipeline_100_start.id) }
  let!(:build_100_b) { builds_table.create!(partition_id: 100, project_id: 1, commit_id: pipeline_100_end.id) }
  let!(:build_101_a) { builds_table.create!(partition_id: 101, project_id: 1, commit_id: pipeline_101_start.id) }
  let!(:build_101_b) { builds_table.create!(partition_id: 101, project_id: 1, commit_id: pipeline_101_end.id) }

  before do
    Ci::ApplicationRecord.connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_builds_100"
        PARTITION OF "p_ci_builds" FOR VALUES IN (100);
      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_builds_101"
        PARTITION OF "p_ci_builds" FOR VALUES IN (101);
    SQL
  end

  describe '#up' do
    it 'sets pipelines_id_range from min(commit_id) of N to min(commit_id) of N+1' do
      migrate!

      expect(partition_100.reload.pipelines_id_range)
        .to eq(pipeline_100_start.id...pipeline_101_start.id)
      expect(partition_101.reload.pipelines_id_range)
        .to eq(pipeline_101_start.id...Float::INFINITY)
      expect(partition_102.reload.pipelines_id_range).to be_nil

      expect(partition_100.pipelines_id_range).to cover(pipeline_100_end.id)
      expect(partition_100.pipelines_id_range).not_to cover(pipeline_101_start.id)
    end

    it 'skips partitions with no builds' do
      builds_table.where(partition_id: 100).delete_all

      migrate!

      expect(partition_100.reload.pipelines_id_range).to be_nil
    end
  end

  describe '#down' do
    it 'clears pipelines_id_range on all partitions' do
      migrate!
      schema_migrate_down!

      expect(partition_100.reload.pipelines_id_range).to be_nil
      expect(partition_101.reload.pipelines_id_range).to be_nil
    end
  end
end
