# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::TablesLocker, :reestablished_active_record_base, :delete, :silence_stdout,
  :suppress_gitlab_schemas_validate_connection, feature_category: :pods do
  let(:detached_partition_table) { '_test_gitlab_main_part_20220101' }
  let(:lock_writes_manager) do
    instance_double(Gitlab::Database::LockWritesManager, lock_writes: nil, unlock_writes: nil)
  end

  before do
    allow(Gitlab::Database::LockWritesManager).to receive(:new).with(any_args).and_return(lock_writes_manager)
  end

  before(:all) do
    create_detached_partition_sql = <<~SQL
      CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic._test_gitlab_main_part_20220101 (
        id bigserial primary key not null
      )
    SQL

    ApplicationRecord.connection.execute(create_detached_partition_sql)
    Ci::ApplicationRecord.connection.execute(create_detached_partition_sql)

    Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
      Postgresql::DetachedPartition.create!(
        table_name: '_test_gitlab_main_part_20220101',
        drop_after: Time.current
      )
    end
  end

  after(:all) do
    drop_detached_partition_sql = <<~SQL
      DROP TABLE IF EXISTS gitlab_partitions_dynamic._test_gitlab_main_part_20220101
    SQL

    ApplicationRecord.connection.execute(drop_detached_partition_sql)
    Ci::ApplicationRecord.connection.execute(drop_detached_partition_sql)

    Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
      Postgresql::DetachedPartition.delete_all
    end
  end

  shared_examples "lock tables" do |table_schema, database_name|
    let(:table_name) do
      Gitlab::Database::GitlabSchema
      .tables_to_schema.filter_map { |table_name, schema| table_name if schema == table_schema }
      .first
    end

    let(:database) { database_name }

    it "locks table in schema #{table_schema} and database #{database_name}" do
      expect(Gitlab::Database::LockWritesManager).to receive(:new).with(
        table_name: table_name,
        connection: anything,
        database_name: database,
        with_retries: true,
        logger: anything,
        dry_run: anything
      ).once.and_return(lock_writes_manager)
      expect(lock_writes_manager).to receive(:lock_writes)

      subject
    end
  end

  shared_examples "unlock tables" do |table_schema, database_name|
    let(:table_name) do
      Gitlab::Database::GitlabSchema
      .tables_to_schema.filter_map { |table_name, schema| table_name if schema == table_schema }
      .first
    end

    let(:database) { database_name }

    it "unlocks table in schema #{table_schema} and database #{database_name}" do
      expect(Gitlab::Database::LockWritesManager).to receive(:new).with(
        table_name: table_name,
        connection: anything,
        database_name: database,
        with_retries: true,
        logger: anything,
        dry_run: anything
      ).once.and_return(lock_writes_manager)
      expect(lock_writes_manager).to receive(:unlock_writes)

      subject
    end
  end

  context 'when running on single database' do
    before do
      skip_if_multiple_databases_are_setup(:ci)
    end

    describe '#lock_writes' do
      subject { described_class.new.lock_writes }

      it 'does not call Gitlab::Database::LockWritesManager.lock_writes' do
        expect(Gitlab::Database::LockWritesManager).to receive(:new).with(any_args).and_return(lock_writes_manager)
        expect(lock_writes_manager).not_to receive(:lock_writes)

        subject
      end

      include_examples "unlock tables", :gitlab_main, 'main'
      include_examples "unlock tables", :gitlab_ci, 'ci'
      include_examples "unlock tables", :gitlab_shared, 'main'
      include_examples "unlock tables", :gitlab_internal, 'main'
    end

    describe '#unlock_writes' do
      subject { described_class.new.lock_writes }

      it 'does call Gitlab::Database::LockWritesManager.unlock_writes' do
        expect(Gitlab::Database::LockWritesManager).to receive(:new).with(any_args).and_return(lock_writes_manager)
        expect(lock_writes_manager).to receive(:unlock_writes)

        subject
      end
    end
  end

  context 'when running on multiple databases' do
    before do
      skip_if_multiple_databases_not_setup(:ci)
    end

    describe '#lock_writes' do
      subject { described_class.new.lock_writes }

      include_examples "lock tables", :gitlab_ci, 'main'
      include_examples "lock tables", :gitlab_main, 'ci'

      include_examples "unlock tables", :gitlab_main, 'main'
      include_examples "unlock tables", :gitlab_ci, 'ci'
      include_examples "unlock tables", :gitlab_shared, 'main'
      include_examples "unlock tables", :gitlab_shared, 'ci'
      include_examples "unlock tables", :gitlab_internal, 'main'
      include_examples "unlock tables", :gitlab_internal, 'ci'
    end

    describe '#unlock_writes' do
      subject { described_class.new.unlock_writes }

      include_examples "unlock tables", :gitlab_ci, 'main'
      include_examples "unlock tables", :gitlab_main, 'ci'
      include_examples "unlock tables", :gitlab_main, 'main'
      include_examples "unlock tables", :gitlab_ci, 'ci'
      include_examples "unlock tables", :gitlab_shared, 'main'
      include_examples "unlock tables", :gitlab_shared, 'ci'
      include_examples "unlock tables", :gitlab_internal, 'main'
      include_examples "unlock tables", :gitlab_internal, 'ci'
    end

    context 'when running in dry_run mode' do
      subject { described_class.new(dry_run: true).lock_writes }

      it 'passes dry_run flag to LockManger' do
        expect(Gitlab::Database::LockWritesManager).to receive(:new).with(
          table_name: 'users',
          connection: anything,
          database_name: 'ci',
          with_retries: true,
          logger: anything,
          dry_run: true
        ).and_return(lock_writes_manager)
        expect(lock_writes_manager).to receive(:lock_writes)

        subject
      end
    end

    context 'when running on multiple shared databases' do
      subject { described_class.new.lock_writes }

      before do
        allow(::Gitlab::Database).to receive(:db_config_share_with).and_return(nil)
        ci_db_config = Ci::ApplicationRecord.connection_db_config
        allow(::Gitlab::Database).to receive(:db_config_share_with).with(ci_db_config).and_return('main')
      end

      it 'does not lock any tables if the ci database is shared with main database' do
        expect(Gitlab::Database::LockWritesManager).to receive(:new).with(any_args).and_return(lock_writes_manager)
        expect(lock_writes_manager).not_to receive(:lock_writes)

        subject
      end
    end
  end

  context 'when geo database is configured' do
    let(:geo_table) do
      Gitlab::Database::GitlabSchema
        .tables_to_schema.filter_map { |table_name, schema| table_name if schema == :gitlab_geo }
        .first
    end

    subject { described_class.new.unlock_writes }

    before do
      skip "Geo database is not configured" unless Gitlab::Database.has_config?(:geo)
    end

    it 'does not lock table in geo database' do
      expect(Gitlab::Database::LockWritesManager).not_to receive(:new).with(
        table_name: geo_table,
        connection: anything,
        database_name: 'geo',
        with_retries: true,
        logger: anything,
        dry_run: anything
      )

      subject
    end
  end
end

def number_of_triggers(connection)
  connection.select_value("SELECT count(*) FROM information_schema.triggers")
end
