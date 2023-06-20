# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeBackFillPreparedAtMergeRequests, :migration, feature_category: :code_review_workflow do
  let(:batched_migrations) { table(:batched_background_migrations) }

  let!(:migration) { described_class::MIGRATION }

  describe '#up' do
    shared_examples 'finalizes the migration' do
      it 'finalizes the migration' do
        allow_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner) do |runner|
          expect(runner).to receive(:finalize).with(migration, :merge_requests, :id, [nil, "up"])
        end
      end
    end

    context 'when prepared at backfilling migration is missing' do
      before do
        batched_migrations.where(job_class_name: migration).delete_all
      end

      it 'warns migration not found' do
        expect(Gitlab::AppLogger)
          .to receive(:warn).with(/Could not find batched background migration for the given configuration:/)

        migrate!
      end
    end

    context 'with backfilling migration present' do
      let!(:project_namespace_backfill) do
        batched_migrations.create!(
          job_class_name: migration,
          table_name: :merge_requests,
          column_name: :id,
          job_arguments: [],
          interval: 2.minutes,
          min_value: 1,
          max_value: 2,
          batch_size: 1000,
          sub_batch_size: 200,
          gitlab_schema: :gitlab_main,
          status: 3 # finished
        )
      end

      context 'when prepared at backfilling migration finished successfully' do
        it 'does not raise exception' do
          expect { migrate! }.not_to raise_error
        end
      end

      context 'when prepared at backfilling migration is paused' do
        using RSpec::Parameterized::TableSyntax

        where(:status, :description) do
          0 | 'paused'
          1 | 'active'
          4 | 'failed'
          5 | 'finalizing'
        end

        with_them do
          before do
            project_namespace_backfill.update!(status: status)
          end

          it_behaves_like 'finalizes the migration'
        end
      end
    end
  end
end
