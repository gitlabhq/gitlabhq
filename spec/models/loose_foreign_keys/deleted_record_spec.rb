# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::DeletedRecord, type: :model do
  let_it_be(:table) { 'public.projects' }

  let_it_be(:deleted_record_1) { described_class.create!(partition: 1, fully_qualified_table_name: table, primary_key_value: 5) }
  let_it_be(:deleted_record_2) { described_class.create!(partition: 1, fully_qualified_table_name: table, primary_key_value: 1) }
  let_it_be(:deleted_record_3) { described_class.create!(partition: 1, fully_qualified_table_name: 'public.other_table', primary_key_value: 3) }
  let_it_be(:deleted_record_4) { described_class.create!(partition: 1, fully_qualified_table_name: table, primary_key_value: 1) } # duplicate

  describe '.load_batch_for_table' do
    it 'loads records and orders them by creation date' do
      records = described_class.load_batch_for_table(table, 10)

      expect(records).to eq([deleted_record_1, deleted_record_2, deleted_record_4])
    end

    it 'supports configurable batch size' do
      records = described_class.load_batch_for_table(table, 2)

      expect(records).to eq([deleted_record_1, deleted_record_2])
    end
  end

  describe '.mark_records_processed' do
    it 'updates all records' do
      described_class.mark_records_processed([deleted_record_1, deleted_record_2, deleted_record_4])

      expect(described_class.status_pending.count).to eq(1)
      expect(described_class.status_processed.count).to eq(3)
    end
  end
end
