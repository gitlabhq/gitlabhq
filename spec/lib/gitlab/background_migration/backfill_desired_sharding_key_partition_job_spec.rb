# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDesiredShardingKeyPartitionJob, migration: :gitlab_ci, feature_category: :cell do
  let(:example_job_class) do
    Class.new(described_class) do
      operation_name :backfill_test_batch_table_project_id
      feature_category :cell
    end
  end

  let(:batch_column) { :id }
  let(:backfill_via_table) { :p_ci_builds }
  let(:start_id) { table(batch_table).minimum(batch_column) }
  let(:end_id) { table(batch_table).maximum(batch_column) }
  let(:batch_table) { :_test_batch_table }
  let(:backfill_column) { :project_id }
  let(:backfill_via_column) { :project_id }
  let(:backfill_via_foreign_key) { :build_id }
  let(:partition_column) { :partition_id }

  let(:test_table) { table(batch_table) }
  let(:connection) { ::Ci::ApplicationRecord.connection }

  let(:migration_attrs) do
    {
      start_id: start_id,
      end_id: end_id,
      batch_table: batch_table,
      batch_column: batch_column,
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
    connection.drop_table(batch_table, if_exists: true)
    connection.create_table batch_table do |t|
      t.timestamps_with_timezone null: false
      t.integer :build_id, null: false
      t.integer :partition_id, null: false
      t.integer :project_id
    end
  end

  after do
    connection.drop_table(batch_table)
  end

  describe '#perform' do
    let(:ci_pipelines_table) { table(:p_ci_pipelines, primary_key: :id) }
    let(:ci_builds_table) { table(:p_ci_builds, primary_key: :id) }

    let(:pipeline) { ci_pipelines_table.create!(partition_id: 100, project_id: 1) }
    let!(:job1) { ci_builds_table.create!(partition_id: 100, project_id: 1, commit_id: pipeline.id) }
    let!(:job2) { ci_builds_table.create!(partition_id: 100, project_id: 2, commit_id: pipeline.id) }

    let(:test1) { test_table.create!(id: 1, partition_id: 100, build_id: job1.id, project_id: nil) }
    let(:test2) { test_table.create!(id: 2, partition_id: 100, build_id: job2.id, project_id: nil) }

    shared_examples 'a migration backfilling the missing project_id for the batch' do
      it 'backfills the missing project_id for the batch' do
        expect { migration.perform }
          .to change { test1.reload.project_id }.from(nil).to(job1.project_id)
          .and change { test2.reload.project_id }.from(nil).to(job2.project_id)
      end
    end

    context "when batch_column is id" do
      let(:batch_column) { :id }

      it_behaves_like 'a migration backfilling the missing project_id for the batch'
    end

    context "when batch_column is build_id" do
      let(:batch_column) { :build_id }

      it_behaves_like 'a migration backfilling the missing project_id for the batch'
    end

    context "when batch_column is invalid" do
      let(:batch_column) { :project_id }

      it 'does not backfill the missing project_id for the batch' do
        expect { migration.perform }
          .to not_change { test1.reload.project_id }.from(nil)
          .and not_change { test2.reload.project_id }.from(nil)
      end
    end
  end

  describe '#constuct_query' do
    using RSpec::Parameterized::TableSyntax

    where(:batch_column) do
      [:id, :build_id]
    end

    with_them do
      it 'constructs a query using the supplied job arguments' do
        sub_batch = table(batch_table).all

        expect(migration.construct_query(sub_batch: sub_batch)).to eq(<<~SQL)
          UPDATE #{batch_table}
          SET project_id = #{backfill_via_table}.#{backfill_via_column}
          FROM #{backfill_via_table}
          WHERE #{backfill_via_table}.id = #{batch_table}.#{backfill_via_foreign_key}
          AND #{backfill_via_table}.#{partition_column} = #{batch_table}.#{partition_column}
          AND #{batch_table}.#{batch_column} IN (#{sub_batch.select(batch_column).to_sql})
        SQL
      end
    end
  end
end
