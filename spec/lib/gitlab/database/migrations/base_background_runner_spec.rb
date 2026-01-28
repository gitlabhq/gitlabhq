# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::BaseBackgroundRunner, :freeze_time, feature_category: :database do
  let(:connection) { ApplicationRecord.connection }

  let(:result_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(result_dir)
  end

  context 'subclassing' do
    subject { described_class.new(result_dir: result_dir, connection: connection) }

    it 'requires that jobs_by_migration_name be implemented' do
      expect { subject.jobs_by_migration_name }.to raise_error(NotImplementedError)
    end

    it 'requires that run_job be implemented' do
      expect { subject.run_job(nil) }.to raise_error(NotImplementedError)
    end
  end

  context 'when processing jobs' do
    let(:runner) { described_class.new(result_dir: result_dir, connection: connection) }

    before do
      allow(runner).to receive(:jobs_by_migration_name).and_return(jobs_by_migration)
      allow(runner).to receive(:run_job)
    end

    context 'when jobs_by_migration_name is empty' do
      let(:jobs_by_migration) { {} }

      it 'returns early without creating directories' do
        runner.run_jobs(for_duration: 1.minute)

        expect(Dir.empty?(result_dir)).to be true
      end
    end

    context 'when no jobs are processed for a migration' do
      let(:jobs_by_migration) { { 'TestMigration' => [].each } }

      it 'creates the migration result directory and marker file' do
        runner.run_jobs(for_duration: 1.minute)

        migration_dir = File.join(result_dir, 'TestMigration')
        marker_file = File.join(migration_dir, '.no_batches_processed')

        expect(File.directory?(migration_dir)).to be true
        expect(File.exist?(marker_file)).to be true
      end
    end

    context 'when jobs are processed' do
      let(:jobs_by_migration) { { 'TestMigration' => [{ id: 1 }, { id: 2 }].each } }

      it 'creates batch directories and does not create marker file' do
        runner.run_jobs(for_duration: 1.minute)

        migration_dir = File.join(result_dir, 'TestMigration')
        batch_1_dir = File.join(migration_dir, 'batch_1')
        batch_2_dir = File.join(migration_dir, 'batch_2')
        marker_file = File.join(migration_dir, '.no_batches_processed')

        expect(File.directory?(migration_dir)).to be true
        expect(File.directory?(batch_1_dir)).to be true
        expect(File.directory?(batch_2_dir)).to be true
        expect(File.exist?(marker_file)).to be false
      end
    end
  end

  context 'integration with real batched migrations', :reestablished_active_record_base do
    let(:test_runner) do
      Gitlab::Database::Migrations::TestBatchedBackgroundRunner.new(
        result_dir: result_dir,
        connection: connection,
        from_id: 0
      )
    end

    before do
      connection.execute('CREATE TEMPORARY TABLE _test_empty_table (id bigint PRIMARY KEY)')

      Gitlab::Database::SharedModel.using_connection(connection) do
        create(:batched_background_migration, :active, table_name: '_test_empty_table', column_name: 'id')
      end
    end

    it 'creates migration directory and marker file when table is empty' do
      test_runner.run_jobs(for_duration: 1.minute)

      migration_dirs = Dir.glob(File.join(result_dir, '*')).select { |f| File.directory?(f) }
      expect(migration_dirs).not_to be_empty

      marker_files = Dir.glob(File.join(result_dir, '*', '.no_batches_processed'))
      expect(marker_files.length).to be >= 1
    end
  end
end
