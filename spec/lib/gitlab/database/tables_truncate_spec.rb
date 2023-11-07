# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::TablesTruncate, :reestablished_active_record_base,
  :suppress_gitlab_schemas_validate_connection, feature_category: :cell do
  include MigrationsHelpers

  let(:min_batch_size) { 1 }
  let(:main_connection) { ApplicationRecord.connection }
  let(:ci_connection) { Ci::ApplicationRecord.connection }
  let(:logger) { instance_double(Logger) }

  # Main Database
  let(:main_db_main_item_model) { table("_test_gitlab_main_items", database: "main") }
  let(:main_db_main_reference_model) { table("_test_gitlab_main_references", database: "main") }
  let(:main_db_ci_item_model) { table("_test_gitlab_ci_items", database: "main") }
  let(:main_db_ci_reference_model) { table("_test_gitlab_ci_references", database: "main") }
  let(:main_db_shared_item_model) { table("_test_gitlab_shared_items", database: "main") }
  let(:main_db_partitioned_item) { table("_test_gitlab_hook_logs", database: "main") }
  let(:main_db_partitioned_item_detached) do
    table("gitlab_partitions_dynamic._test_gitlab_hook_logs_202201", database: "main")
  end

  # CI Database
  let(:ci_db_main_item_model) { table("_test_gitlab_main_items", database: "ci") }
  let(:ci_db_main_reference_model) { table("_test_gitlab_main_references", database: "ci") }
  let(:ci_db_ci_item_model) { table("_test_gitlab_ci_items", database: "ci") }
  let(:ci_db_ci_reference_model) { table("_test_gitlab_ci_references", database: "ci") }
  let(:ci_db_shared_item_model) { table("_test_gitlab_shared_items", database: "ci") }
  let(:ci_db_partitioned_item) { table("_test_gitlab_hook_logs", database: "ci") }
  let(:ci_db_partitioned_item_detached) do
    table("gitlab_partitions_dynamic._test_gitlab_hook_logs_202201", database: "ci")
  end

  before do
    skip_if_shared_database(:ci)

    # Creating some test tables on the main database
    main_tables_sql = <<~SQL
      CREATE TABLE _test_gitlab_main_items (id serial NOT NULL PRIMARY KEY);

      CREATE TABLE _test_gitlab_main_references (
        id serial NOT NULL PRIMARY KEY,
        item_id BIGINT NOT NULL,
        CONSTRAINT fk_constrained_1 FOREIGN KEY(item_id) REFERENCES _test_gitlab_main_items(id)
      );

      CREATE TABLE _test_gitlab_hook_logs (
        id bigserial not null,
        created_at timestamptz not null,
        item_id BIGINT NOT NULL,
        PRIMARY KEY (id, created_at),
        CONSTRAINT fk_constrained_1 FOREIGN KEY(item_id) REFERENCES _test_gitlab_main_items(id)
      ) PARTITION BY RANGE(created_at);

      CREATE TABLE gitlab_partitions_dynamic._test_gitlab_hook_logs_202201
      PARTITION OF _test_gitlab_hook_logs
      FOR VALUES FROM ('20220101') TO ('20220131');

      CREATE TABLE gitlab_partitions_dynamic._test_gitlab_hook_logs_202202
      PARTITION OF _test_gitlab_hook_logs
      FOR VALUES FROM ('20220201') TO ('20220228');

      ALTER TABLE _test_gitlab_hook_logs DETACH PARTITION gitlab_partitions_dynamic._test_gitlab_hook_logs_202201;
    SQL

    execute_on_each_database(main_tables_sql)

    ci_tables_sql = <<~SQL
      CREATE TABLE _test_gitlab_ci_items (id serial NOT NULL PRIMARY KEY);

      CREATE TABLE _test_gitlab_ci_references (
        id serial NOT NULL PRIMARY KEY,
        item_id BIGINT NOT NULL,
        CONSTRAINT fk_constrained_1 FOREIGN KEY(item_id) REFERENCES _test_gitlab_ci_items(id)
      );
    SQL

    execute_on_each_database(ci_tables_sql)

    internal_tables_sql = <<~SQL
      CREATE TABLE _test_gitlab_shared_items (id serial NOT NULL PRIMARY KEY);
    SQL

    execute_on_each_database(internal_tables_sql)

    # Filling the tables
    5.times do |i|
      # Main Database
      main_db_main_item_model.create!(id: i)
      main_db_main_reference_model.create!(item_id: i)
      main_db_ci_item_model.create!(id: i)
      main_db_ci_reference_model.create!(item_id: i)
      main_db_shared_item_model.create!(id: i)
      main_db_partitioned_item.create!(item_id: i, created_at: '2022-02-02 02:00')
      main_db_partitioned_item_detached.create!(item_id: i, created_at: '2022-01-01 01:00')
      # CI Database
      ci_db_main_item_model.create!(id: i)
      ci_db_main_reference_model.create!(item_id: i)
      ci_db_ci_item_model.create!(id: i)
      ci_db_ci_reference_model.create!(item_id: i)
      ci_db_shared_item_model.create!(id: i)
      ci_db_partitioned_item.create!(item_id: i, created_at: '2022-02-02 02:00')
      ci_db_partitioned_item_detached.create!(item_id: i, created_at: '2022-01-01 01:00')
    end

    Gitlab::Database::SharedModel.using_connection(main_connection) do
      Postgresql::DetachedPartition.create!(
        table_name: '_test_gitlab_hook_logs_202201',
        drop_after: Time.current
      )
    end

    Gitlab::Database::SharedModel.using_connection(ci_connection) do
      Postgresql::DetachedPartition.create!(
        table_name: '_test_gitlab_hook_logs_202201',
        drop_after: Time.current
      )
    end

    allow(Gitlab::Database::GitlabSchema).to receive(:tables_to_schema).and_return(
      {
        "_test_gitlab_main_items" => :gitlab_main,
        "_test_gitlab_main_references" => :gitlab_main,
        "_test_gitlab_hook_logs" => :gitlab_main,
        "_test_gitlab_ci_items" => :gitlab_ci,
        "_test_gitlab_ci_references" => :gitlab_ci,
        "_test_gitlab_shared_items" => :gitlab_shared,
        "_test_gitlab_geo_items" => :gitlab_geo
      }
    )

    allow(Gitlab::Database::GitlabSchema).to receive(:views_and_tables_to_schema).and_return(
      {
        "_test_gitlab_main_items" => :gitlab_main,
        "_test_gitlab_main_references" => :gitlab_main,
        "_test_gitlab_hook_logs" => :gitlab_main,
        "_test_gitlab_ci_items" => :gitlab_ci,
        "_test_gitlab_ci_references" => :gitlab_ci,
        "_test_gitlab_shared_items" => :gitlab_shared,
        "_test_gitlab_geo_items" => :gitlab_geo,
        "detached_partitions" => :gitlab_shared,
        "postgres_foreign_keys" => :gitlab_shared,
        "postgres_partitions" => :gitlab_shared
      }
    )

    allow(logger).to receive(:info).with(any_args)
  end

  shared_examples 'truncating legacy tables on a database' do
    let(:dry_run) { false }
    let(:until_table) { nil }

    subject(:truncate_legacy_tables) do
      described_class.new(
        database_name: connection.pool.db_config.name,
        min_batch_size: min_batch_size,
        logger: logger,
        dry_run: dry_run,
        until_table: until_table
      ).execute
    end

    context 'when the truncated tables are not locked for writes' do
      it 'raises an error that the tables are not locked for writes' do
        error_message = /is not locked for writes. Run the rake task gitlab:db:lock_writes first/
        expect { truncate_legacy_tables }.to raise_error(error_message)
      end
    end

    context 'when the truncated tables are locked for writes' do
      before do
        legacy_tables_models.map(&:table_name).each do |table|
          Gitlab::Database::LockWritesManager.new(
            table_name: table,
            connection: connection,
            database_name: connection.pool.db_config.name,
            with_retries: false
          ).lock_writes
        end
      end

      it 'truncates the legacy tables' do
        old_counts = legacy_tables_models.map(&:count)
        expect do
          truncate_legacy_tables
        end.to change { legacy_tables_models.map(&:count) }.from(old_counts).to([0] * legacy_tables_models.length)
      end

      it 'does not affect the other tables' do
        expect do
          truncate_legacy_tables
        end.not_to change { other_tables_models.map(&:count) }
      end

      it 'logs the sql statements to the logger' do
        expect(logger).to receive(:info).with("SET LOCAL lock_timeout = 0")
        expect(logger).to receive(:info).with("SET LOCAL statement_timeout = 0")
        expect(logger).to receive(:info)
                      .with(/TRUNCATE TABLE #{legacy_tables_models.map(&:table_name).sort.join(', ')} RESTRICT/)
        truncate_legacy_tables
      end

      context 'when running in dry_run mode' do
        let(:dry_run) { true }

        it 'does not truncate the legacy tables if running in dry run mode' do
          legacy_tables_models = [main_db_ci_reference_model, main_db_ci_reference_model]
          expect do
            truncate_legacy_tables
          end.not_to change { legacy_tables_models.map(&:count) }
        end
      end

      context 'when passing until_table parameter' do
        context 'with a table that exists' do
          let(:until_table) { referencing_table_model.table_name }

          it 'only truncates until the table specified' do
            expect do
              truncate_legacy_tables
            end.to change(referencing_table_model, :count).by(-5)
               .and change(referenced_table_model, :count).by(0)
          end
        end

        context 'with a table that does not exist' do
          let(:until_table) { 'foobar' }

          it 'raises an error if the specified table does not exist' do
            expect do
              truncate_legacy_tables
            end.to raise_error(/The table 'foobar' is not within the truncated tables/)
          end
        end
      end

      context 'when one of the attached partitions happened to be locked for writes' do
        before do
          skip if connection.pool.db_config.name != 'ci'

          Gitlab::Database::LockWritesManager.new(
            table_name: "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_gitlab_hook_logs_202202",
            connection: connection,
            database_name: connection.pool.db_config.name,
            with_retries: false
          ).lock_writes
        end

        it 'truncates the locked partition successfully' do
          expect do
            truncate_legacy_tables
          end.to change { ci_db_partitioned_item.count }.from(5).to(0)
        end
      end

      context 'with geo configured' do
        let(:geo_connection) { Gitlab::Database.database_base_models[:geo].connection }

        before do
          skip unless geo_configured?
          geo_connection.execute('CREATE TABLE _test_gitlab_geo_items (id serial NOT NULL PRIMARY KEY)')
          geo_connection.execute('INSERT INTO _test_gitlab_geo_items VALUES(generate_series(1, 50))')
        end

        it 'does not truncate gitlab_geo tables' do
          expect do
            truncate_legacy_tables
          end.not_to change { geo_connection.select_value("select count(*) from _test_gitlab_geo_items") }
        end
      end
    end
  end

  context 'when truncating gitlab_ci tables on the main database' do
    let(:connection) { ApplicationRecord.connection }
    let(:legacy_tables_models) { [main_db_ci_item_model, main_db_ci_reference_model] }
    let(:referencing_table_model) { main_db_ci_reference_model }
    let(:referenced_table_model) { main_db_ci_item_model }
    let(:other_tables_models) do
      [
        main_db_main_item_model, main_db_main_reference_model,
        ci_db_ci_item_model, ci_db_ci_reference_model,
        ci_db_main_item_model, ci_db_main_reference_model,
        main_db_shared_item_model, ci_db_shared_item_model
      ]
    end

    it_behaves_like 'truncating legacy tables on a database'
  end

  context 'when truncating gitlab_main tables on the ci database' do
    let(:connection) { Ci::ApplicationRecord.connection }
    let(:legacy_tables_models) do
      [ci_db_main_item_model, ci_db_main_reference_model, ci_db_partitioned_item, ci_db_partitioned_item_detached]
    end

    let(:referencing_table_model) { ci_db_main_reference_model }
    let(:referenced_table_model) { ci_db_main_item_model }
    let(:other_tables_models) do
      [
        main_db_main_item_model, main_db_main_reference_model,
        ci_db_ci_item_model, ci_db_ci_reference_model,
        main_db_ci_item_model, main_db_ci_reference_model,
        main_db_shared_item_model, ci_db_shared_item_model
      ]
    end

    it_behaves_like 'truncating legacy tables on a database'
  end

  context 'when running with multiple shared databases' do
    before do
      skip_if_multiple_databases_not_setup(:ci)
      skip_if_database_exists(:ci)
    end

    it 'raises an error when truncating the main database that it is a single database setup' do
      expect do
        described_class.new(database_name: 'main', min_batch_size: min_batch_size).execute
      end.to raise_error(/Cannot truncate legacy tables in single-db setup/)
    end

    it 'raises an error when truncating the ci database that it is a single database setup' do
      expect do
        described_class.new(database_name: 'ci', min_batch_size: min_batch_size).execute
      end.to raise_error(/Cannot truncate legacy tables in single-db setup/)
    end
  end

  context 'when running in a single database mode' do
    before do
      skip_if_multiple_databases_are_setup(:ci)
    end

    it 'raises an error when truncating the main database that it is a single database setup' do
      expect do
        described_class.new(database_name: 'main', min_batch_size: min_batch_size).execute
      end.to raise_error(/Cannot truncate legacy tables in single-db setup/)
    end

    it 'raises an error when truncating the ci database that it is a single database setup' do
      expect do
        described_class.new(database_name: 'ci', min_batch_size: min_batch_size).execute
      end.to raise_error(/Cannot truncate legacy tables in single-db setup/)
    end
  end

  describe '#needs_truncation?' do
    let(:database_name) { 'ci' }

    subject { described_class.new(database_name: database_name).needs_truncation? }

    context 'when running in a single database mode' do
      before do
        skip_if_multiple_databases_are_setup(:ci)
      end

      it { is_expected.to eq(false) }
    end

    context 'when running in a multiple database mode' do
      before do
        skip_if_shared_database(:ci)
      end

      context 'with main data in ci database' do
        it { is_expected.to eq(true) }
      end

      context 'with no main data in ci datatabase' do
        before do
          # Remove 'main' data in ci database
          ci_connection.execute(
            "TRUNCATE TABLE _test_gitlab_main_items, _test_gitlab_main_references RESTART IDENTITY CASCADE;"
          )
        end

        it { is_expected.to eq(false) }

        it 'supresses some QueryAnalyzers' do
          expect(
            Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection
          ).to receive(:with_suppressed).and_call_original
          expect(
            Gitlab::Database::QueryAnalyzers::Ci::PartitioningRoutingAnalyzer
          ).to receive(:with_suppressed).and_call_original

          subject
        end
      end
    end
  end

  def geo_configured?
    !!ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'geo')
  end
end
