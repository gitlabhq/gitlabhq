# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeProjectNamespacesBackfill, :migration do
  let(:batched_migrations) { table(:batched_background_migrations) }

  let_it_be(:migration) { described_class::MIGRATION }

  describe '#up' do
    shared_examples 'finalizes the migration' do
      it 'finalizes the migration' do
        allow_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner) do |runner|
          expect(runner).to receive(:finalize).with('"ProjectNamespaces::BackfillProjectNamespaces"', :projects, :id, [nil, "up"])
        end
      end
    end

    context 'when project namespace backfilling migration is missing' do
      it 'warns migration not found' do
        expect(Gitlab::AppLogger)
          .to receive(:warn).with(/Could not find batched background migration for the given configuration:/)

        migrate!
      end
    end

    context 'with backfilling migration present' do
      let!(:project_namespace_backfill) do
        batched_migrations.create!(
          job_class_name: 'ProjectNamespaces::BackfillProjectNamespaces',
          table_name: :projects,
          column_name: :id,
          job_arguments: [nil, 'up'],
          interval: 2.minutes,
          min_value: 1,
          max_value: 2,
          batch_size: 1000,
          sub_batch_size: 200,
          status: 3 # finished
        )
      end

      context 'when project namespace backfilling migration finished successfully' do
        it 'does not raise exception' do
          expect { migrate! }.not_to raise_error(/Expected batched background migration for the given configuration to be marked as 'finished'/)
        end
      end

      context 'when project namespace backfilling migration is paused' do
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
