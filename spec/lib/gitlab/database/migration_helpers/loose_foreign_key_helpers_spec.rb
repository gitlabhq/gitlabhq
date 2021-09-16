# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers do
  let_it_be(:migration) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  let(:model) do
    Class.new(ApplicationRecord) do
      self.table_name = 'loose_fk_test_table'
    end
  end

  before(:all) do
    migration.create_table :loose_fk_test_table do |t|
      t.timestamps
    end
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
      migration.track_record_deletions(:loose_fk_test_table)
    end

    it 'stores the record deletion' do
      records = model.all
      record_to_be_deleted = records.last

      record_to_be_deleted.delete

      expect(LooseForeignKeys::DeletedRecord.count).to eq(1)
      deleted_record = LooseForeignKeys::DeletedRecord.all.first

      expect(deleted_record.deleted_table_primary_key_value).to eq(record_to_be_deleted.id)
      expect(deleted_record.deleted_table_name).to eq('loose_fk_test_table')
    end

    it 'stores multiple record deletions' do
      model.delete_all

      expect(LooseForeignKeys::DeletedRecord.count).to eq(3)
    end
  end
end
