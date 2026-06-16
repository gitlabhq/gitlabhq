# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateBackfillMergeRequestDiffCommitsToPartitioned, migration: :gitlab_main_org,
  feature_category: :code_review_workflow do
  let(:migration_name) { described_class::MIGRATION }
  let(:view_prefix) { described_class::VIEW_PREFIX }
  let(:view_count) { described_class::VIEW_COUNT }

  def create_bbm(table_name:, max_batch_size: 250_000)
    Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
      job_class_name: migration_name,
      table_name: table_name,
      column_name: 'merge_request_diff_id',
      job_arguments: %w[merge_request_diff_commits_b5377a7a34],
      interval: 120,
      min_value: 1,
      max_value: 2,
      batch_size: 50_000,
      sub_batch_size: 1_000,
      max_batch_size: max_batch_size,
      pause_ms: 100,
      gitlab_schema: :gitlab_main_org,
      status: 1,
      total_tuple_count: 1000
    )
  end

  context 'when on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    context 'when BBMs exist', :aggregate_failures do
      let!(:existing_bbms) do
        Array.new(view_count) { |i| create_bbm(table_name: "#{view_prefix}_#{i + 1}") }
      end

      describe '#up' do
        it 'updates max_batch_size to the new cap on all 4 BBMs' do
          expect { migrate! }
            .to change { existing_bbms.map { |bbm| bbm.reload.max_batch_size } }
              .from([250_000] * view_count)
              .to([described_class::MAX_BATCH_SIZE] * view_count)
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

  context 'when not on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    context 'when BBMs exist' do
      let!(:existing_bbms) do
        Array.new(view_count) { |i| create_bbm(table_name: "#{view_prefix}_#{i + 1}") }
      end

      describe '#up' do
        it 'does not update max_batch_size' do
          expect { migrate! }
            .not_to change { existing_bbms.map { |bbm| bbm.reload.max_batch_size } }
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
end
