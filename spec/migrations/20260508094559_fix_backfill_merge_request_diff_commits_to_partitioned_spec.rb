# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixBackfillMergeRequestDiffCommitsToPartitioned, migration: :gitlab_main_org,
  feature_category: :code_review_workflow do
  let(:migration_name) { described_class::MIGRATION }
  let(:view_prefix) { described_class::VIEW_PREFIX }
  let(:view_count) { described_class::VIEW_COUNT }

  def create_bbm(table_name:, sub_batch_size: 1_000, batch_size: 50_000)
    Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
      job_class_name: migration_name,
      table_name: table_name,
      column_name: 'merge_request_diff_id',
      job_arguments: %w[merge_request_diff_commits_b5377a7a34],
      interval: 120,
      min_value: 1,
      max_value: 2,
      batch_size: batch_size,
      sub_batch_size: sub_batch_size,
      pause_ms: 100,
      gitlab_schema: :gitlab_main_org,
      status: 1,
      total_tuple_count: 1000
    )
  end

  context 'when on GitLab.com', :aggregate_failures do
    let(:table_cardinality) { 4_000_000 }
    let(:per_view_count) { table_cardinality / view_count }

    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)

      pg_class = instance_double(Gitlab::Database::PgClass, cardinality_estimate: table_cardinality)
      allow(Gitlab::Database::PgClass).to receive(:for_table).and_return(pg_class)
    end

    context 'when BBMs exist', :aggregate_failures do
      let!(:existing_bbms) do
        Array.new(view_count) do |index|
          create_bbm(table_name: "#{view_prefix}_#{index + 1}")
        end
      end

      describe '#up' do
        it 'updates sub_batch_size and batch_size on all 4 BBMs' do
          expect { migrate! }
            .to change { existing_bbms.map { |bbm| bbm.reload.sub_batch_size } }
              .from([1_000] * view_count).to([described_class::SUB_BATCH_SIZE] * view_count)
            .and change { existing_bbms.map { |bbm| bbm.reload.batch_size } }
              .from([50_000] * 4).to([described_class::BATCH_SIZE] * view_count)
        end

        it 'sets total_tuple_count to per-view cardinality estimate' do
          expect { migrate! }
            .to change { existing_bbms.map { |bbm| bbm.reload.total_tuple_count } }
              .from([1000] * 4).to([per_view_count] * view_count)
        end

        it 'does not create additional BBM records' do
          expect { migrate! }
            .not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
        end
      end

      describe '#down' do
        it 'is a no-op' do
          migrate!

          expect { schema_migrate_down! }
            .not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
        end
      end
    end

    context 'when BBMs do not exist' do
      it 'does not raise and does not create any BBMs' do
        expect { migrate! }
          .not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
      end
    end
  end

  context 'when not on GitLab.com', :aggregate_failures do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    context 'when BBM exists' do
      let!(:existing_bbm) { create_bbm(table_name: described_class::TABLE) }

      describe '#up' do
        it 'updates sub_batch_size and batch_size' do
          expect { migrate! }
            .to change { existing_bbm.reload.sub_batch_size }.from(1_000).to(described_class::SUB_BATCH_SIZE)
            .and change { existing_bbm.reload.batch_size }.from(50_000).to(described_class::BATCH_SIZE)
        end

        it 'does not create additional BBM records' do
          expect { migrate! }
            .not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
        end
      end

      describe '#down' do
        it 'is a no-op' do
          migrate!

          expect { schema_migrate_down! }
            .not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
        end
      end
    end

    context 'when BBM does not exist' do
      it 'does not raise and does not create any BBMs' do
        expect { migrate! }
          .not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
      end
    end
  end
end
