# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EnsureTaskNoteRenamingBackgroundMigrationFinished, :migration, feature_category: :team_planning do
  let(:batched_migrations) { table(:batched_background_migrations) }
  let(:batch_failed_status) { 2 }
  let(:batch_finalized_status) { 3 }

  let!(:migration) { described_class::MIGRATION }

  describe '#up' do
    shared_examples 'finalizes the migration' do
      it 'finalizes the migration' do
        expect do
          migrate!

          task_renaming_migration.reload
          failed_job.reload
        end.to change(task_renaming_migration, :status).from(task_renaming_migration.status).to(3).and(
          change(failed_job, :status).from(batch_failed_status).to(batch_finalized_status)
        )
      end
    end

    context 'when migration is missing' do
      before do
        batched_migrations.where(job_class_name: migration).delete_all
      end

      it 'warns migration not found' do
        expect(Gitlab::AppLogger)
          .to receive(:warn).with(/Could not find batched background migration for the given configuration:/)

        migrate!
      end
    end

    context 'with migration present' do
      let!(:task_renaming_migration) do
        batched_migrations.create!(
          job_class_name: migration,
          table_name: :system_note_metadata,
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

      context 'when migration finished successfully' do
        it 'does not raise exception' do
          expect { migrate! }.not_to raise_error
        end
      end

      context 'with different migration statuses', :redis do
        using RSpec::Parameterized::TableSyntax

        where(:status, :description) do
          0 | 'paused'
          1 | 'active'
          4 | 'failed'
          5 | 'finalizing'
        end

        with_them do
          let!(:failed_job) do
            table(:batched_background_migration_jobs).create!(
              batched_background_migration_id: task_renaming_migration.id,
              status: batch_failed_status,
              min_value: 1,
              max_value: 10,
              attempts: 2,
              batch_size: 100,
              sub_batch_size: 10
            )
          end

          before do
            task_renaming_migration.update!(status: status)
          end

          it_behaves_like 'finalizes the migration'
        end
      end
    end
  end
end
