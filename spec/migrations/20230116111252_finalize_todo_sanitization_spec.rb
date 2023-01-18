# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeTodoSanitization, :migration, feature_category: :portfolio_management do
  let(:batched_migrations) { table(:batched_background_migrations) }

  let!(:migration) { described_class::MIGRATION }

  describe '#up' do
    let!(:sanitize_todos_migration) do
      batched_migrations.create!(
        job_class_name: 'SanitizeConfidentialTodos',
        table_name: :notes,
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

    context 'with different migration statuses' do
      using RSpec::Parameterized::TableSyntax

      where(:status, :description) do
        0 | 'paused'
        1 | 'active'
        4 | 'failed'
        5 | 'finalizing'
      end

      with_them do
        before do
          sanitize_todos_migration.update!(status: status)
        end

        it 'finalizes the migration' do
          allow_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner) do |runner|
            expect(runner).to receive(:finalize).with('SanitizeConfidentialTodos', :members, :id, [])
          end
        end
      end
    end
  end
end
