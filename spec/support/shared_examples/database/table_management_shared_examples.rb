# frozen_string_literal: true

RSpec.shared_examples "a measurable object" do
  let(:part_type) { :range }

  context 'when the table is not allowed' do
    let(:source_table) { :_test_this_table_is_not_allowed }

    it 'raises an error' do
      expect(migration).to receive(:assert_table_is_allowed).with(source_table).and_call_original

      expect do
        subject
      end.to raise_error(/#{source_table} is not allowed for use/)
    end
  end

  context 'when run inside a transaction block' do
    it 'raises an error' do
      expect(migration).to receive(:transaction_open?).and_return(true)

      expect do
        subject
      end.to raise_error(/can not be run inside a transaction/)
    end
  end

  context 'when the given table does not have a primary key' do
    it 'raises an error' do
      migration.execute(<<~SQL)
        ALTER TABLE #{source_table}
        DROP CONSTRAINT #{source_table}_pkey
      SQL

      expect do
        subject
      end.to raise_error(/primary key not defined for #{source_table}/)
    end
  end

  it 'creates the partitioned table with the same non-key columns' do
    subject

    copied_columns = filter_columns_by_name(connection.columns(partitioned_table), new_primary_key)
    original_columns = filter_columns_by_name(connection.columns(source_table), new_primary_key)

    expect(copied_columns).to match_array(original_columns)
  end

  it 'removes the default from the primary key column' do
    subject

    pk_column = connection.columns(partitioned_table).find { |c| c.name == old_primary_key }

    expect(pk_column.default_function).to be_nil
  end

  describe 'constructing the partitioned table' do
    it 'creates a table partitioned by the proper column' do
      subject

      expect(connection.table_exists?(partitioned_table)).to be(true)
      expect(connection.primary_key(partitioned_table)).to eq(new_primary_key)

      expect_table_partitioned_by(partitioned_table, [partition_column_name], part_type: part_type)
    end

    it 'requires the migration helper to be run in DDL mode' do
      expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_ddl_mode!)

      subject

      expect(connection.table_exists?(partitioned_table)).to be(true)
      expect(connection.primary_key(partitioned_table)).to eq(new_primary_key)

      expect_table_partitioned_by(partitioned_table, [partition_column_name], part_type: part_type)
    end

    it 'changes the primary key datatype to bigint' do
      subject

      pk_column = connection.columns(partitioned_table).find { |c| c.name == old_primary_key }

      expect(pk_column.sql_type).to eq('bigint')
    end

    it 'removes the default from the primary key column' do
      subject

      pk_column = connection.columns(partitioned_table).find { |c| c.name == old_primary_key }

      expect(pk_column.default_function).to be_nil
    end

    it 'creates the partitioned table with the same non-key columns' do
      subject

      copied_columns = filter_columns_by_name(connection.columns(partitioned_table), new_primary_key)
      original_columns = filter_columns_by_name(connection.columns(source_table), new_primary_key)

      expect(copied_columns).to match_array(original_columns)
    end
  end

  describe 'keeping data in sync with the partitioned table' do
    before do
      partitioned_model.primary_key = :id
      partitioned_model.table_name = partitioned_table
    end

    it 'creates a trigger function on the original table' do
      expect_function_not_to_exist(function_name)
      expect_trigger_not_to_exist(source_table, trigger_name)

      subject

      expect_function_to_exist(function_name)
      expect_valid_function_trigger(source_table, trigger_name, function_name, after: %w[delete insert update])
    end

    it 'syncs inserts to the partitioned tables' do
      subject

      expect(partitioned_model.count).to eq(0)

      first_record = source_model.create!(name: 'Bob', age: 20, created_at: timestamp, external_id: 1,
        updated_at: timestamp)
      second_record = source_model.create!(name: 'Alice', age: 30, created_at: timestamp, external_id: 2,
        updated_at: timestamp)

      expect(partitioned_model.count).to eq(2)
      expect(partitioned_model.find(first_record.id).attributes).to eq(first_record.attributes)
      expect(partitioned_model.find(second_record.id).attributes).to eq(second_record.attributes)
    end

    it 'syncs updates to the partitioned tables' do
      subject

      first_record = source_model.create!(name: 'Bob', age: 20, created_at: timestamp, external_id: 1,
        updated_at: timestamp)
      second_record = source_model.create!(name: 'Alice', age: 30, created_at: timestamp, external_id: 2,
        updated_at: timestamp)

      expect(partitioned_model.count).to eq(2)

      first_copy = partitioned_model.find(first_record.id)
      second_copy = partitioned_model.find(second_record.id)

      expect(first_copy.attributes).to eq(first_record.attributes)
      expect(second_copy.attributes).to eq(second_record.attributes)

      first_record.update!(age: 21, updated_at: timestamp + 1.hour, external_id: 3)

      expect(partitioned_model.count).to eq(2)
      expect(first_copy.reload.attributes).to eq(first_record.attributes)
      expect(second_copy.reload.attributes).to eq(second_record.attributes)
    end

    it 'syncs deletes to the partitioned tables' do
      subject

      first_record = source_model.create!(name: 'Bob', age: 20, created_at: timestamp, external_id: 1,
        updated_at: timestamp)
      second_record = source_model.create!(name: 'Alice', age: 30, created_at: timestamp, external_id: 2,
        updated_at: timestamp)

      expect(partitioned_model.count).to eq(2)

      first_record.destroy!

      expect(partitioned_model.count).to eq(1)
      expect(partitioned_model.find_by_id(first_record.id)).to be_nil
      expect(partitioned_model.find(second_record.id).attributes).to eq(second_record.attributes)
    end
  end
end
