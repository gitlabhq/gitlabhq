# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Cursor based batched background migrations', feature_category: :database do
  include Gitlab::Database::DynamicModelHelpers
  let(:connection) { ApplicationRecord.connection }
  let(:table_name) { :_test_cursor_batching }
  let(:model) { define_batchable_model(table_name, connection: connection) }
  let(:batching_strategy) { Gitlab::BackgroundMigration::BatchingStrategies::PrimaryKeyBatchingStrategy }
  let(:batching_strategy_name) { batching_strategy.name.demodulize }

  let(:background_migration_job_class) do
    stub_const('Gitlab::BackgroundMigration::TestCursorMigration',
      Class.new(Gitlab::BackgroundMigration::BatchedMigrationJob) do
        cursor :id_a, :id_b

        def perform
          each_sub_batch do |relation|
            # Want to relation.update_all(backfilled: )
            # But rails doesn't know what to use as the primary key when transforming that to
            #   UPDATE .. WHERE <pk> IN (subquery) because the primary key is composite
            # So it generates invalid sql UPDATE ... WHERE <table_name>."" IN (subquery)
            # Instead build our own
            connection.execute(<<~SQL)
              UPDATE #{batch_table}
              SET backfilled = backfilled + 1
              WHERE (id_a, id_b) IN (#{relation.select(:id_a, :id_b).to_sql})
            SQL
          end
        end
      end
    )
  end

  let(:background_migration_name) { background_migration_job_class.name.demodulize }

  before do
    connection.execute(<<~SQL)
      create table _test_cursor_batching (
        id_a bigint not null,
        id_b bigint not null,
        backfilled int not null default 0,
        primary key (id_a, id_b)
      );
      insert into _test_cursor_batching(id_a, id_b)
      select i / 10, i % 10
      from generate_series(1, 1000) g(i);
    SQL
  end

  context 'when running a real cursor-based batched background migration' do
    let(:strategy_instance) { batching_strategy.new(connection: connection) }
    let(:migration) do
      create(:batched_background_migration, :active,
        job_class_name: background_migration_name,
        batch_class_name: batching_strategy_name,
        table_name: table_name,
        batch_size: 10,
        sub_batch_size: 5,
        pause_ms: 0,
        min_cursor: [0, 0],
        max_cursor: [100, 9]
      )
    end

    let(:runner) { Gitlab::Database::BackgroundMigration::BatchedMigrationRunner.new(connection: connection) }

    it 'migrates correctly' do
      runner.run_entire_migration(migration)
      expect(model.where(backfilled: 1).count).to eq(model.count)

      unless migration.batched_jobs.count == 100
        migration.batched_jobs.find_each do |job|
          puts job.inspect
        end
      end

      expect(migration.batched_jobs.count).to eq(100)
    end

    context 'when the last batch only has one row' do
      let(:migration) do
        create(:batched_background_migration, :active,
          job_class_name: background_migration_name,
          batch_class_name: batching_strategy_name,
          table_name: table_name,
          batch_size: 10,
          sub_batch_size: 1,
          pause_ms: 0,
          min_cursor: [98, 9],
          max_cursor: [100, 1]
        )
      end

      it 'migrates correctly' do
        runner.run_entire_migration(migration)
        expect(model.where(backfilled: 1).count).to eq(11)
        expect(migration.batched_jobs.count).to eq(2)
      end
    end
  end
end
