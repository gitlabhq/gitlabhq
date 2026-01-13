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
      allow(runner).to receive(:jobs_by_migration_name).and_return({ 'test_migration' => jobs })
      allow(runner).to receive(:run_job)
    end

    context 'when no jobs are processed' do
      let(:jobs) { [] }

      it 'creates the migration result directory and marker file' do
        runner.run_jobs(for_duration: 1.minute)

        migration_dir = File.join(result_dir, 'test_migration')
        marker_file = File.join(migration_dir, '.no_batches_processed')

        expect(File.directory?(migration_dir)).to be true
        expect(File.exist?(marker_file)).to be true
      end
    end

    context 'when jobs are processed' do
      let(:jobs) { [{ id: 1 }] }

      it 'creates batch directories and does not create marker file' do
        runner.run_jobs(for_duration: 1.minute)

        migration_dir = File.join(result_dir, 'test_migration')
        batch_dir = File.join(migration_dir, 'batch_1')
        marker_file = File.join(migration_dir, '.no_batches_processed')

        expect(File.directory?(migration_dir)).to be true
        expect(File.directory?(batch_dir)).to be true
        expect(File.exist?(marker_file)).to be false
      end
    end
  end
end
