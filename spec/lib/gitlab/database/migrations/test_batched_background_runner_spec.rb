# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::TestBatchedBackgroundRunner, :freeze_time, feature_category: :database do
  include Gitlab::Database::MigrationHelpers
  include Database::MigrationTestingHelpers

  def queue_migration(
    job_class_name,
    batch_table_name,
    batch_column_name,
    *job_arguments,
    job_interval:,
    batch_size: Gitlab::Database::Migrations::BatchedBackgroundMigrationHelpers::BATCH_SIZE,
    sub_batch_size: Gitlab::Database::Migrations::BatchedBackgroundMigrationHelpers::SUB_BATCH_SIZE
  )

    batch_max_value = define_batchable_model(batch_table_name, connection: connection).maximum(batch_column_name)

    Gitlab::Database::SharedModel.using_connection(connection) do
      Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
        job_class_name: job_class_name,
        table_name: batch_table_name,
        column_name: batch_column_name,
        job_arguments: job_arguments,
        interval: job_interval,
        min_value: Gitlab::Database::Migrations::BatchedBackgroundMigrationHelpers::BATCH_MIN_VALUE,
        max_value: batch_max_value,
        batch_class_name: Gitlab::Database::Migrations::BatchedBackgroundMigrationHelpers::BATCH_CLASS_NAME,
        batch_size: batch_size,
        sub_batch_size: sub_batch_size,
        status_event: :execute,
        max_batch_size: nil,
        gitlab_schema: gitlab_schema
      )
    end
  end

  where(:case_name, :base_model, :gitlab_schema) do
    [
      ['main database', ApplicationRecord, :gitlab_main],
      ['ci database', Ci::ApplicationRecord, :gitlab_ci]
    ]
  end

  with_them do
    let(:result_dir) { Pathname.new(Dir.mktmpdir) }
    let(:connection) { base_model.connection }
    let(:table_name) { "_test_column_copying" }
    let(:num_rows_in_table) { 1000 }
    let(:from_id) { 0 }

    after do
      FileUtils.rm_rf(result_dir)
    end

    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{table_name} (
          id bigint primary key not null,
          data bigint default 0
        );

        insert into #{table_name} (id) select i from generate_series(1, #{num_rows_in_table}) g(i);
      SQL
    end

    context 'running a real background migration' do
      let(:interval) { 5.minutes }
      let(:params) { { version: nil, connection: connection } }
      let(:migration_name) { 'CopyColumnUsingBackgroundMigrationJob' }
      let(:migration_file_path) { result_dir.join('CopyColumnUsingBackgroundMigrationJob', 'details.json') }
      let(:json_file) { Gitlab::Json.parse(File.read(migration_file_path)) }
      let(:expected_file_keys) { %w[interval total_tuple_count max_batch_size] }

      before do
        # job_interval is skipped when testing
        queue_migration(migration_name, table_name, :id, :id, :data, batch_size: 100, job_interval: interval)
      end

      subject(:sample_migration) do
        described_class.new(result_dir: result_dir, connection: connection,
                            from_id: from_id).run_jobs(for_duration: 1.minute)
      end

      it 'runs sampled jobs from the batched background migration' do
        # Expect that running sampling for this migration processes some of the rows. Sampling doesn't run
        # over every row in the table, so this does not completely migrate the table.
        expect { subject }.to change {
                                define_batchable_model(table_name, connection: connection)
                                  .where('id IS DISTINCT FROM data').count
                              }.by_at_most(-1)
      end

      it 'uses the correct params to instrument the background migration' do
        expect_next_instance_of(Gitlab::Database::Migrations::Instrumentation) do |instrumentation|
          expect(instrumentation).to receive(:observe).with(hash_including(params)).at_least(:once).and_call_original
        end

        subject
      end

      it 'uses the filtering clause from the migration' do
        expect_next_instance_of(Gitlab::BackgroundMigration::BatchingStrategies::PrimaryKeyBatchingStrategy) do |s|
          expect(s).to receive(:filter_batch).at_least(:once).and_call_original
        end

        subject
      end

      it 'exports migration details to a file' do
        subject

        expect(json_file.keys).to match_array(expected_file_keys)
      end
    end

    context 'with jobs to run' do
      let(:migration_name) { 'TestBackgroundMigration' }

      it 'samples jobs' do
        calls = []
        define_background_migration(migration_name) do |*args|
          calls << args
        end

        queue_migration(migration_name, table_name, :id,
                        job_interval: 5.minutes,
                        batch_size: 100)

        described_class.new(result_dir: result_dir, connection: connection,
                            from_id: from_id).run_jobs(for_duration: 3.minutes)

        expect(calls).not_to be_empty
      end

      it 'samples 1 job with a batch size higher than the table size' do
        calls = []
        define_background_migration(migration_name) do |*args|
          travel 1.minute
          calls << args
        end

        queue_migration(migration_name, table_name, :id,
                        job_interval: 5.minutes,
                        batch_size: num_rows_in_table * 2,
                        sub_batch_size: num_rows_in_table * 2)

        described_class.new(result_dir: result_dir, connection: connection,
                            from_id: from_id).run_jobs(for_duration: 3.minutes)

        expect(calls.size).to eq(1)
      end

      context 'with multiple jobs to run' do
        let(:last_id) do
          Gitlab::Database::SharedModel.using_connection(connection) do
            Gitlab::Database::BackgroundMigration::BatchedMigration.maximum(:id)
          end
        end

        it 'runs all pending jobs based on the last migration id' do
          old_migration = define_background_migration(migration_name)
          queue_migration(migration_name, table_name, :id,
                          job_interval: 5.minutes,
                          batch_size: 100)

          last_id
          new_migration = define_background_migration('NewMigration') { travel 1.second }
          queue_migration('NewMigration', table_name, :id,
                          job_interval: 5.minutes,
                          batch_size: 10,
                          sub_batch_size: 5)

          other_new_migration = define_background_migration('NewMigration2') { travel 2.seconds }
          queue_migration('NewMigration2', table_name, :id,
                          job_interval: 5.minutes,
                          batch_size: 10,
                          sub_batch_size: 5)

          expect_migration_runs(new_migration => 3, other_new_migration => 2, old_migration => 0) do
            described_class.new(result_dir: result_dir, connection: connection,
                                from_id: last_id).run_jobs(for_duration: 5.seconds)
          end
        end
      end
    end

    context 'choosing uniform batches to run' do
      subject { described_class.new(result_dir: result_dir, connection: connection, from_id: from_id) }

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
end
