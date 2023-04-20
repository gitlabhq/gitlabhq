# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::V2 do
  include Database::TriggerHelpers
  include Database::TableSchemaHelpers

  let(:migration) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  before do
    allow(migration).to receive(:puts)

    allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)
  end

  shared_examples_for 'Setting up to rename a column' do
    let(:model) { Class.new(ActiveRecord::Base) }

    before do
      model.table_name = :_test_table
    end

    context 'when called inside a transaction block' do
      before do
        allow(migration).to receive(:transaction_open?).and_return(true)
      end

      it 'raises an error' do
        expect do
          migration.public_send(operation, :_test_table, :original, :renamed)
        end.to raise_error("#{operation} can not be run inside a transaction")
      end
    end

    context 'when the existing column has a default function' do
      before do
        migration.change_column_default :_test_table, existing_column, -> { 'now()' }
      end

      it 'raises an error' do
        expect do
          migration.public_send(operation, :_test_table, :original, :renamed)
        end.to raise_error("#{operation} does not currently support columns with default functions")
      end
    end

    context 'when passing a batch column' do
      context 'when the batch column does not exist' do
        it 'raises an error' do
          expect do
            migration.public_send(operation, :_test_table, :original, :renamed, batch_column_name: :missing)
          end.to raise_error('Column missing does not exist on _test_table')
        end
      end

      context 'when the batch column does exist' do
        it 'passes it when creating the column' do
          expect(migration).to receive(:create_column_from)
            .with(:_test_table, existing_column, added_column, type: nil, batch_column_name: :status)
            .and_call_original

          migration.public_send(operation, :_test_table, :original, :renamed, batch_column_name: :status)
        end
      end
    end

    context 'when the existing column has a default value' do
      before do
        migration.change_column_default :_test_table, existing_column, 'default value'
      end

      it 'creates the renamed column, syncing existing data' do
        existing_record_1 = model.create!(status: 0, existing_column => 'existing')
        existing_record_2 = model.create!(status: 0)

        migration.send(operation, :_test_table, :original, :renamed)
        model.reset_column_information

        expect(migration.column_exists?(:_test_table, added_column)).to eq(true)

        expect(existing_record_1.reload).to have_attributes(status: 0, original: 'existing', renamed: 'existing')
        expect(existing_record_2.reload).to have_attributes(status: 0, original: 'default value', renamed: 'default value')
      end

      it 'installs triggers to sync new data' do
        migration.public_send(operation, :_test_table, :original, :renamed)
        model.reset_column_information

        new_record_1 = model.create!(status: 1, original: 'first')
        new_record_2 = model.create!(status: 1, renamed: 'second')
        new_record_3 = model.create!(status: 1)
        new_record_4 = model.create!(status: 1)

        expect(new_record_1.reload).to have_attributes(status: 1, original: 'first', renamed: 'first')
        expect(new_record_2.reload).to have_attributes(status: 1, original: 'second', renamed: 'second')
        expect(new_record_3.reload).to have_attributes(status: 1, original: 'default value', renamed: 'default value')
        expect(new_record_4.reload).to have_attributes(status: 1, original: 'default value', renamed: 'default value')

        new_record_1.update!(original: 'updated')
        new_record_2.update!(renamed: nil)
        new_record_3.update!(renamed: 'update renamed')
        new_record_4.update!(original: 'update original')

        expect(new_record_1.reload).to have_attributes(status: 1, original: 'updated', renamed: 'updated')
        expect(new_record_2.reload).to have_attributes(status: 1, original: nil, renamed: nil)
        expect(new_record_3.reload).to have_attributes(status: 1, original: 'update renamed', renamed: 'update renamed')
        expect(new_record_4.reload).to have_attributes(status: 1, original: 'update original', renamed: 'update original')
      end
    end

    context 'when the existing column has a default value that evaluates to NULL' do
      before do
        migration.change_column_default :_test_table, existing_column, -> { "('test' || null)" }
      end

      it 'creates the renamed column, syncing existing data' do
        existing_record_1 = model.create!(status: 0, existing_column => 'existing')
        existing_record_2 = model.create!(status: 0)

        migration.send(operation, :_test_table, :original, :renamed)
        model.reset_column_information

        expect(migration.column_exists?(:_test_table, added_column)).to eq(true)

        expect(existing_record_1.reload).to have_attributes(status: 0, original: 'existing', renamed: 'existing')
        expect(existing_record_2.reload).to have_attributes(status: 0, original: nil, renamed: nil)
      end

      it 'installs triggers to sync new data' do
        migration.public_send(operation, :_test_table, :original, :renamed)
        model.reset_column_information

        new_record_1 = model.create!(status: 1, original: 'first')
        new_record_2 = model.create!(status: 1, renamed: 'second')
        new_record_3 = model.create!(status: 1)
        new_record_4 = model.create!(status: 1)

        expect(new_record_1.reload).to have_attributes(status: 1, original: 'first', renamed: 'first')
        expect(new_record_2.reload).to have_attributes(status: 1, original: 'second', renamed: 'second')
        expect(new_record_3.reload).to have_attributes(status: 1, original: nil, renamed: nil)
        expect(new_record_4.reload).to have_attributes(status: 1, original: nil, renamed: nil)

        new_record_1.update!(original: 'updated')
        new_record_2.update!(renamed: nil)
        new_record_3.update!(renamed: 'update renamed')
        new_record_4.update!(original: 'update original')

        expect(new_record_1.reload).to have_attributes(status: 1, original: 'updated', renamed: 'updated')
        expect(new_record_2.reload).to have_attributes(status: 1, original: nil, renamed: nil)
        expect(new_record_3.reload).to have_attributes(status: 1, original: 'update renamed', renamed: 'update renamed')
        expect(new_record_4.reload).to have_attributes(status: 1, original: 'update original', renamed: 'update original')
      end
    end

    it 'creates the renamed column, syncing existing data' do
      existing_record_1 = model.create!(status: 0, existing_column => 'existing')
      existing_record_2 = model.create!(status: 0, existing_column => nil)

      migration.send(operation, :_test_table, :original, :renamed)
      model.reset_column_information

      expect(migration.column_exists?(:_test_table, added_column)).to eq(true)

      expect(existing_record_1.reload).to have_attributes(status: 0, original: 'existing', renamed: 'existing')
      expect(existing_record_2.reload).to have_attributes(status: 0, original: nil, renamed: nil)
    end

    it 'installs triggers to sync new data' do
      migration.public_send(operation, :_test_table, :original, :renamed)
      model.reset_column_information

      new_record_1 = model.create!(status: 1, original: 'first')
      new_record_2 = model.create!(status: 1, renamed: 'second')

      expect(new_record_1.reload).to have_attributes(status: 1, original: 'first', renamed: 'first')
      expect(new_record_2.reload).to have_attributes(status: 1, original: 'second', renamed: 'second')

      new_record_1.update!(original: 'updated')
      new_record_2.update!(renamed: nil)

      expect(new_record_1.reload).to have_attributes(status: 1, original: 'updated', renamed: 'updated')
      expect(new_record_2.reload).to have_attributes(status: 1, original: nil, renamed: nil)
    end

    it 'requires the helper to run in ddl mode' do
      expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_ddl_mode!)

      migration.public_send(operation, :_test_table, :original, :renamed)
    end
  end

  describe '#rename_column_concurrently' do
    before do
      allow(migration).to receive(:transaction_open?).and_return(false)

      migration.create_table :_test_table do |t|
        t.integer :status, null: false
        t.text :original
        t.text :other_column
      end
    end

    it_behaves_like 'Setting up to rename a column' do
      let(:operation) { :rename_column_concurrently }
      let(:existing_column) { :original }
      let(:added_column) { :renamed }
    end

    context 'when the column to rename does not exist' do
      it 'raises an error' do
        expect do
          migration.rename_column_concurrently :_test_table, :missing_column, :renamed
        end.to raise_error('Column missing_column does not exist on _test_table')
      end
    end
  end

  describe '#undo_cleanup_concurrent_column_rename' do
    before do
      allow(migration).to receive(:transaction_open?).and_return(false)

      migration.create_table :_test_table do |t|
        t.integer :status, null: false
        t.text :other_column
        t.text :renamed
      end
    end

    it_behaves_like 'Setting up to rename a column' do
      let(:operation) { :undo_cleanup_concurrent_column_rename }
      let(:existing_column) { :renamed }
      let(:added_column) { :original }
    end

    context 'when the renamed column does not exist' do
      it 'raises an error' do
        expect do
          migration.undo_cleanup_concurrent_column_rename :_test_table, :original, :missing_column
        end.to raise_error('Column missing_column does not exist on _test_table')
      end
    end
  end

  shared_examples_for 'Cleaning up from renaming a column' do
    let(:connection) { migration.connection }

    before do
      allow(migration).to receive(:transaction_open?).and_return(false)

      migration.create_table :_test_table do |t|
        t.integer :status, null: false
        t.text :original
        t.text :other_column
      end

      migration.rename_column_concurrently :_test_table, :original, :renamed
    end

    context 'when the helper is called repeatedly' do
      before do
        migration.public_send(operation, :_test_table, :original, :renamed)
      end

      it 'does not make repeated attempts to cleanup' do
        expect(migration).not_to receive(:remove_column)

        expect do
          migration.public_send(operation, :_test_table, :original, :renamed)
        end.not_to raise_error
      end
    end

    context 'when the renamed column exists' do
      let(:triggers) do
        [
          ['trigger_020dbcb8cdd0', 'function_for_trigger_020dbcb8cdd0', before: 'insert'],
          ['trigger_6edaca641d03', 'function_for_trigger_6edaca641d03', before: 'update'],
          ['trigger_a3fb9f3add34', 'function_for_trigger_a3fb9f3add34', before: 'update']
        ]
      end

      it 'removes the sync triggers and renamed columns' do
        triggers.each do |(trigger_name, function_name, event)|
          expect_function_to_exist(function_name)
          expect_valid_function_trigger(:_test_table, trigger_name, function_name, event)
        end

        expect(migration.column_exists?(:_test_table, added_column)).to eq(true)

        migration.public_send(operation, :_test_table, :original, :renamed)

        expect(migration.column_exists?(:_test_table, added_column)).to eq(false)

        triggers.each do |(trigger_name, function_name, _)|
          expect_trigger_not_to_exist(:_test_table, trigger_name)
          expect_function_not_to_exist(function_name)
        end
      end
    end
  end

  describe '#undo_rename_column_concurrently' do
    it_behaves_like 'Cleaning up from renaming a column' do
      let(:operation) { :undo_rename_column_concurrently }
      let(:added_column) { :renamed }
    end
  end

  describe '#cleanup_concurrent_column_rename' do
    it_behaves_like 'Cleaning up from renaming a column' do
      let(:operation) { :cleanup_concurrent_column_rename }
      let(:added_column) { :original }
    end
  end

  describe '#create_table' do
    let(:table_name) { :_test_table }
    let(:column_attributes) do
      [
        { name: 'id',         sql_type: 'bigint',                   null: false, default: nil    },
        { name: 'created_at', sql_type: 'timestamp with time zone', null: false, default: nil    },
        { name: 'updated_at', sql_type: 'timestamp with time zone', null: false, default: nil    },
        { name: 'some_id',    sql_type: 'integer',                  null: false, default: nil    },
        { name: 'active',     sql_type: 'boolean',                  null: false, default: 'true' },
        { name: 'name',       sql_type: 'text',                     null: true,  default: nil    }
      ]
    end

    context 'using a limit: attribute on .text' do
      it 'creates the table as expected' do
        migration.create_table table_name do |t|
          t.timestamps_with_timezone
          t.integer :some_id, null: false
          t.boolean :active, null: false, default: true
          t.text :name, limit: 100
        end

        expect_table_columns_to_match(column_attributes, table_name)
        expect_check_constraint(table_name, 'check_e9982cf9da', 'char_length(name) <= 100')
      end
    end
  end

  describe '#with_lock_retries' do
    let(:model) do
      ActiveRecord::Migration.new.extend(described_class)
    end

    let(:buffer) { StringIO.new }
    let(:in_memory_logger) { Gitlab::JsonLogger.new(buffer) }
    let(:env) { { 'DISABLE_LOCK_RETRIES' => 'true' } }

    it 'sets the migration class name in the logs' do
      model.with_lock_retries(env: env, logger: in_memory_logger) {}

      buffer.rewind
      expect(buffer.read).to include("\"class\":\"#{model.class}\"")
    end

    where(raise_on_exhaustion: [true, false])

    with_them do
      it 'sets raise_on_exhaustion as requested' do
        with_lock_retries = double
        expect(Gitlab::Database::WithLockRetries).to receive(:new).and_return(with_lock_retries)
        expect(with_lock_retries).to receive(:run).with(raise_on_exhaustion: raise_on_exhaustion)

        model.with_lock_retries(env: env, logger: in_memory_logger, raise_on_exhaustion: raise_on_exhaustion) {}
      end
    end

    it 'does not raise on exhaustion by default' do
      with_lock_retries = double
      expect(Gitlab::Database::WithLockRetries).to receive(:new).and_return(with_lock_retries)
      expect(with_lock_retries).to receive(:run).with(raise_on_exhaustion: false)

      model.with_lock_retries(env: env, logger: in_memory_logger) {}
    end

    it 'defaults to disallowing subtransactions' do
      with_lock_retries = double
      expect(Gitlab::Database::WithLockRetries).to receive(:new).with(hash_including(allow_savepoints: false)).and_return(with_lock_retries)
      expect(with_lock_retries).to receive(:run).with(raise_on_exhaustion: false)

      model.with_lock_retries(env: env, logger: in_memory_logger) {}
    end

    context 'when in transaction' do
      before do
        allow(model).to receive(:transaction_open?).and_return(true)
      end

      context 'when lock retries are enabled' do
        before do
          allow(model).to receive(:enable_lock_retries?).and_return(true)
        end

        it 'does not use Gitlab::Database::WithLockRetries and executes the provided block directly' do
          expect(Gitlab::Database::WithLockRetries).not_to receive(:new)

          expect(model.with_lock_retries(env: env, logger: in_memory_logger) { :block_result }).to eq(:block_result)
        end
      end

      context 'when lock retries are not enabled' do
        before do
          allow(model).to receive(:enable_lock_retries?).and_return(false)
        end

        it 'raises an error' do
          expect { model.with_lock_retries(env: env, logger: in_memory_logger) {} }.to raise_error /can not be run inside an already open transaction/
        end
      end
    end
  end

  describe '#truncate_tables!' do
    before do
      ApplicationRecord.connection.execute(<<~SQL)
        CREATE TABLE _test_gitlab_main_table (id serial primary key);
        CREATE TABLE _test_gitlab_main_table2 (id serial primary key);

        INSERT INTO _test_gitlab_main_table DEFAULT VALUES;
        INSERT INTO _test_gitlab_main_table2 DEFAULT VALUES;
      SQL

      Ci::ApplicationRecord.connection.execute(<<~SQL)
        CREATE TABLE _test_gitlab_ci_table (id serial primary key);
      SQL
    end

    it 'truncates the table' do
      expect(migration).to receive(:execute).with('TRUNCATE TABLE "_test_gitlab_main_table"').and_call_original

      expect { migration.truncate_tables!('_test_gitlab_main_table') }
        .to change { ApplicationRecord.connection.select_value('SELECT count(1) from _test_gitlab_main_table') }.to(0)
    end

    it 'truncates multiple tables' do
      expect(migration).to receive(:execute).with('TRUNCATE TABLE "_test_gitlab_main_table", "_test_gitlab_main_table2"').and_call_original

      expect { migration.truncate_tables!('_test_gitlab_main_table', '_test_gitlab_main_table2') }
        .to change { ApplicationRecord.connection.select_value('SELECT count(1) from _test_gitlab_main_table') }.to(0)
        .and change { ApplicationRecord.connection.select_value('SELECT count(1) from _test_gitlab_main_table2') }.to(0)
    end

    it 'raises an ArgumentError if truncating multiple gitlab_schema' do
      expect do
        migration.truncate_tables!('_test_gitlab_main_table', '_test_gitlab_ci_table')
      end.to raise_error(ArgumentError, /one `gitlab_schema`/)
    end

    context 'with multiple databases' do
      before do
        skip_if_shared_database(:ci)
      end

      context 'for ci database' do
        before do
          migration.instance_variable_set :@connection, Ci::ApplicationRecord.connection
        end

        it 'skips the TRUNCATE statement tables not in schema for connection' do
          expect(migration).not_to receive(:execute)

          migration.truncate_tables!('_test_gitlab_main_table')
        end
      end

      context 'for main database' do
        before do
          migration.instance_variable_set :@connection, ApplicationRecord.connection
        end

        it 'executes a TRUNCATE statement' do
          expect(migration).to receive(:execute).with('TRUNCATE TABLE "_test_gitlab_main_table"')

          migration.truncate_tables!('_test_gitlab_main_table')
        end
      end
    end

    context 'with single database' do
      before do
        skip_if_database_exists(:ci)
      end

      it 'executes a TRUNCATE statement' do
        expect(migration).to receive(:execute).with('TRUNCATE TABLE "_test_gitlab_main_table"')

        migration.truncate_tables!('_test_gitlab_main_table')
      end
    end
  end
end
