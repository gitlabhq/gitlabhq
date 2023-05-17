# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EnsureWorkItemTypeBackfillMigrationFinished, :migration, feature_category: :team_planning do
  let(:batched_migrations) { table(:batched_background_migrations) }
  let(:work_item_types) { table(:work_item_types) }
  let(:batch_failed_status) { 2 }
  let(:batch_finalized_status) { 3 }

  let!(:migration_class) { described_class::MIGRATION }

  describe '#up', :redis do
    context 'when migration is missing' do
      before do
        batched_migrations.where(job_class_name: migration_class).delete_all
      end

      it 'warns migration not found' do
        expect(Gitlab::AppLogger)
          .to receive(:warn).with(/Could not find batched background migration for the given configuration:/)
                            .exactly(5).times

        migrate!
      end
    end

    context 'with migration present' do
      let(:relevant_types) do
        {
          issue: 0,
          incident: 1,
          test_case: 2,
          requirement: 3,
          task: 4
        }
      end

      let!(:backfill_migrations) do
        relevant_types.map do |_base_type, enum_value|
          type_id = work_item_types.find_by!(namespace_id: nil, base_type: enum_value).id

          create_migration_with(status, enum_value, type_id)
        end
      end

      context 'when migrations have finished' do
        let(:status) { 3 } # finished enum value

        it 'does not raise an error' do
          expect { migrate! }.not_to raise_error
        end
      end

      context 'with different migration statuses' do
        using RSpec::Parameterized::TableSyntax

        where(:status, :description) do
          0 | 'paused'
          1 | 'active'
          4 | 'failed'
          5 | 'finalizing'
        end

        with_them do
          it 'finalizes the migration' do
            expect do
              migrate!

              backfill_migrations.each(&:reload)
            end.to change { backfill_migrations.map(&:status).uniq }.from([status]).to([3])
          end
        end
      end
    end
  end

  def create_migration_with(status, base_type, type_id)
    migration = batched_migrations.create!(
      job_class_name: migration_class,
      table_name: :issues,
      column_name: :id,
      job_arguments: [base_type, type_id],
      interval: 2.minutes,
      min_value: 1,
      max_value: 2,
      batch_size: 1000,
      sub_batch_size: 200,
      gitlab_schema: :gitlab_main,
      status: status
    )

    table(:batched_background_migration_jobs).create!(
      batched_background_migration_id: migration.id,
      status: batch_failed_status,
      min_value: 1,
      max_value: 10,
      attempts: 2,
      batch_size: 100,
      sub_batch_size: 10
    )

    migration
  end
end
