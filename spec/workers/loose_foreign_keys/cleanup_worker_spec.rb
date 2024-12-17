# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::CleanupWorker, feature_category: :cell do
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

    case db
    when :main
      time += 2.minutes
    when :ci
      time += 3.minutes
    when :sec
      time += 4.minutes
    else
      raise "Unsupported DB: #{db}"
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
            LooseForeignKeys::DeletedRecord.create!(fully_qualified_table_name: 'public._test_loose_fk_parent_table_1', primary_key_value: 1)
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

        Gitlab::Database::SharedModel.using_connection(expected_connection) do
          expect(LooseForeignKeys::DeletedRecord.load_batch_for_table('public._test_loose_fk_parent_table_1', 10)).to be_empty
        end
      end
    end
  end

  describe 'turbo mode' do
    context 'when turbo mode is off' do
      where(:database_name, :feature_flag) do
        :main | :loose_foreign_keys_turbo_mode_main
        :ci   | :loose_foreign_keys_turbo_mode_ci
        :sec  | :loose_foreign_keys_turbo_mode_sec
      end

      with_them do
        before do
          skip unless Gitlab::Database.has_config?(database_name)
          stub_feature_flags(feature_flag => false)
        end

        it 'does not use TurboModificationTracker' do
          allow_next_instance_of(LooseForeignKeys::TurboModificationTracker) do |instance|
            expect(instance).not_to receive(:over_limit?)
          end

          perform_for(db: database_name)
        end

        it 'logs not using turbo mode' do
          expect_next_instance_of(LooseForeignKeys::CleanupWorker) do |instance|
            expect(instance).to receive(:log_extra_metadata_on_done).with(:stats, a_hash_including(turbo_mode: false))
          end

          perform_for(db: database_name)
        end
      end
    end

    context 'when turbo mode is on' do
      where(:database_name, :feature_flag) do
        :main | :loose_foreign_keys_turbo_mode_main
        :ci   | :loose_foreign_keys_turbo_mode_ci
        :sec  | :loose_foreign_keys_turbo_mode_sec
      end

      with_them do
        before do
          skip unless Gitlab::Database.has_config?(database_name)
          stub_feature_flags(feature_flag => true)
        end

        it 'does not use TurboModificationTracker' do
          expect_next_instance_of(LooseForeignKeys::TurboModificationTracker) do |instance|
            expect(instance).to receive(:over_limit?).at_least(:once)
          end

          perform_for(db: database_name)
        end

        it 'logs using turbo mode' do
          expect_next_instance_of(LooseForeignKeys::CleanupWorker) do |instance|
            expect(instance).to receive(:log_extra_metadata_on_done).with(:stats, a_hash_including(turbo_mode: true))
          end

          perform_for(db: database_name)
        end
      end
    end
  end
end
