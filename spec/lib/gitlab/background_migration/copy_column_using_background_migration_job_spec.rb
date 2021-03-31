# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CopyColumnUsingBackgroundMigrationJob do
  let(:table_name) { :copy_primary_key_test }
  let(:test_table) { table(table_name) }
  let(:sub_batch_size) { 1000 }

  before do
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE TABLE #{table_name}
      (
       id integer NOT NULL,
       name character varying,
       fk integer NOT NULL,
       id_convert_to_bigint bigint DEFAULT 0 NOT NULL,
       fk_convert_to_bigint bigint DEFAULT 0 NOT NULL,
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

  subject { described_class.new }

  describe '#perform' do
    let(:migration_class) { described_class.name }

    it 'copies all primary keys in range' do
      subject.perform(12, 15, table_name, 'id', sub_batch_size, 'id', 'id_convert_to_bigint')

      expect(test_table.where('id = id_convert_to_bigint').pluck(:id)).to contain_exactly(12, 15)
      expect(test_table.where(id_convert_to_bigint: 0).pluck(:id)).to contain_exactly(11, 19)
      expect(test_table.all.count).to eq(4)
    end

    it 'copies all foreign keys in range' do
      subject.perform(10, 14, table_name, 'id', sub_batch_size, 'fk', 'fk_convert_to_bigint')

      expect(test_table.where('fk = fk_convert_to_bigint').pluck(:id)).to contain_exactly(11, 12)
      expect(test_table.where(fk_convert_to_bigint: 0).pluck(:id)).to contain_exactly(15, 19)
      expect(test_table.all.count).to eq(4)
    end

    it 'copies columns with NULLs' do
      expect(test_table.where("name_convert_to_text = 'no name'").count).to eq(4)

      subject.perform(10, 20, table_name, 'id', sub_batch_size, 'name', 'name_convert_to_text')

      expect(test_table.where('name = name_convert_to_text').pluck(:id)).to contain_exactly(11, 12, 19)
      expect(test_table.where('name is NULL and name_convert_to_text is NULL').pluck(:id)).to contain_exactly(15)
      expect(test_table.where("name_convert_to_text = 'no name'").count).to eq(0)
    end

    it 'tracks timings of queries' do
      expect(subject.batch_metrics.timings).to be_empty

      subject.perform(10, 20, table_name, 'id', sub_batch_size, 'name', 'name_convert_to_text')

      expect(subject.batch_metrics.timings[:update_all]).not_to be_empty
    end
  end
end
