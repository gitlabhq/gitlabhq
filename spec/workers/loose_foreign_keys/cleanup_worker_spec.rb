# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::CleanupWorker do
  include MigrationsHelpers
  using RSpec::Parameterized::TableSyntax

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
    allow(Gitlab::Database::LooseForeignKeys).to receive(:definitions_by_table).and_return(all_loose_foreign_key_definitions)

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

  def perform_for(db:)
    time = Time.current.midnight

    if db == :main
      time += 2.minutes
    elsif db == :ci
      time += 3.minutes
    end

    travel_to(time) do
      described_class.new.perform
    end
  end

  it 'cleans up all rows' do
    perform_for(db: :main)

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

      perform_for(db: :main)

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
      expect { perform_for(db: :main) }.to change { count_deletable_rows }.by(-2)
    end
  end

  describe 'multi-database support' do
    where(:current_minute, :configured_base_models, :expected_connection_model) do
      2 | { main: 'ActiveRecord::Base', ci: 'Ci::ApplicationRecord' } | 'ActiveRecord::Base'
      3 | { main: 'ActiveRecord::Base', ci: 'Ci::ApplicationRecord' } | 'Ci::ApplicationRecord'
      2 | { main: 'ActiveRecord::Base' } | 'ActiveRecord::Base'
      3 | { main: 'ActiveRecord::Base' } | 'ActiveRecord::Base'
    end

    with_them do
      let(:database_base_models) { configured_base_models.transform_values(&:constantize) }

      let(:expected_connection) { expected_connection_model.constantize.connection }

      before do
        allow(Gitlab::Database).to receive(:database_base_models_with_gitlab_shared).and_return(database_base_models)

        if database_base_models.has_key?(:ci)
          Gitlab::Database::SharedModel.using_connection(database_base_models[:ci].connection) do
            LooseForeignKeys::DeletedRecord.create!(fully_qualified_table_name: 'public._test_loose_fk_parent_table_1', primary_key_value: 999)
            LooseForeignKeys::DeletedRecord.create!(fully_qualified_table_name: 'public._test_loose_fk_parent_table_1', primary_key_value: 9991)
          end
        end
      end

      it 'uses the correct connection' do
        record_count = Gitlab::Database::SharedModel.using_connection(expected_connection) do
          LooseForeignKeys::DeletedRecord.count
        end

        record_count.times do
          expect_next_found_instance_of(LooseForeignKeys::DeletedRecord) do |instance|
            expect(instance.class.connection).to eq(expected_connection)
          end
        end

        travel_to DateTime.new(2019, 1, 1, 10, current_minute) do
          described_class.new.perform
        end
      end
    end
  end
end
