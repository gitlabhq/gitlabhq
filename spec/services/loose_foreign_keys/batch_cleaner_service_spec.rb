# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::BatchCleanerService do
  include MigrationsHelpers

  def create_table_structure
    migration = ActiveRecord::Migration.new.extend(Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers)

    migration.create_table :_test_loose_fk_parent_table

    migration.create_table :_test_loose_fk_child_table_1 do |t|
      t.bigint :parent_id
    end

    migration.create_table :_test_loose_fk_child_table_2 do |t|
      t.bigint :parent_id_with_different_column
    end

    migration.track_record_deletions(:_test_loose_fk_parent_table)
  end

  let(:parent_model) do
    Class.new(ApplicationRecord) do
      self.table_name = '_test_loose_fk_parent_table'

      include LooseForeignKey

      loose_foreign_key :_test_loose_fk_child_table_1, :parent_id, on_delete: :async_delete
      loose_foreign_key :_test_loose_fk_child_table_2, :parent_id_with_different_column, on_delete: :async_nullify
    end
  end

  let(:child_model_1) do
    Class.new(ApplicationRecord) do
      self.table_name = '_test_loose_fk_child_table_1'
    end
  end

  let(:child_model_2) do
    Class.new(ApplicationRecord) do
      self.table_name = '_test_loose_fk_child_table_2'
    end
  end

  let(:loose_fk_child_table_1) { table(:_test_loose_fk_child_table_1) }
  let(:loose_fk_child_table_2) { table(:_test_loose_fk_child_table_2) }
  let(:parent_record_1) { parent_model.create! }
  let(:other_parent_record) { parent_model.create! }

  before(:all) do
    create_table_structure
  end

  before do
    parent_record_1

    loose_fk_child_table_1.create!(parent_id: parent_record_1.id)
    loose_fk_child_table_1.create!(parent_id: parent_record_1.id)

    # these will not be deleted
    loose_fk_child_table_1.create!(parent_id: other_parent_record.id)
    loose_fk_child_table_1.create!(parent_id: other_parent_record.id)

    loose_fk_child_table_2.create!(parent_id_with_different_column: parent_record_1.id)
    loose_fk_child_table_2.create!(parent_id_with_different_column: parent_record_1.id)

    # these will not be deleted
    loose_fk_child_table_2.create!(parent_id_with_different_column: other_parent_record.id)
    loose_fk_child_table_2.create!(parent_id_with_different_column: other_parent_record.id)
  end

  after(:all) do
    migration = ActiveRecord::Migration.new
    migration.drop_table :_test_loose_fk_parent_table
    migration.drop_table :_test_loose_fk_child_table_1
    migration.drop_table :_test_loose_fk_child_table_2
  end

  context 'when parent records are deleted' do
    let(:deleted_records_counter) { Gitlab::Metrics.registry.get(:loose_foreign_key_processed_deleted_records) }

    before do
      parent_record_1.delete

      expect(loose_fk_child_table_1.count).to eq(4)
      expect(loose_fk_child_table_2.count).to eq(4)

      described_class.new(parent_klass: parent_model,
                          deleted_parent_records: LooseForeignKeys::DeletedRecord.status_pending.all,
                          models_by_table_name: {
                            '_test_loose_fk_child_table_1' => child_model_1,
                            '_test_loose_fk_child_table_2' => child_model_2
                          }).execute
    end

    it 'cleans up the child records' do
      expect(loose_fk_child_table_1.where(parent_id: parent_record_1.id)).to be_empty
      expect(loose_fk_child_table_2.where(parent_id_with_different_column: nil).count).to eq(2)
    end

    it 'cleans up the pending parent DeletedRecord' do
      expect(LooseForeignKeys::DeletedRecord.status_pending.count).to eq(0)
      expect(LooseForeignKeys::DeletedRecord.status_processed.count).to eq(1)
    end

    it 'records the DeletedRecord status updates', :prometheus do
      counter = Gitlab::Metrics.registry.get(:loose_foreign_key_processed_deleted_records)

      expect(counter.get(table: parent_model.table_name, db_config_name: 'main')).to eq(1)
    end

    it 'does not delete unrelated records' do
      expect(loose_fk_child_table_1.where(parent_id: other_parent_record.id).count).to eq(2)
      expect(loose_fk_child_table_2.where(parent_id_with_different_column: other_parent_record.id).count).to eq(2)
    end
  end
end
