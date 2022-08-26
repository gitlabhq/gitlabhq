# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::TestBatchedBackgroundRunner, :freeze_time do
  include Gitlab::Database::MigrationHelpers
  include Database::MigrationTestingHelpers

  let(:result_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(result_dir)
  end

  let(:migration) do
    ActiveRecord::Migration.new.extend(Gitlab::Database::Migrations::BatchedBackgroundMigrationHelpers)
  end

  let(:connection) { ApplicationRecord.connection }

  let(:table_name) { "_test_column_copying" }

  before do
    connection.execute(<<~SQL)
      CREATE TABLE #{table_name} (
        id bigint primary key not null,
        data bigint default 0
      );

      insert into #{table_name} (id) select i from generate_series(1, 1000) g(i);
    SQL

    allow(migration).to receive(:transaction_open?).and_return(false)
  end

  context 'running a real background migration' do
    it 'runs sampled jobs from the batched background migration' do
      migration.queue_batched_background_migration('CopyColumnUsingBackgroundMigrationJob',
                                         table_name, :id,
                                         :id, :data,
                                         batch_size: 100,
                                         job_interval: 5.minutes) # job_interval is skipped when testing

      # Expect that running sampling for this migration processes some of the rows. Sampling doesn't run
      # over every row in the table, so this does not completely migrate the table.
      expect { described_class.new(result_dir: result_dir, connection: connection).run_jobs(for_duration: 1.minute) }
        .to change { define_batchable_model(table_name).where('id IS DISTINCT FROM data').count }
              .by_at_most(-1)
    end
  end

  context 'with jobs to run' do
    let(:migration_name) { 'TestBackgroundMigration' }

    it 'samples jobs' do
      calls = []
      define_background_migration(migration_name) do |*args|
        calls << args
      end

      migration.queue_batched_background_migration(migration_name, table_name, :id,
                                                   job_interval: 5.minutes,
                                                   batch_size: 100)

      described_class.new(result_dir: result_dir, connection: connection).run_jobs(for_duration: 3.minutes)

      expect(calls).not_to be_empty
    end

    context 'with multiple jobs to run' do
      it 'runs all jobs created within the last 3 hours' do
        old_migration = define_background_migration(migration_name)
        migration.queue_batched_background_migration(migration_name, table_name, :id,
                                             job_interval: 5.minutes,
                                             batch_size: 100)

        travel 4.hours

        new_migration = define_background_migration('NewMigration') { travel 1.second }
        migration.queue_batched_background_migration('NewMigration', table_name, :id,
                                           job_interval: 5.minutes,
                                           batch_size: 10,
                                           sub_batch_size: 5)

        other_new_migration = define_background_migration('NewMigration2') { travel 2.seconds }
        migration.queue_batched_background_migration('NewMigration2', table_name, :id,
                                           job_interval: 5.minutes,
                                           batch_size: 10,
                                           sub_batch_size: 5)

        expect_migration_runs(new_migration => 3, other_new_migration => 2, old_migration => 0) do
          described_class.new(result_dir: result_dir, connection: connection).run_jobs(for_duration: 5.seconds)
        end
      end
    end
  end

  context 'choosing uniform batches to run' do
    subject { described_class.new(result_dir: result_dir, connection: connection) }

    describe '#uniform_fractions' do
      it 'generates evenly distributed sequences of fractions' do
        received = subject.uniform_fractions.take(9)
        expected = [0, 1, 1.0 / 2, 1.0 / 4, 3.0 / 4, 1.0 / 8, 3.0 / 8, 5.0 / 8, 7.0 / 8]

        # All the fraction numerators are small integers, and all denominators are powers of 2, so these
        # fit perfectly into floating point numbers with zero loss of precision
        expect(received).to eq(expected)
      end
    end
  end
end
