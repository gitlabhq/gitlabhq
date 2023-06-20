# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EnsureIncidentWorkItemTypeBackfillIsFinished, :migration, feature_category: :team_planning do
  include MigrationHelpers::WorkItemTypesHelper

  let(:batched_migrations) { table(:batched_background_migrations) }
  let(:work_item_types) { table(:work_item_types) }
  let(:batch_failed_status) { 2 }

  let!(:migration_class) { described_class::MIGRATION }

  describe '#up', :redis do
    it "doesn't fail if work item types don't exist on the DB" do
      table(:work_item_types).delete_all

      migrate!

      # Since migration specs run outside of a transaction, we need to make
      # sure we recreate default types since this spec deletes them all
      reset_work_item_types
    end

    context 'when migration is missing' do
      before do
        batched_migrations.where(job_class_name: migration_class).delete_all
      end

      it 'warns migration not found' do
        expect(Gitlab::AppLogger)
          .to receive(:warn).with(/Could not find batched background migration for the given configuration:/)
                            .once

        migrate!
      end
    end

    context 'with migration present' do
      let!(:backfill_migration) do
        type_id = work_item_types.find_by!(namespace_id: nil, base_type: described_class::INCIDENT_ENUM_TYPE).id

        create_migration_with(status, described_class::INCIDENT_ENUM_TYPE, type_id)
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

              backfill_migration.reload
            end.to change { backfill_migration.status }.from(status).to(3)
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
