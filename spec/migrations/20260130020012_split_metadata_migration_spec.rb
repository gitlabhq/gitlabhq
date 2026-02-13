# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SplitMetadataMigration, migration: :gitlab_ci, feature_category: :continuous_integration do
  let(:view_prefix) { described_class::VIEW_PREFIX }
  let(:view_boundaries) { described_class::VIEW_BOUNDARIES }
  let(:migration_name) { described_class::MIGRATION }

  let(:pipelines_table) { ci_partitioned_table(:p_ci_pipelines) }
  let(:builds_table) { ci_partitioned_table(:p_ci_builds) }

  let!(:original_migration) do
    Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
      job_class_name: migration_name,
      table_name: 'gitlab_partitions_dynamic.ci_builds',
      column_name: :id,
      job_arguments: ['partition_id', [100]],
      interval: 120,
      min_value: 1,
      max_value: 10000,
      batch_size: 1000,
      sub_batch_size: 250,
      gitlab_schema: :gitlab_ci,
      status: 1,
      total_tuple_count: 4774979600,
      id: described_class::MIGRATION_ID
    )
  end

  before do
    statements = [
      'DROP TABLE IF EXISTS gitlab_partitions_dynamic.ci_builds_100 CASCADE;',
      'CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_builds PARTITION OF p_ci_builds FOR VALUES IN (100);'
    ]

    statements += (1..4).map do |i|
      "CREATE OR REPLACE VIEW #{view_prefix}_#{i} AS SELECT id, partition_id FROM p_ci_builds WHERE partition_id = 100;"
    end

    Ci::ApplicationRecord.connection.execute(statements.join("\n"))
  end

  describe '#up' do
    context 'when on GitLab.com', :aggregate_failures do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(true)
      end

      it 'queues background migrations for views 2-4 and updates original migration' do
        expect { migrate! }.to change { original_migration.reload.max_value }

        expect(original_migration.table_name).to eq("#{view_prefix}_1")

        view_boundaries.each_cons(2).map.with_index(1) do |range, index|
          migration = find_migration(index)

          expect(migration).to be_present
          expect(migration.min_value).to eq(range.first)
          expect(migration.max_value).to eq(range.last)
          expect(migration.total_tuple_count).to eq(1193744900)
        end
      end

      def find_migration(index)
        Gitlab::Database::BackgroundMigration::BatchedMigration.find_by(
          job_class_name: migration_name,
          table_name: "#{view_prefix}_#{index}"
        )
      end
    end

    context 'when not on GitLab.com' do
      it 'does not queue any migrations' do
        expect { migrate! }.not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
      end
    end

    context 'when migration does not exist' do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(true)
        original_migration.delete
      end

      it 'does not queue any migrations' do
        expect { migrate! }.not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
      end
    end
  end

  describe '#down' do
    context 'when on GitLab.com', :aggregate_failures do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(true)
        migrate!
      end

      it 'deletes view migrations and restores original migration' do
        schema_migrate_down!

        expect(original_migration.reload.table_name).to eq('gitlab_partitions_dynamic.ci_builds')
        expect(original_migration.max_value).to eq(view_boundaries.last)
        expect(original_migration.total_tuple_count).to eq(4774979600)

        (2..4).each do |view_number|
          view_migration = Gitlab::Database::BackgroundMigration::BatchedMigration.find_by(
            job_class_name: migration_name,
            table_name: "#{view_prefix}_#{view_number}"
          )
          expect(view_migration).to be_nil
        end
      end
    end

    context 'when not on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(false)
      end

      it 'does not attempt to delete migrations' do
        expect { schema_migrate_down! }.not_to raise_error
      end
    end
  end
end
