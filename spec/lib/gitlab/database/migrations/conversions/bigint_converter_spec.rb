# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::Conversions::BigintConverter, feature_category: :database do
  include MigrationsHelpers
  include Database::TriggerHelpers

  let(:converter) do
    described_class.new(migration, table_name, column_names)
  end

  let(:migration) do
    migration_class.new
  end

  let(:connection) { migration.connection }

  let(:migration_class) do
    Class.new(Gitlab::Database::Migration[2.2]) do
      milestone '17.4'
      restrict_gitlab_migration gitlab_schema: :gitlab_main

      def type_from_path(_)
        :regular
      end
    end
  end

  let(:current_milestone) { '17.4' }
  let(:tmp_file_path) { 'tmp/integer_ids_not_yet_initialized_to_bigint.yml' }

  let(:table_name) { :_test_table }
  let(:loaded_table_integer_ids) { { table_name => %w[id], 'other_table' => %w[id partition_id] } }
  let(:missing_integer_ids) { loaded_table_integer_ids[table_name] - column_names.map(&:to_s) }
  let(:create_table) do
    migration.create_table table_name, id: false do |t|
      t.integer :id, primary_key: true
      t.integer :ids, array: true, default: []
      t.integer :non_nullable_column, null: false
      t.integer :non_nullable_column_with_default, null: false, default: 8
      t.integer :nullable_column
      t.integer :nullable_column_with_default, default: 9
      t.bigint :bigint_id
      t.bigint :bigint_ids, array: true, default: []
      t.bigint :bigint_non_nullable_column, null: false
      t.bigint :bigint_nullable_column
    end
  end

  before do
    stub_const("#{described_class}::YAML_FILE_PATH", tmp_file_path)
    delete_yaml
    allow_next_instance_of(migration_class) do |instance|
      allow(instance).to receive_messages(
        puts: nil,
        transaction_open?: false,
        milestone: current_milestone
      )
      allow(instance.connection).to receive_messages(
        puts: nil,
        transaction_open?: false
      )
    end
  end

  shared_examples 'raising error when table does not exist' do
    context 'when table does not exist' do
      let(:table_name) { :_test_unknow_table }
      let(:column_names) { [] }

      it 'raises an error' do
        expect { execution }
          .to raise_error('Table _test_unknow_table does not exist')
      end
    end
  end

  shared_examples 'raising error when some column does not exist' do
    context 'when some column does not exist' do
      let(:column_names) { [:id, :unknown_id, :unknown_column] }

      it 'raises an error' do
        expect { execution }
          .to raise_error('Columns unknown_id, unknown_column does not exist on _test_table')
      end
    end
  end

  shared_examples 'creating new bigint columns and trigger' do |type = 'bigint'|
    it 'creates the columns and trigger' do
      expect_function_not_to_exist(new_trigger_name)
      expect_trigger_not_to_exist(table_name, new_trigger_name)

      expect { execution }
        .to change {
          all_column_names
        }.to(a_collection_including(*new_bigint_columns.keys.map(&:to_s)))

      expect_function_to_exist(new_trigger_name)
      expect_valid_function_trigger(table_name, new_trigger_name, new_trigger_name, before: %w[insert update])

      all_columns = migration.columns(table_name).index_by(&:name)
      new_bigint_columns.each do |column, expectation|
        metadata = all_columns[column.to_s]
        expect(metadata.sql_type).to eq(type)
        expect(metadata).to have_attributes(expectation)
      end
    end
  end

  shared_examples 'not creating any columns or trigger' do
    it 'does not create any columns or trigger' do
      expect_function_not_to_exist(new_trigger_name)
      expect_trigger_not_to_exist(table_name, new_trigger_name)

      expect { execution }
        .to not_change { all_column_names }

      expect_function_not_to_exist(new_trigger_name)
      expect_trigger_not_to_exist(table_name, new_trigger_name)
    end
  end

  shared_examples 'raising error for missing integer ID columns' do
    it 'raises an error' do
      expect { execution }
        .to raise_error(/Table #{table_name} still has integer ID columns \(#{missing_integer_ids.join(', ')}\)\./)
    end
  end

  describe '#init' do
    let(:execution) do
      converter.init
    end

    let(:loaded_table_integer_ids) { { table_name => %w[id ids] } }

    it_behaves_like 'raising error when table does not exist'

    context 'when target table exists' do
      before do
        create_table
        allow(converter).to receive(:all_table_integer_ids).and_return(loaded_table_integer_ids.stringify_keys)
      end

      it_behaves_like 'raising error when some column does not exist'

      context 'when all columns exist' do
        context 'for milestone below minimum' do
          let(:current_milestone) { '17.0' }
          let(:column_names) do
            [:id, :ids, :bigint_id, :bigint_ids, :non_nullable_column, :non_nullable_column_with_default,
              :nullable_column, :nullable_column_with_default]
          end

          it_behaves_like 'creating new bigint columns and trigger' do
            let(:new_bigint_columns) do
              {
                id_convert_to_bigint: {
                  default: '0',
                  null: false,
                  array: false
                },
                ids_convert_to_bigint: {
                  default: '{}',
                  null: true,
                  array: true
                },
                non_nullable_column_convert_to_bigint: {
                  default: '0',
                  null: false,
                  array: false
                },
                non_nullable_column_with_default_convert_to_bigint: {
                  default: '8',
                  null: false,
                  array: false
                },
                nullable_column_convert_to_bigint: {
                  default: nil,
                  null: true,
                  array: false
                },
                nullable_column_with_default_convert_to_bigint: {
                  default: '9',
                  null: true,
                  array: false
                }
              }
            end

            let(:new_trigger_name) { 'trigger_7508b18640c4' }
          end
        end

        context 'for milestone at least minimum' do
          context 'for columns that do not include all integer ID columns' do
            context 'when columns only include integer non-ID columns' do
              let(:column_names) { [:non_nullable_column] }

              it_behaves_like 'raising error for missing integer ID columns'
            end

            context 'when columns include part of integer ID columns' do
              let(:column_names) { [:id, :non_nullable_column] }

              it_behaves_like 'raising error for missing integer ID columns'

              context 'when columns include all bigint ID columns' do
                let(:column_names) { [:id, :non_nullable_column, :bigint_id, :bigint_ids] }

                it_behaves_like 'raising error for missing integer ID columns'
              end
            end
          end

          context 'for columns that include all integer ID columns' do
            context 'when columns only include integer ID columns' do
              let(:column_names) { [:id, :ids] }

              it_behaves_like 'creating new bigint columns and trigger' do
                let(:new_bigint_columns) do
                  {
                    id_convert_to_bigint: {
                      default: '0',
                      null: false,
                      array: false
                    },
                    ids_convert_to_bigint: {
                      default: '{}',
                      null: true,
                      array: true
                    }
                  }
                end

                let(:new_trigger_name) { 'trigger_f210e7fac012' }
              end
            end

            context 'when columns include integer non-ID columns as well' do
              let(:column_names) do
                [:id, :ids, :non_nullable_column, :non_nullable_column_with_default, :nullable_column,
                  :nullable_column_with_default]
              end

              let(:model) { table(table_name, primary_key: :id) }

              it_behaves_like 'creating new bigint columns and trigger' do
                let(:new_bigint_columns) do
                  {
                    id_convert_to_bigint: {
                      default: '0',
                      null: false,
                      array: false
                    },
                    ids_convert_to_bigint: {
                      default: '{}',
                      null: true,
                      array: true
                    },
                    non_nullable_column_convert_to_bigint: {
                      default: '0',
                      null: false,
                      array: false
                    },
                    non_nullable_column_with_default_convert_to_bigint: {
                      default: '8',
                      null: false,
                      array: false
                    },
                    nullable_column_convert_to_bigint: {
                      default: nil,
                      null: true,
                      array: false
                    },
                    nullable_column_with_default_convert_to_bigint: {
                      default: '9',
                      null: true,
                      array: false
                    }
                  }
                end

                let(:new_trigger_name) { 'trigger_768b4b1ff839' }
              end

              it 'syncs values' do
                execution
                record = model.create!(
                  ids: [777, 888],
                  non_nullable_column: 999, non_nullable_column_with_default: 1000,
                  nullable_column: 111, nullable_column_with_default: 222,
                  bigint_non_nullable_column: 8888
                )
                expect(record).to have_attributes(
                  id_convert_to_bigint: 0,
                  ids_convert_to_bigint: [],
                  non_nullable_column_convert_to_bigint: 0,
                  non_nullable_column_with_default_convert_to_bigint: 8,
                  nullable_column_convert_to_bigint: nil,
                  nullable_column_with_default_convert_to_bigint: 9
                )
                expect(record.reload).to have_attributes(
                  id_convert_to_bigint: record.id,
                  ids_convert_to_bigint: [777, 888],
                  non_nullable_column_convert_to_bigint: 999,
                  non_nullable_column_with_default_convert_to_bigint: 1000,
                  nullable_column_convert_to_bigint: 111,
                  nullable_column_with_default_convert_to_bigint: 222
                )
              end
            end

            context 'when columns include all bigint columns as well' do
              let(:column_names) { [:id, :ids, :bigint_id, :bigint_ids] }

              it_behaves_like 'creating new bigint columns and trigger' do
                let(:new_bigint_columns) do
                  {
                    id_convert_to_bigint: {
                      default: '0',
                      null: false,
                      array: false
                    },
                    ids_convert_to_bigint: {
                      default: '{}',
                      null: true,
                      array: true
                    }
                  }
                end

                let(:new_trigger_name) { 'trigger_749c8b7b817d' }
              end
            end
          end

          context 'when columns are already bigint' do
            let(:create_table) do
              migration.create_table table_name, id: false do |t|
                t.bigint :id, primary_key: true
                t.bigint :ids, array: true, default: []
              end
            end

            let(:column_names) { [:id, :ids] }

            it_behaves_like 'not creating any columns or trigger' do
              let(:new_trigger_name) { 'trigger_749c8b7b817d' }
            end
          end

          context 'for composite primary key' do
            let(:create_table) do
              migration.create_table table_name, primary_key: [:id, :partition_id] do |t|
                t.integer :id, null: false
                t.integer :partition_id, null: false
              end
            end

            let(:column_names) { [:id, :partition_id] }
            let(:loaded_table_integer_ids) { { table_name => %w[id partition_id] } }

            it_behaves_like 'creating new bigint columns and trigger' do
              let(:new_bigint_columns) do
                {
                  id_convert_to_bigint: {
                    default: '0',
                    null: false,
                    array: false
                  },
                  partition_id_convert_to_bigint: {
                    default: '0',
                    null: false,
                    array: false
                  }
                }
              end

              let(:new_trigger_name) { 'trigger_326a36fdee44' }
            end
          end
        end
      end
    end
  end

  describe '#restore_cleanup' do
    let(:execution) do
      converter.restore_cleanup
    end

    it_behaves_like 'raising error when table does not exist'

    context 'when target table exists' do
      let(:create_table) do
        migration.create_table table_name, id: false do |t|
          t.bigint :id, primary_key: true
          t.bigint :ids, array: true, default: []
          t.bigint :non_nullable_column, null: false
          t.bigint :non_nullable_column_with_default, null: false, default: 8
          t.bigint :nullable_column
          t.bigint :nullable_column_with_default, default: 9
          t.bigint :bigint_id
          t.bigint :bigint_ids, array: true, default: []
          t.bigint :bigint_non_nullable_column, null: false
          t.bigint :bigint_nullable_column
        end
      end

      before do
        create_table
      end

      it_behaves_like 'raising error when some column does not exist'

      context 'when all columns exist' do
        include MigrationsHelpers
        let(:column_names) do
          [:id, :ids, :non_nullable_column, :non_nullable_column_with_default, :nullable_column,
            :nullable_column_with_default]
        end

        let(:model) { table(table_name, primary_key: :id) }

        it_behaves_like 'creating new bigint columns and trigger', 'integer' do
          let(:new_bigint_columns) do
            {
              id_convert_to_bigint: {
                default: '0',
                null: false,
                array: false
              },
              ids_convert_to_bigint: {
                default: '{}',
                null: true,
                array: true
              },
              non_nullable_column_convert_to_bigint: {
                default: '0',
                null: false,
                array: false
              },
              non_nullable_column_with_default_convert_to_bigint: {
                default: '8',
                null: false,
                array: false
              },
              nullable_column_convert_to_bigint: {
                default: nil,
                null: true,
                array: false
              }
            }
          end

          let(:new_trigger_name) { 'trigger_768b4b1ff839' }
        end

        it 'syncs values' do
          execution
          record = model.create!(
            ids: [777, 888],
            non_nullable_column: 999, non_nullable_column_with_default: 1000,
            nullable_column: 111, nullable_column_with_default: 222,
            bigint_non_nullable_column: 8888
          )
          expect(record).to have_attributes(
            id_convert_to_bigint: 0,
            ids_convert_to_bigint: [],
            non_nullable_column_convert_to_bigint: 0,
            non_nullable_column_with_default_convert_to_bigint: 8,
            nullable_column_convert_to_bigint: nil,
            nullable_column_with_default_convert_to_bigint: 9
          )
          expect(record.reload).to have_attributes(
            id_convert_to_bigint: record.id,
            ids_convert_to_bigint: [777, 888],
            non_nullable_column_convert_to_bigint: 999,
            non_nullable_column_with_default_convert_to_bigint: 1000,
            nullable_column_convert_to_bigint: 111,
            nullable_column_with_default_convert_to_bigint: 222
          )
        end

        context 'for composite primary key' do
          let(:create_table) do
            migration.create_table table_name, primary_key: [:id, :partition_id] do |t|
              t.bigint :id, null: false
              t.bigint :partition_id, null: false
            end
          end

          let(:column_names) { [:id, :partition_id] }
          let(:loaded_table_integer_ids) { { table_name => %w[id partition_id] } }

          it_behaves_like 'creating new bigint columns and trigger', 'integer' do
            let(:new_bigint_columns) do
              {
                id_convert_to_bigint: {
                  default: '0',
                  null: false,
                  array: false
                },
                partition_id_convert_to_bigint: {
                  default: '0',
                  null: false,
                  array: false
                }
              }
            end

            let(:new_trigger_name) { 'trigger_326a36fdee44' }
          end
        end
      end
    end
  end

  describe '#cleanup' do
    let(:execution) do
      converter.cleanup
    end

    it_behaves_like 'raising error when table does not exist'

    context 'when target table exists' do
      let(:init_table) { false }

      before do
        create_table

        converter.dup.init if init_table
      end

      it_behaves_like 'raising error when some column does not exist'

      context 'when all columns exist' do
        let(:column_names) do
          [:id, :ids, :non_nullable_column, :non_nullable_column_with_default, :nullable_column,
            :nullable_column_with_default, :bigint_id, :bigint_ids]
        end

        let(:removed_trigger_name) { 'trigger_ad215af84a96' }

        context 'when conversion is not initialized' do
          it 'does not remove any columns or trigger' do
            expect_function_not_to_exist(removed_trigger_name)
            expect_trigger_not_to_exist(table_name, removed_trigger_name)

            expect { execution }
              .to not_change { all_column_names }

            expect_function_not_to_exist(removed_trigger_name)
            expect_trigger_not_to_exist(table_name, removed_trigger_name)
          end
        end

        context 'when conversion is initialized' do
          let(:init_table) { true }

          let(:removed_bigint_columns) do
            %w[
              id_convert_to_bigint ids_convert_to_bigint
              non_nullable_column_convert_to_bigint non_nullable_column_with_default_convert_to_bigint
              nullable_column_convert_to_bigint nullable_column_with_default_convert_to_bigint
            ]
          end

          before do
            write_yaml(loaded_table_integer_ids.stringify_keys)
          end

          it 'removes the columns and trigger' do
            expect_function_to_exist(removed_trigger_name)
            expect_valid_function_trigger(table_name, removed_trigger_name, removed_trigger_name,
              before: %w[insert update])

            expect { execution }
              .to change { all_column_names }
                .to(not_include(*removed_bigint_columns))

            expect_function_not_to_exist(removed_trigger_name)
            expect_trigger_not_to_exist(table_name, removed_trigger_name)
          end

          context 'when columns are swapped' do
            let(:column_names) { [:partition_id] }
            let(:removed_bigint_columns) { %w[partition_id_convert_to_bigint] }
            let(:removed_trigger_name) { 'trigger_6780b33477ad' }
            let(:create_table) do
              migration.create_table table_name, id: false do |t|
                t.bigint :id, primary_key: true
                t.integer :partition_id
              end
            end

            it 'removes the swapped columns' do
              expect(migration.column_for(table_name, column_names.first).sql_type).to eq('integer')
              migration.extend(Gitlab::Database::MigrationHelpers::Swapping)
              migration.swap_columns(table_name, :partition_id, :partition_id_convert_to_bigint)
              expect(migration.column_for(table_name, column_names.first).sql_type).to eq('bigint')

              expect_function_to_exist(removed_trigger_name)
              expect_valid_function_trigger(table_name, removed_trigger_name, removed_trigger_name,
                before: %w[insert update])

              expect { execution }
                .to change { all_column_names }
                  .to(not_include(*removed_bigint_columns))
                .and change { latest_table_integer_ids }
                  .to(not_include(table_name.to_s => %w[id ids]))

              expect_function_not_to_exist(removed_trigger_name)
              expect_trigger_not_to_exist(table_name, removed_trigger_name)
            end
          end
        end
      end
    end
  end

  describe '#revert_init' do
    let(:execution) do
      converter.revert_init
    end

    it_behaves_like 'raising error when table does not exist'

    context 'when target table exists' do
      let(:init_table) { false }

      before do
        create_table

        converter.dup.init if init_table
      end

      it_behaves_like 'raising error when some column does not exist'

      context 'when all columns exist' do
        let(:column_names) do
          [:id, :ids, :non_nullable_column, :non_nullable_column_with_default, :nullable_column,
            :nullable_column_with_default, :bigint_id, :bigint_ids]
        end

        let(:removed_trigger_name) { 'trigger_ad215af84a96' }

        context 'when conversion is not initialized' do
          it 'does not remove any columns or trigger' do
            expect_function_not_to_exist(removed_trigger_name)
            expect_trigger_not_to_exist(table_name, removed_trigger_name)

            expect { execution }
              .to not_change { all_column_names }

            expect_function_not_to_exist(removed_trigger_name)
            expect_trigger_not_to_exist(table_name, removed_trigger_name)
          end
        end

        context 'when conversion is initialized' do
          let(:init_table) { true }

          let(:removed_bigint_columns) do
            %w[
              id_convert_to_bigint ids_convert_to_bigint
              non_nullable_column_convert_to_bigint non_nullable_column_with_default_convert_to_bigint
              nullable_column_convert_to_bigint nullable_column_with_default_convert_to_bigint
            ]
          end

          it 'removes the columns and trigger' do
            expect_function_to_exist(removed_trigger_name)
            expect_valid_function_trigger(table_name, removed_trigger_name, removed_trigger_name,
              before: %w[insert update])

            expect { execution }
              .to change { all_column_names }
                .to(not_include(*removed_bigint_columns))

            expect_function_not_to_exist(removed_trigger_name)
            expect_trigger_not_to_exist(table_name, removed_trigger_name)
          end

          context 'when columns are swapped' do
            let(:column_names) { [:partition_id] }
            let(:removed_bigint_columns) { %w[partition_id_convert_to_bigint] }
            let(:removed_trigger_name) { 'trigger_6780b33477ad' }
            let(:create_table) do
              migration.create_table table_name, id: false do |t|
                t.bigint :id, primary_key: true
                t.integer :partition_id
              end
            end

            it 'removes the swapped columns' do
              expect(migration.column_for(table_name, column_names.first).sql_type).to eq('integer')
              migration.extend(Gitlab::Database::MigrationHelpers::Swapping)
              migration.swap_columns(table_name, :partition_id, :partition_id_convert_to_bigint)
              expect(migration.column_for(table_name, column_names.first).sql_type).to eq('bigint')

              expect_function_to_exist(removed_trigger_name)
              expect_valid_function_trigger(table_name, removed_trigger_name, removed_trigger_name,
                before: %w[insert update])

              expect { execution }
                .to change { all_column_names }
                  .to(not_include(*removed_bigint_columns))

              expect_function_not_to_exist(removed_trigger_name)
              expect_trigger_not_to_exist(table_name, removed_trigger_name)
            end
          end
        end
      end
    end
  end

  describe '#backfill' do
    let(:execution) do
      converter.backfill(
        primary_key: :id,
        batch_size: 20_000,
        sub_batch_size: 1000,
        pause_ms: 100,
        job_interval: 2.minutes
      )
    end

    it_behaves_like 'raising error when table does not exist'

    context 'when target table exists' do
      let(:init_table) { false }

      before do
        create_table
      end

      it_behaves_like 'raising error when some column does not exist'

      context 'when all columns exist' do
        let(:column_names) do
          [:id, :ids, :non_nullable_column, :non_nullable_column_with_default, :nullable_column,
            :nullable_column_with_default, :bigint_id, :bigint_ids]
        end

        context 'when conversion is not initialized' do
          it 'does not queue any batched background migration' do
            expect { execution }
              .to change { Gitlab::Database::BackgroundMigration::BatchedMigration.first&.attributes }
              .to(a_hash_including(
                'batch_class_name' => 'PrimaryKeyBatchingStrategy',
                'job_class_name' => 'CopyColumnUsingBackgroundMigrationJob',
                'table_name' => table_name.to_s,
                'column_name' => 'id',
                'job_arguments' => [
                  %w[
                    id ids
                    non_nullable_column non_nullable_column_with_default
                    nullable_column nullable_column_with_default
                    bigint_id bigint_ids
                  ], %w[
                    id_convert_to_bigint ids_convert_to_bigint
                    non_nullable_column_convert_to_bigint non_nullable_column_with_default_convert_to_bigint
                    nullable_column_convert_to_bigint nullable_column_with_default_convert_to_bigint
                    bigint_id_convert_to_bigint bigint_ids_convert_to_bigint
                  ]
                ],
                'batch_size' => 20_000,
                'sub_batch_size' => 1000,
                'pause_ms' => 100,
                'interval' => 2.minutes
              ))
          end
        end

        context 'when conversion is initialized' do
          before do
            converter.dup.init
          end

          it 'queues batched background migration' do
            expect { execution }
              .to change { Gitlab::Database::BackgroundMigration::BatchedMigration.first&.attributes }
              .to(a_hash_including(
                'batch_class_name' => 'PrimaryKeyBatchingStrategy',
                'job_class_name' => 'CopyColumnUsingBackgroundMigrationJob',
                'table_name' => table_name.to_s,
                'column_name' => 'id',
                'job_arguments' => [
                  %w[
                    id ids
                    non_nullable_column non_nullable_column_with_default
                    nullable_column nullable_column_with_default
                    bigint_id bigint_ids
                  ], %w[
                    id_convert_to_bigint ids_convert_to_bigint
                    non_nullable_column_convert_to_bigint non_nullable_column_with_default_convert_to_bigint
                    nullable_column_convert_to_bigint nullable_column_with_default_convert_to_bigint
                    bigint_id_convert_to_bigint bigint_ids_convert_to_bigint
                  ]
                ],
                'batch_size' => 20_000,
                'sub_batch_size' => 1000,
                'pause_ms' => 100,
                'interval' => 2.minutes
              ))
          end
        end

        context 'when columns are already bigint' do
          let(:create_table) do
            migration.create_table table_name, id: false do |t|
              t.bigint :id, primary_key: true
              t.bigint :ids, array: true, default: []
            end
          end

          let(:column_names) { [:id, :ids] }

          it 'does not queue any batched background migration' do
            expect { execution }
              .to change { Gitlab::Database::BackgroundMigration::BatchedMigration.first&.attributes }
              .to(a_hash_including(
                'batch_class_name' => 'PrimaryKeyBatchingStrategy',
                'job_class_name' => 'CopyColumnUsingBackgroundMigrationJob',
                'table_name' => table_name.to_s,
                'column_name' => 'id',
                'job_arguments' => [
                  %w[
                    id ids
                  ], %w[
                    id_convert_to_bigint ids_convert_to_bigint
                  ]
                ],
                'batch_size' => 20_000,
                'sub_batch_size' => 1000,
                'pause_ms' => 100,
                'interval' => 2.minutes
              ))
          end
        end
      end
    end
  end

  describe '#ensure_backfill' do
    let(:execution) do
      converter.ensure_backfill(primary_key: :id)
    end

    it_behaves_like 'raising error when table does not exist'

    context 'when target table exists' do
      let(:init_table) { false }

      before do
        create_table
      end

      it_behaves_like 'raising error when some column does not exist'

      context 'when all columns exist' do
        let(:column_names) do
          [:id, :ids, :non_nullable_column, :non_nullable_column_with_default, :nullable_column,
            :nullable_column_with_default, :bigint_id, :bigint_ids]
        end

        context 'when conversion is not initialized' do
          it 'does nothing' do
            expect { execution }
              .to not_change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
          end
        end

        context 'when conversion is initialized and backfill creates' do
          before do
            converter.dup.init
            converter.dup.backfill(
              primary_key: :id,
              batch_size: 20_000,
              sub_batch_size: 1000,
              pause_ms: 100,
              job_interval: 2.minutes
            )
          end

          it 'finalizes batched background migration' do
            expect { execution }
              .to change { Gitlab::Database::BackgroundMigration::BatchedMigration.first.human_status_name }
                .to('finalized')
          end
        end
      end
    end
  end

  describe '#revert_backfill' do
    let(:execution) do
      converter.revert_backfill(primary_key: :id)
    end

    it_behaves_like 'raising error when table does not exist'

    context 'when target table exists' do
      let(:init_table) { false }

      before do
        create_table
      end

      it_behaves_like 'raising error when some column does not exist'

      context 'when all columns exist' do
        let(:column_names) do
          [:id, :ids, :non_nullable_column, :non_nullable_column_with_default, :nullable_column,
            :nullable_column_with_default, :bigint_id, :bigint_ids]
        end

        context 'when conversion is not initialized' do
          it 'does not remove any batched background migration' do
            expect { execution }
              .to not_change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
          end
        end

        context 'when conversion is initialized' do
          before do
            converter.dup.init
            converter.dup.backfill(
              primary_key: :id,
              batch_size: 20_000,
              sub_batch_size: 1000,
              pause_ms: 100,
              job_interval: 2.minutes
            )
          end

          it 'removes batched background migration' do
            expect { execution }
              .to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
              .by(-1)
          end
        end

        context 'when columns are already bigint' do
          let(:create_table) do
            migration.create_table table_name, id: false do |t|
              t.bigint :id, primary_key: true
              t.bigint :ids, array: true, default: []
            end
          end

          let(:column_names) { [:id, :ids] }

          it 'does not remove any batched background migration' do
            expect { execution }
              .not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
          end
        end
      end
    end
  end

  private

  def all_column_names
    migration.columns(table_name).map(&:name)
  end

  def latest_table_integer_ids
    YAML.safe_load_file(File.join(tmp_file_path))
  rescue Errno::ENOENT
    {}
  end

  def write_yaml(table_integer_ids)
    File.open(tmp_file_path, 'w') do |file|
      file.write(table_integer_ids.stringify_keys.to_yaml)
    end
  end

  def delete_yaml
    FileUtils.rm_f(tmp_file_path)
  end
end
