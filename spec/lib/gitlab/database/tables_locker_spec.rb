# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::TablesLocker, :suppress_gitlab_schemas_validate_connection, :silence_stdout,
  feature_category: :cell do
  let(:default_lock_writes_manager) do
    instance_double(
      Gitlab::Database::LockWritesManager,
      lock_writes: { action: 'any action' },
      unlock_writes: { action: 'unlocked' }
    )
  end

  before do
    allow(Gitlab::Database::LockWritesManager).to receive(:new).with(any_args).and_return(default_lock_writes_manager)
    # Limiting the scope of the tests to a subset of the database tables
    allow(Gitlab::Database::GitlabSchema).to receive(:tables_to_schema).and_return({
      'application_setttings' => :gitlab_main_clusterwide,
      'projects' => :gitlab_main,
      'zoekt_tasks' => :gitlab_main,
      'ci_builds' => :gitlab_ci,
      'ci_jobs' => :gitlab_ci,
      'loose_foreign_keys_deleted_records' => :gitlab_shared,
      'ar_internal_metadata' => :gitlab_internal
    })
  end

  before(:all) do
    create_partition_sql = <<~SQL
      CREATE TABLE IF NOT EXISTS #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.zoekt_tasks_test_partition
      PARTITION OF zoekt_tasks
      FOR VALUES IN (0)
    SQL

    create_detached_partition_sql = <<~SQL
      CREATE TABLE IF NOT EXISTS #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_gitlab_main_part_202201 (
        id bigserial primary key not null
      )
    SQL

    ::Gitlab::Database.database_base_models_with_gitlab_shared.values
      .map(&:connection)
      .each do |conn|
        conn.execute(create_partition_sql)
        conn.execute(
          "DROP TABLE IF EXISTS #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_gitlab_main_part_202201"
        )
        conn.execute(create_detached_partition_sql)

        Gitlab::Database::SharedModel.using_connection(conn) do
          Postgresql::DetachedPartition.delete_all
          Postgresql::DetachedPartition.create!(
            table_name: '_test_gitlab_main_part_20220101',
            drop_after: Time.current
          )
        end
      end
  end

  after(:all) do
    ::Gitlab::Database.database_base_models_with_gitlab_shared.values
      .map(&:connection)
      .each do |conn|
        conn.execute(
          "DROP TABLE IF EXISTS #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_gitlab_main_part_202201"
        )
        Gitlab::Database::SharedModel.using_connection(conn) { Postgresql::DetachedPartition.delete_all }
      end
  end

  shared_examples "lock tables" do |gitlab_schema, database_name|
    let(:connection) { Gitlab::Database.database_base_models[database_name].connection }
    let(:tables_to_lock) do
      Gitlab::Database::GitlabSchema
        .tables_to_schema.filter_map { |table_name, schema| table_name if schema == gitlab_schema }
    end

    it "locks table in schema #{gitlab_schema} and database #{database_name}" do
      expect(tables_to_lock).not_to be_empty

      tables_to_lock.each do |table_name|
        lock_writes_manager = instance_double(Gitlab::Database::LockWritesManager, lock_writes: nil)

        expect(Gitlab::Database::LockWritesManager).to receive(:new).with(
          table_name: table_name,
          connection: connection,
          database_name: database_name,
          with_retries: true,
          logger: anything,
          dry_run: anything
        ).once.and_return(lock_writes_manager)
        expect(lock_writes_manager).to receive(:lock_writes).once
      end

      subject
    end

    it 'returns list of actions' do
      expect(subject).to include({ action: 'any action' })
    end
  end

  shared_examples "unlock tables" do |gitlab_schema, database_name|
    let(:connection) { Gitlab::Database.database_base_models[database_name].connection }

    let(:tables_to_unlock) do
      Gitlab::Database::GitlabSchema
        .tables_to_schema.filter_map { |table_name, schema| table_name if schema == gitlab_schema }
    end

    it "unlocks table in schema #{gitlab_schema} and database #{database_name}" do
      expect(tables_to_unlock).not_to be_empty

      tables_to_unlock.each do |table_name|
        lock_writes_manager = instance_double(Gitlab::Database::LockWritesManager, unlock_writes: nil)

        expect(Gitlab::Database::LockWritesManager).to receive(:new).with(
          table_name: table_name,
          connection: anything,
          database_name: database_name,
          with_retries: true,
          logger: anything,
          dry_run: anything
        ).once.and_return(lock_writes_manager)
        expect(lock_writes_manager).to receive(:unlock_writes)
      end

      subject
    end

    it 'returns list of actions' do
      expect(subject).to include({ action: 'unlocked' })
    end
  end

  shared_examples "lock partitions" do |partition_identifier, database_name|
    let(:connection) { Gitlab::Database.database_base_models[database_name].connection }

    it 'locks the partition' do
      lock_writes_manager = instance_double(Gitlab::Database::LockWritesManager, lock_writes: nil)

      expect(Gitlab::Database::LockWritesManager).to receive(:new).with(
        table_name: partition_identifier,
        connection: connection,
        database_name: database_name,
        with_retries: true,
        logger: anything,
        dry_run: anything
      ).once.and_return(lock_writes_manager)
      expect(lock_writes_manager).to receive(:lock_writes)

      subject
    end
  end

  shared_examples "unlock partitions" do |partition_identifier, database_name|
    let(:connection) { Gitlab::Database.database_base_models[database_name].connection }

    it 'unlocks the partition' do
      lock_writes_manager = instance_double(Gitlab::Database::LockWritesManager, unlock_writes: nil)

      expect(Gitlab::Database::LockWritesManager).to receive(:new).with(
        table_name: partition_identifier,
        connection: connection,
        database_name: database_name,
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
      skip_if_database_exists(:ci)
      skip_if_database_exists(:sec)
    end

    describe '#lock_writes' do
      subject { described_class.new.lock_writes }

      it 'does not lock any table' do
        expect(Gitlab::Database::LockWritesManager).to receive(:new)
          .with(any_args).and_return(default_lock_writes_manager)
        expect(default_lock_writes_manager).not_to receive(:lock_writes)

        subject
      end

      it_behaves_like 'unlock tables', :gitlab_main, 'main'
      it_behaves_like 'unlock tables', :gitlab_ci, 'main'
      it_behaves_like 'unlock tables', :gitlab_main_clusterwide, 'main'
      it_behaves_like 'unlock tables', :gitlab_shared, 'main'
      it_behaves_like 'unlock tables', :gitlab_internal, 'main'
    end

    describe '#unlock_writes' do
      subject { described_class.new.lock_writes }

      it 'does call Gitlab::Database::LockWritesManager.unlock_writes' do
        expect(Gitlab::Database::LockWritesManager).to receive(:new)
          .with(any_args).and_return(default_lock_writes_manager)
        expect(default_lock_writes_manager).to receive(:unlock_writes)
        expect(default_lock_writes_manager).not_to receive(:lock_writes)

        subject
      end
    end
  end

  context 'when running on multiple databases' do
    before do
      skip_if_shared_database(:ci)
    end

    describe '#lock_writes' do
      subject { described_class.new.lock_writes }

      it_behaves_like 'lock tables', :gitlab_ci, 'main'
      it_behaves_like 'lock tables', :gitlab_main, 'ci'
      it_behaves_like 'lock tables', :gitlab_main_clusterwide, 'ci'

      it_behaves_like 'unlock tables', :gitlab_main_clusterwide, 'main'
      it_behaves_like 'unlock tables', :gitlab_main, 'main'
      it_behaves_like 'unlock tables', :gitlab_ci, 'ci'
      it_behaves_like 'unlock tables', :gitlab_shared, 'main'
      it_behaves_like 'unlock tables', :gitlab_shared, 'ci'
      it_behaves_like 'unlock tables', :gitlab_internal, 'main'
      it_behaves_like 'unlock tables', :gitlab_internal, 'ci'

      gitlab_main_partition = "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.zoekt_tasks_test_partition"
      it_behaves_like 'unlock partitions', gitlab_main_partition, 'main'
      it_behaves_like 'lock partitions', gitlab_main_partition, 'ci'

      gitlab_main_detached_partition = "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_gitlab_main_part_20220101"
      it_behaves_like 'unlock partitions', gitlab_main_detached_partition, 'main'
      it_behaves_like 'lock partitions', gitlab_main_detached_partition, 'ci'
    end

    describe '#unlock_writes' do
      subject { described_class.new.unlock_writes }

      it_behaves_like "unlock tables", :gitlab_ci, 'main'
      it_behaves_like "unlock tables", :gitlab_main, 'ci'
      it_behaves_like "unlock tables", :gitlab_main, 'main'
      it_behaves_like "unlock tables", :gitlab_ci, 'ci'
      it_behaves_like "unlock tables", :gitlab_shared, 'main'
      it_behaves_like "unlock tables", :gitlab_shared, 'ci'
      it_behaves_like "unlock tables", :gitlab_internal, 'main'
      it_behaves_like "unlock tables", :gitlab_internal, 'ci'

      gitlab_main_partition = "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.zoekt_tasks_test_partition"
      it_behaves_like 'unlock partitions', gitlab_main_partition, 'main'
      it_behaves_like 'unlock partitions', gitlab_main_partition, 'ci'

      gitlab_main_detached_partition = "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_gitlab_main_part_20220101"
      it_behaves_like 'unlock partitions', gitlab_main_detached_partition, 'main'
      it_behaves_like 'unlock partitions', gitlab_main_detached_partition, 'ci'
    end

    context 'when not including partitions' do
      subject { described_class.new(include_partitions: false).lock_writes }

      it 'does not include any table partitions' do
        gitlab_main_partition = "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.zoekt_tasks_test_partition"

        expect(Gitlab::Database::LockWritesManager).not_to receive(:new).with(
          hash_including(table_name: gitlab_main_partition)
        )

        subject
      end

      it 'does not include any detached partitions' do
        detached_partition_name = "_test_gitlab_main_part_20220101"
        gitlab_main_detached_partition = "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{detached_partition_name}"

        expect(Gitlab::Database::LockWritesManager).not_to receive(:new).with(
          hash_including(table_name: gitlab_main_detached_partition)
        )

        subject
      end
    end

    context 'when running in dry_run mode' do
      subject { described_class.new(dry_run: true).lock_writes }

      it 'passes dry_run flag to LockWritesManager' do
        expect(Gitlab::Database::LockWritesManager).to receive(:new).with(
          table_name: 'zoekt_tasks',
          connection: anything,
          database_name: 'ci',
          with_retries: true,
          logger: anything,
          dry_run: true
        ).and_return(default_lock_writes_manager)
        expect(default_lock_writes_manager).to receive(:lock_writes)

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
        expect(Gitlab::Database::LockWritesManager).to receive(:new)
          .with(any_args).and_return(default_lock_writes_manager)
        expect(default_lock_writes_manager).not_to receive(:lock_writes)

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

  context 'when sec database is configured' do
    let(:sec_table) do
      Gitlab::Database::GitlabSchema
        .tables_to_schema.filter_map { |table_name, schema| table_name if schema == :gitlab_sec }
        .first
    end

    subject { described_class.new.unlock_writes }

    before do
      skip_if_shared_database(:sec)
    end

    it 'does not lock table in sec database' do
      expect(Gitlab::Database::LockWritesManager).not_to receive(:new).with(
        table_name: sec_table,
        connection: anything,
        database_name: 'sec',
        with_retries: true,
        logger: anything,
        dry_run: anything
      )

      subject
    end
  end
end
