# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDesiredShardingKeyPartitionJob, migration: :gitlab_ci, feature_category: :cell do
  let(:example_job_class) do
    Class.new(described_class) do
      operation_name :backfill_test_batch_table_project_id
      feature_category :cell
    end
  end

  let(:start_id) { table(batch_table).minimum(:id) }
  let(:end_id) { table(batch_table).maximum(:id) }
  let(:batch_table) { :_test_batch_table }
  let(:backfill_via_table) { :p_ci_builds }
  let(:backfill_column) { :project_id }
  let(:backfill_via_column) { :project_id }
  let(:backfill_via_foreign_key) { :build_id }
  let(:partition_column) { :partition_id }

  let(:test_table) { table(:_test_batch_table) }
  let(:connection) { ::Ci::ApplicationRecord.connection }

  let(:migration_attrs) do
    {
      start_id: start_id,
      end_id: end_id,
      batch_table: batch_table,
      batch_column: :id,
      sub_batch_size: 10,
      pause_ms: 2,
      connection: connection,
      job_arguments: [
        backfill_column,
        backfill_via_table,
        backfill_via_column,
        backfill_via_foreign_key,
        partition_column
      ]
    }
  end

  let(:migration) { example_job_class.new(**migration_attrs) }

  before do
    connection.create_table :_test_batch_table do |t|
      t.timestamps_with_timezone null: false
      t.integer :build_id, null: false
      t.integer :partition_id, null: false
      t.integer :project_id
    end
  end

  after do
    connection.drop_table(:_test_batch_table)
  end

  describe '#perform' do
    let(:ci_pipelines_table) { table(:ci_pipelines, primary_key: :id) }
    let(:ci_builds_table) { table(:p_ci_builds, primary_key: :id) }

    let(:pipeline) { ci_pipelines_table.create!(partition_id: 100, project_id: 1) }
    let!(:job1) { ci_builds_table.create!(partition_id: 100, project_id: 1, commit_id: pipeline.id) }
    let!(:job2) { ci_builds_table.create!(partition_id: 100, project_id: 2, commit_id: pipeline.id) }

    let(:test1) { test_table.create!(id: 1, partition_id: 100, build_id: job1.id, project_id: nil) }
    let(:test2) { test_table.create!(id: 2, partition_id: 100, build_id: job2.id, project_id: nil) }

    it 'backfills the missing project_id for the batch' do
      expect { migration.perform }
        .to change { test1.reload.project_id }.from(nil).to(job1.project_id)
        .and change { test2.reload.project_id }.from(nil).to(job2.project_id)
    end
  end

  describe '#constuct_query' do
    it 'constructs a query using the supplied job arguments' do
      sub_batch = table(batch_table).all

      expect(migration.construct_query(sub_batch: sub_batch)).to eq(<<~SQL)
        UPDATE _test_batch_table
        SET project_id = p_ci_builds.project_id
        FROM p_ci_builds
        WHERE p_ci_builds.id = _test_batch_table.build_id
        AND p_ci_builds.partition_id = _test_batch_table.partition_id
        AND _test_batch_table.id IN (#{sub_batch.select(:id).to_sql})
      SQL
    end
  end
end
