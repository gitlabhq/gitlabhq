# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::DeletedRecord do
  let_it_be(:deleted_record_1) { described_class.create!(created_at: 1.day.ago, deleted_table_name: 'projects', deleted_table_primary_key_value: 5) }
  let_it_be(:deleted_record_2) { described_class.create!(created_at: 3.days.ago, deleted_table_name: 'projects', deleted_table_primary_key_value: 1) }
  let_it_be(:deleted_record_3) { described_class.create!(created_at: 5.days.ago, deleted_table_name: 'projects', deleted_table_primary_key_value: 3) }
  let_it_be(:deleted_record_4) { described_class.create!(created_at: 10.days.ago, deleted_table_name: 'projects', deleted_table_primary_key_value: 1) } # duplicate

  # skip created_at because it gets truncated after insert
  def map_attributes(records)
    records.pluck(:deleted_table_name, :deleted_table_primary_key_value)
  end

  describe 'partitioning strategy' do
    it 'has retain_non_empty_partitions option' do
      expect(described_class.partitioning_strategy.retain_non_empty_partitions).to eq(true)
    end
  end

  describe '.load_batch' do
    it 'loads records and orders them by creation date' do
      records = described_class.load_batch(4)

      expect(map_attributes(records)).to eq([['projects', 1], ['projects', 3], ['projects', 1], ['projects', 5]])
    end

    it 'supports configurable batch size' do
      records = described_class.load_batch(2)

      expect(map_attributes(records)).to eq([['projects', 1], ['projects', 3]])
    end
  end

  describe '.delete_records' do
    it 'deletes exactly one record' do
      described_class.delete_records([deleted_record_2])

      expect(described_class.count).to eq(3)
      expect(described_class.find_by(created_at: deleted_record_2.created_at)).to eq(nil)
    end

    it 'deletes two records' do
      described_class.delete_records([deleted_record_2, deleted_record_4])

      expect(described_class.count).to eq(2)
    end

    it 'deletes all records' do
      described_class.delete_records([deleted_record_1, deleted_record_2, deleted_record_3, deleted_record_4])

      expect(described_class.count).to eq(0)
    end
  end
end
