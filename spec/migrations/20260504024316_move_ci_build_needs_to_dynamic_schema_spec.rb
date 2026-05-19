# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MoveCiBuildNeedsToDynamicSchema, :migration, feature_category: :pipeline_composition do
  let(:migration) { described_class.new }
  let(:table_name) { described_class::TABLE_NAME }
  let(:identifier) { "#{described_class::DYNAMIC_SCHEMA}.#{table_name}" }

  describe '#up' do
    it 'moves the table into the dynamic schema' do
      expect(table_exists?(table_name)).to be_truthy

      migration.up

      expect(table_exists?(table_name)).to be_falsey
      expect(table_exists?(identifier)).to be_truthy
    end
  end

  describe '#down' do
    context 'when the partition exists in the dynamic schema' do
      before do
        migration.up
      end

      it 'moves the table into the current schema' do
        expect(table_exists?(identifier)).to be_truthy

        migration.down

        expect(table_exists?(table_name)).to be_truthy
      end
    end

    context 'when the partition does not exist in the dynamic schema' do
      before do
        migration.up
        drop_partition(identifier)

        (100..111).each do |n|
          ApplicationRecord.connection.execute(<<~SQL)
            CREATE TABLE IF NOT EXISTS #{identifier}_#{n}
              PARTITION OF p_#{table_name} FOR VALUES IN (#{n});
          SQL
        end
      end

      it 'creates the table in the current schema' do
        expect(table_exists?(identifier)).to be_falsey

        migration.down

        expect(table_exists?(table_name)).to be_truthy
      end
    end
  end

  def table_exists?(name)
    ApplicationRecord.connection.table_exists?(name)
  end

  def drop_partition(name)
    return unless table_exists?(name)

    ApplicationRecord.connection.execute(<<~SQL)
      ALTER TABLE p_#{table_name} DETACH PARTITION #{name};
      DROP TABLE IF EXISTS #{name};
    SQL
  end
end
