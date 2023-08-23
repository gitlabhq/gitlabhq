# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::ProcessDeletedRecordsService, feature_category: :database do
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

  let(:all_loose_foreign_key_definitions) do
    {
      '_test_loose_fk_parent_table_1' => [
        ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
          '_test_loose_fk_child_table_1_1',
          '_test_loose_fk_parent_table_1',
          {
            column: 'parent_id',
            on_delete: :async_delete,
            gitlab_schema: :gitlab_main
          }
        ),
        ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
          '_test_loose_fk_child_table_1_2',
          '_test_loose_fk_parent_table_1',
          {
            column: 'parent_id_with_different_column',
            on_delete: :async_nullify,
            gitlab_schema: :gitlab_main
          }
        )
      ],
      '_test_loose_fk_parent_table_2' => [
        ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
          '_test_loose_fk_child_table_2_1',
          '_test_loose_fk_parent_table_2',
          {
            column: 'parent_id',
            on_delete: :async_delete,
            gitlab_schema: :gitlab_main
          }
        )
      ]
    }
  end

  let(:connection) { ::ApplicationRecord.connection }

  let(:loose_fk_parent_table_1) { table(:_test_loose_fk_parent_table_1) }
  let(:loose_fk_parent_table_2) { table(:_test_loose_fk_parent_table_2) }
  let(:loose_fk_child_table_1_1) { table(:_test_loose_fk_child_table_1_1) }
  let(:loose_fk_child_table_1_2) { table(:_test_loose_fk_child_table_1_2) }
  let(:loose_fk_child_table_2_1) { table(:_test_loose_fk_child_table_2_1) }

  before_all do
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
    allow(Gitlab::Database::LooseForeignKeys).to receive(:definitions_by_table)
      .and_return(all_loose_foreign_key_definitions)

    parent_record_1 = loose_fk_parent_table_1.create!
    loose_fk_child_table_1_1.create!(parent_id: parent_record_1.id)
    loose_fk_child_table_1_2.create!(parent_id_with_different_column: parent_record_1.id)

    parent_record_2 = loose_fk_parent_table_1.create!
    2.times { loose_fk_child_table_1_1.create!(parent_id: parent_record_2.id) }
    3.times { loose_fk_child_table_1_2.create!(parent_id_with_different_column: parent_record_2.id) }

    parent_record_3 = loose_fk_parent_table_2.create!
    5.times { loose_fk_child_table_2_1.create!(parent_id: parent_record_3.id) }

    loose_fk_parent_table_1.delete_all
    loose_fk_parent_table_2.delete_all
  end

  describe '#execute' do
    def execute
      ::Gitlab::Database::SharedModel.using_connection(connection) do
        described_class.new(connection: connection).execute
      end
    end

    it 'cleans up all rows' do
      execute

      expect(loose_fk_child_table_1_1.count).to eq(0)
      expect(loose_fk_child_table_1_2.where(parent_id_with_different_column: nil).count).to eq(4)
      expect(loose_fk_child_table_2_1.count).to eq(0)
    end

    it 'returns stats for records cleaned up' do
      stats = execute

      expect(stats[:delete_count]).to eq(8)
      expect(stats[:update_count]).to eq(4)
    end

    it 'records the Apdex as success: true' do
      expect(::Gitlab::Metrics::LooseForeignKeysSlis).to receive(:record_apdex)
        .with(success: true, db_config_name: 'main')

      execute
    end

    it 'records the error rate as error: false' do
      expect(::Gitlab::Metrics::LooseForeignKeysSlis).to receive(:record_error_rate)
        .with(error: false, db_config_name: 'main')

      execute
    end

    context 'when the amount of records to clean up exceeds BATCH_SIZE' do
      before do
        stub_const('LooseForeignKeys::CleanupWorker::BATCH_SIZE', 2)
      end

      it 'cleans up everything over multiple batches' do
        expect(LooseForeignKeys::BatchCleanerService).to receive(:new).exactly(:twice).and_call_original

        execute

        expect(loose_fk_child_table_1_1.count).to eq(0)
        expect(loose_fk_child_table_1_2.where(parent_id_with_different_column: nil).count).to eq(4)
        expect(loose_fk_child_table_2_1.count).to eq(0)
      end
    end

    context 'when the amount of records to clean up exceeds the total MAX_DELETES' do
      def count_deletable_rows
        loose_fk_child_table_1_1.count + loose_fk_child_table_2_1.count
      end

      before do
        allow_next_instance_of(LooseForeignKeys::ModificationTracker) do |instance|
          allow(instance).to receive(:max_deletes).and_return(2)
        end
        stub_const('LooseForeignKeys::CleanerService::DELETE_LIMIT', 1)
      end

      it 'cleans up MAX_DELETES and leaves the rest for the next run' do
        expect { execute }.to change { count_deletable_rows }.by(-2)
        expect(count_deletable_rows).to be > 0
      end

      it 'records the Apdex as success: false' do
        expect(::Gitlab::Metrics::LooseForeignKeysSlis).to receive(:record_apdex)
          .with(success: false, db_config_name: 'main')

        execute
      end
    end

    context 'when cleanup raises an error' do
      before do
        expect_next_instance_of(::LooseForeignKeys::BatchCleanerService) do |service|
          allow(service).to receive(:execute).and_raise("Something broke")
        end
      end

      it 'records the error rate as error: true and does not increment apdex' do
        expect(::Gitlab::Metrics::LooseForeignKeysSlis).to receive(:record_error_rate)
          .with(error: true, db_config_name: 'main')
        expect(::Gitlab::Metrics::LooseForeignKeysSlis).not_to receive(:record_apdex)

        expect { execute }.to raise_error("Something broke")
      end
    end
  end
end
