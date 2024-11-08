# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::TestBackgroundRunner, :redis do
  include Gitlab::Database::Migrations::ReestablishedConnectionStack
  include Gitlab::Database::Migrations::BackgroundMigrationHelpers
  include Database::MigrationTestingHelpers

  # In order to test the interaction between queueing sidekiq jobs and seeing those jobs in queues,
  # we need to disable sidekiq's testing mode and actually send our jobs to redis
  around do |ex|
    Sidekiq::Testing.disable! { ex.run }
  end

  let(:result_dir) { Dir.mktmpdir }
  let(:connection) { ApplicationRecord.connection }

  after do
    FileUtils.rm_rf(result_dir)
  end

  context 'without jobs to run' do
    it 'returns immediately' do
      runner = described_class.new(result_dir: result_dir)
      expect(runner).not_to receive(:run_job)
      described_class.new(result_dir: result_dir).run_jobs(for_duration: 1.second)
    end
  end

  context 'with jobs to run' do
    let(:migration_name) { 'TestBackgroundMigration' }

    before do
      (1..5).each do |i|
        migrate_in(i.minutes, migration_name, [i])
      end
    end

    context 'finding pending background jobs' do
      it 'finds all the migrations' do
        expect(described_class.new(result_dir: result_dir).traditional_background_migrations.to_a.size).to eq(5)
      end
    end

    context 'running migrations', :freeze_time do
      it 'runs the migration class correctly' do
        calls = []
        define_background_migration(migration_name, with_base_class: false) do |i|
          calls << i
        end
        described_class.new(result_dir: result_dir).run_jobs(for_duration: 1.second) # Any time would work here as we do not advance time
        expect(calls).to contain_exactly(1, 2, 3, 4, 5)
      end

      it 'runs the migration for a uniform amount of time' do
        migration = define_background_migration(migration_name, with_base_class: false) do |i|
          travel(1.minute)
        end

        expect_migration_runs(migration => 3) do
          described_class.new(result_dir: result_dir).run_jobs(for_duration: 3.minutes)
        end
      end

      context 'with multiple migrations to run' do
        let(:other_migration_name) { 'OtherBackgroundMigration' }

        before do
          (1..5).each do |i|
            migrate_in(i.minutes, other_migration_name, [i])
          end
        end

        it 'splits the time between migrations when all migrations use all their time' do
          migration = define_background_migration(migration_name, with_base_class: false) do |i|
            travel(1.minute)
          end

          other_migration = define_background_migration(other_migration_name, with_base_class: false) do |i|
            travel(2.minutes)
          end

          expect_migration_runs(
            migration => 2, # 1 minute jobs for 90 seconds, can finish the first and start the second
            other_migration => 1 # 2 minute jobs for 90 seconds, past deadline after a single job
          ) do
            described_class.new(result_dir: result_dir).run_jobs(for_duration: 3.minutes)
          end
        end

        it 'does not give leftover time to extra migrations' do
          # This is currently implemented this way for simplicity, but it could make sense to change this behavior.

          migration = define_background_migration(migration_name, with_base_class: false) do
            travel(1.second)
          end
          other_migration = define_background_migration(other_migration_name, with_base_class: false) do
            travel(1.minute)
          end

          expect_migration_runs(
            migration => 5,
            other_migration => 2
          ) do
            described_class.new(result_dir: result_dir).run_jobs(for_duration: 3.minutes)
          end
        end
      end
    end
  end
end
