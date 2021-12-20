# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers do
  let_it_be(:migration) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  let(:model) do
    Class.new(ApplicationRecord) do
      self.table_name = '_test_loose_fk_test_table'
    end
  end

  before(:all) do
    migration.create_table :_test_loose_fk_test_table do |t|
      t.timestamps
    end
  end

  after(:all) do
    migration.drop_table :_test_loose_fk_test_table
  end

  before do
    3.times { model.create! }
  end

  context 'when the record deletion tracker trigger is not installed' do
    it 'does store record deletions' do
      model.delete_all

      expect(LooseForeignKeys::DeletedRecord.count).to eq(0)
    end
  end

  context 'when the record deletion tracker trigger is installed' do
    before do
      migration.track_record_deletions(:_test_loose_fk_test_table)
    end

    it 'stores the record deletion' do
      records = model.all
      record_to_be_deleted = records.last

      record_to_be_deleted.delete

      expect(LooseForeignKeys::DeletedRecord.count).to eq(1)

      arel_table = LooseForeignKeys::DeletedRecord.arel_table
      deleted_record = LooseForeignKeys::DeletedRecord
        .select(arel_table[Arel.star], arel_table[:partition].as('partition_number')) # aliasing the ignored partition column to partition_number
        .all
        .first

      expect(deleted_record.primary_key_value).to eq(record_to_be_deleted.id)
      expect(deleted_record.fully_qualified_table_name).to eq('public._test_loose_fk_test_table')
      expect(deleted_record.partition_number).to eq(1)
    end

    it 'stores multiple record deletions' do
      model.delete_all

      expect(LooseForeignKeys::DeletedRecord.count).to eq(3)
    end
  end
end
