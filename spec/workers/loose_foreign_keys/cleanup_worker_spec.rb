# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::CleanupWorker do
  include MigrationsHelpers

  def create_table_structure
    migration = ActiveRecord::Migration.new.extend(Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers)

    migration.create_table :_test_loose_fk_parent_table_1
    migration.create_table :_test_loose_fk_parent_table_2

    migration.create_table :_test_loose_fk_child_table_1_1 do |t|
      t.bigint :parent_id
    end

    migration.create_table :_test_loose_fk_child_table_1_2 do |t|
      t.bigint :parent_id_with_different_column
    end

    migration.create_table :_test_loose_fk_child_table_2_1 do |t|
      t.bigint :parent_id
    end

    migration.track_record_deletions(:_test_loose_fk_parent_table_1)
    migration.track_record_deletions(:_test_loose_fk_parent_table_2)
  end

  let!(:parent_model_1) do
    Class.new(ApplicationRecord) do
      self.table_name = '_test_loose_fk_parent_table_1'

      include LooseForeignKey

      loose_foreign_key :_test_loose_fk_child_table_1_1, :parent_id, on_delete: :async_delete
      loose_foreign_key :_test_loose_fk_child_table_1_2, :parent_id_with_different_column, on_delete: :async_nullify
    end
  end

  let!(:parent_model_2) do
    Class.new(ApplicationRecord) do
      self.table_name = '_test_loose_fk_parent_table_2'

      include LooseForeignKey

      loose_foreign_key :_test_loose_fk_child_table_2_1, :parent_id, on_delete: :async_delete
    end
  end

  let!(:child_model_1) do
    Class.new(ApplicationRecord) do
      self.table_name = '_test_loose_fk_child_table_1_1'
    end
  end

  let!(:child_model_2) do
    Class.new(ApplicationRecord) do
      self.table_name = '_test_loose_fk_child_table_1_2'
    end
  end

  let!(:child_model_3) do
    Class.new(ApplicationRecord) do
      self.table_name = '_test_loose_fk_child_table_2_1'
    end
  end

  let(:loose_fk_parent_table_1) { table(:_test_loose_fk_parent_table_1) }
  let(:loose_fk_parent_table_2) { table(:_test_loose_fk_parent_table_2) }
  let(:loose_fk_child_table_1_1) { table(:_test_loose_fk_child_table_1_1) }
  let(:loose_fk_child_table_1_2) { table(:_test_loose_fk_child_table_1_2) }
  let(:loose_fk_child_table_2_1) { table(:_test_loose_fk_child_table_2_1) }

  before(:all) do
    create_table_structure
  end

  after(:all) do
    migration = ActiveRecord::Migration.new

    migration.drop_table :_test_loose_fk_parent_table_1
    migration.drop_table :_test_loose_fk_parent_table_2
    migration.drop_table :_test_loose_fk_child_table_1_1
    migration.drop_table :_test_loose_fk_child_table_1_2
    migration.drop_table :_test_loose_fk_child_table_2_1
  end

  before do
    parent_record_1 = loose_fk_parent_table_1.create!
    loose_fk_child_table_1_1.create!(parent_id: parent_record_1.id)
    loose_fk_child_table_1_2.create!(parent_id_with_different_column: parent_record_1.id)

    parent_record_2 = loose_fk_parent_table_1.create!
    2.times { loose_fk_child_table_1_1.create!(parent_id: parent_record_2.id) }
    3.times { loose_fk_child_table_1_2.create!(parent_id_with_different_column: parent_record_2.id) }

    parent_record_3 = loose_fk_parent_table_2.create!
    5.times { loose_fk_child_table_2_1.create!(parent_id: parent_record_3.id) }

    parent_model_1.delete_all
    parent_model_2.delete_all
  end

  it 'cleans up all rows' do
    described_class.new.perform

    expect(loose_fk_child_table_1_1.count).to eq(0)
    expect(loose_fk_child_table_1_2.where(parent_id_with_different_column: nil).count).to eq(4)
    expect(loose_fk_child_table_2_1.count).to eq(0)
  end

  context 'when deleting in batches' do
    before do
      stub_const('LooseForeignKeys::CleanupWorker::BATCH_SIZE', 2)
    end

    it 'cleans up all rows' do
      expect(LooseForeignKeys::BatchCleanerService).to receive(:new).exactly(:twice).and_call_original

      described_class.new.perform

      expect(loose_fk_child_table_1_1.count).to eq(0)
      expect(loose_fk_child_table_1_2.where(parent_id_with_different_column: nil).count).to eq(4)
      expect(loose_fk_child_table_2_1.count).to eq(0)
    end
  end

  context 'when the deleted rows count limit have been reached' do
    def count_deletable_rows
      loose_fk_child_table_1_1.count + loose_fk_child_table_2_1.count
    end

    before do
      stub_const('LooseForeignKeys::ModificationTracker::MAX_DELETES', 2)
      stub_const('LooseForeignKeys::CleanerService::DELETE_LIMIT', 1)
    end

    it 'cleans up 2 rows' do
      expect { described_class.new.perform }.to change { count_deletable_rows }.by(-2)
    end
  end

  context 'when the loose_foreign_key_cleanup feature flag is off' do
    before do
      stub_feature_flags(loose_foreign_key_cleanup: false)
    end

    it 'does nothing' do
      expect { described_class.new.perform }.not_to change { LooseForeignKeys::DeletedRecord.status_processed.count }
    end
  end
end
