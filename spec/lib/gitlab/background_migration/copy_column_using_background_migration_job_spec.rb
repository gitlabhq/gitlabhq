# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CopyColumnUsingBackgroundMigrationJob do
  let(:table_name) { :copy_primary_key_test }
  let(:test_table) { table(table_name) }
  let(:sub_batch_size) { 1000 }
  let(:pause_ms) { 0 }

  let(:helpers) do
    ActiveRecord::Migration.new.extend(Gitlab::Database::MigrationHelpers)
  end

  before do
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE TABLE #{table_name}
      (
       id integer NOT NULL,
       name character varying,
       fk integer NOT NULL,
       #{helpers.convert_to_bigint_column(:id)} bigint DEFAULT 0 NOT NULL,
       #{helpers.convert_to_bigint_column(:fk)} bigint DEFAULT 0 NOT NULL,
       name_convert_to_text text DEFAULT 'no name'
      );
    SQL

    # Insert some data, it doesn't make a difference
    test_table.create!(id: 11, name: 'test1', fk: 1)
    test_table.create!(id: 12, name: 'test2', fk: 2)
    test_table.create!(id: 15, name: nil, fk: 3)
    test_table.create!(id: 19, name: 'test4', fk: 4)
  end

  after do
    # Make sure that the temp table we created is dropped (it is not removed by the database_cleaner)
    ActiveRecord::Base.connection.execute(<<~SQL)
      DROP TABLE IF EXISTS #{table_name};
    SQL
  end

  subject(:copy_columns) { described_class.new }

  describe '#perform' do
    let(:migration_class) { described_class.name }

    it 'copies all primary keys in range' do
      temporary_column = helpers.convert_to_bigint_column(:id)
      copy_columns.perform(12, 15, table_name, 'id', sub_batch_size, pause_ms, 'id', temporary_column)

      expect(test_table.where("id = #{temporary_column}").pluck(:id)).to contain_exactly(12, 15)
      expect(test_table.where(temporary_column => 0).pluck(:id)).to contain_exactly(11, 19)
      expect(test_table.all.count).to eq(4)
    end

    it 'copies all foreign keys in range' do
      temporary_column = helpers.convert_to_bigint_column(:fk)
      copy_columns.perform(10, 14, table_name, 'id', sub_batch_size, pause_ms, 'fk', temporary_column)

      expect(test_table.where("fk = #{temporary_column}").pluck(:id)).to contain_exactly(11, 12)
      expect(test_table.where(temporary_column => 0).pluck(:id)).to contain_exactly(15, 19)
      expect(test_table.all.count).to eq(4)
    end

    it 'copies columns with NULLs' do
      expect(test_table.where("name_convert_to_text = 'no name'").count).to eq(4)

      copy_columns.perform(10, 20, table_name, 'id', sub_batch_size, pause_ms, 'name', 'name_convert_to_text')

      expect(test_table.where('name = name_convert_to_text').pluck(:id)).to contain_exactly(11, 12, 19)
      expect(test_table.where('name is NULL and name_convert_to_text is NULL').pluck(:id)).to contain_exactly(15)
      expect(test_table.where("name_convert_to_text = 'no name'").count).to eq(0)
    end

    it 'copies multiple columns when given' do
      columns_to_copy_from = %w[id fk]
      id_tmp_column = helpers.convert_to_bigint_column('id')
      fk_tmp_column = helpers.convert_to_bigint_column('fk')
      columns_to_copy_to = [id_tmp_column, fk_tmp_column]

      subject.perform(10, 15, table_name, 'id', sub_batch_size, pause_ms, columns_to_copy_from, columns_to_copy_to)

      expect(test_table.where("id = #{id_tmp_column} AND fk = #{fk_tmp_column}").pluck(:id)).to contain_exactly(11, 12, 15)
      expect(test_table.where(id_tmp_column => 0).where(fk_tmp_column => 0).pluck(:id)).to contain_exactly(19)
      expect(test_table.all.count).to eq(4)
    end

    it 'raises error when number of source and target columns does not match' do
      columns_to_copy_from = %w[id fk]
      columns_to_copy_to = [helpers.convert_to_bigint_column(:id)]

      expect do
        subject.perform(10, 15, table_name, 'id', sub_batch_size, pause_ms, columns_to_copy_from, columns_to_copy_to)
      end.to raise_error(ArgumentError, 'number of source and destination columns must match')
    end

    it 'tracks timings of queries' do
      expect(copy_columns.batch_metrics.timings).to be_empty

      copy_columns.perform(10, 20, table_name, 'id', sub_batch_size, pause_ms, 'name', 'name_convert_to_text')

      expect(copy_columns.batch_metrics.timings[:update_all]).not_to be_empty
    end

    context 'pause interval between sub-batches' do
      it 'sleeps for the specified time between sub-batches' do
        sub_batch_size = 2

        expect(copy_columns).to receive(:sleep).with(0.005)

        copy_columns.perform(10, 12, table_name, 'id', sub_batch_size, 5, 'name', 'name_convert_to_text')
      end

      it 'treats negative values as 0' do
        sub_batch_size = 2

        expect(copy_columns).to receive(:sleep).with(0)

        copy_columns.perform(10, 12, table_name, 'id', sub_batch_size, -5, 'name', 'name_convert_to_text')
      end
    end
  end
end
