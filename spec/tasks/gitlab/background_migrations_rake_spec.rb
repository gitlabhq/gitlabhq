# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:background_migrations namespace rake tasks' do
  before do
    Rake.application.rake_require 'tasks/gitlab/background_migrations'
  end

  describe 'finalize' do
    subject(:finalize_task) { run_rake_task('gitlab:background_migrations:finalize', *arguments) }

    context 'without the proper arguments' do
      let(:arguments) { %w[CopyColumnUsingBackgroundMigrationJob events id] }

      it 'exits without finalizing the migration' do
        expect(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner).not_to receive(:finalize)

        expect { finalize_task }.to output(/Must specify job_arguments as an argument/).to_stdout
          .and raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      end
    end

    context 'with the proper arguments' do
      let(:arguments) { %w[CopyColumnUsingBackgroundMigrationJob events id [["id1"\,"id2"]]] }

      it 'finalizes the matching migration' do
        expect(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner).to receive(:finalize)
          .with('CopyColumnUsingBackgroundMigrationJob', 'events', 'id', [%w[id1 id2]])

        expect { finalize_task }.to output(/Done/).to_stdout
      end
    end
  end

  describe 'status' do
    subject(:status_task) { run_rake_task('gitlab:background_migrations:status') }

    it 'outputs the status of background migrations' do
      migration1 = create(:batched_background_migration, :finished, job_arguments: [%w[id1 id2]])
      migration2 = create(:batched_background_migration, :failed, job_arguments: [])

      expect { status_task }.to output(<<~OUTPUT).to_stdout
        finished   | #{migration1.job_class_name},#{migration1.table_name},#{migration1.column_name},[["id1","id2"]]
        failed     | #{migration2.job_class_name},#{migration2.table_name},#{migration2.column_name},[]
      OUTPUT
    end
  end
end
