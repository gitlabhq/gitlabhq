# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers, feature_category: :database do
  include Database::TableSchemaHelpers
  include Database::TriggerHelpers

  let(:model) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  before do
    allow(model).to receive(:puts)
  end

  it { expect(model.singleton_class.ancestors).to include(described_class::WraparoundVacuumHelpers) }

  describe 'overridden dynamic model helpers' do
    let(:test_table) { :_test_batching_table }

    before do
      model.connection.execute(<<~SQL)
        CREATE TABLE #{test_table} (
          id integer NOT NULL PRIMARY KEY,
          name text NOT NULL
        );

        INSERT INTO #{test_table} (id, name)
        VALUES (1, 'bob'), (2, 'mary'), (3, 'amy');
      SQL
    end

    describe '#define_batchable_model' do
      it 'defines a batchable model with the migration connection' do
        expect(model.define_batchable_model(test_table).count).to eq(3)
      end
    end

    describe '#each_batch' do
      before do
        allow(model).to receive(:transaction_open?).and_return(false)
      end

      it 'calls each_batch with the migration connection' do
        each_batch_name = ->(&block) do
          model.each_batch(test_table, of: 2) do |batch|
            block.call(batch.pluck(:name))
          end
        end

        expect { |b| each_batch_name.call(&b) }.to yield_successive_args(%w[bob mary], %w[amy])
      end
    end

    describe '#each_batch_range' do
      before do
        allow(model).to receive(:transaction_open?).and_return(false)
      end

      it 'calls each_batch with the migration connection' do
        expect { |b| model.each_batch_range(test_table, of: 2, &b) }.to yield_successive_args([1, 2], [3, 3])
      end
    end
  end

  describe '#remove_timestamps' do
    it 'can remove the default timestamps' do
      Gitlab::Database::MigrationHelpers::DEFAULT_TIMESTAMP_COLUMNS.each do |column_name|
        expect(model).to receive(:remove_column).with(:foo, column_name)
      end

      model.remove_timestamps(:foo)
    end

    it 'can remove custom timestamps' do
      expect(model).to receive(:remove_column).with(:foo, :bar)

      model.remove_timestamps(:foo, columns: [:bar])
    end
  end

  describe '#add_timestamps_with_timezone' do
    it 'adds "created_at" and "updated_at" fields with the "datetime_with_timezone" data type' do
      Gitlab::Database::MigrationHelpers::DEFAULT_TIMESTAMP_COLUMNS.each do |column_name|
        expect(model).to receive(:add_column)
          .with(:foo, column_name, :datetime_with_timezone, { default: nil, null: false })
      end

      model.add_timestamps_with_timezone(:foo)
    end

    it 'can disable the NOT NULL constraint' do
      Gitlab::Database::MigrationHelpers::DEFAULT_TIMESTAMP_COLUMNS.each do |column_name|
        expect(model).to receive(:add_column)
          .with(:foo, column_name, :datetime_with_timezone, { default: nil, null: true })
      end

      model.add_timestamps_with_timezone(:foo, null: true)
    end

    it 'can add just one column' do
      expect(model).to receive(:add_column).with(:foo, :created_at, :datetime_with_timezone, anything)
      expect(model).not_to receive(:add_column).with(:foo, :updated_at, :datetime_with_timezone, anything)

      model.add_timestamps_with_timezone(:foo, columns: [:created_at])
    end

    it 'can add choice of acceptable columns' do
      expect(model).to receive(:add_column).with(:foo, :created_at, :datetime_with_timezone, anything)
      expect(model).to receive(:add_column).with(:foo, :deleted_at, :datetime_with_timezone, anything)
      expect(model).to receive(:add_column).with(:foo, :processed_at, :datetime_with_timezone, anything)
      expect(model).not_to receive(:add_column).with(:foo, :updated_at, :datetime_with_timezone, anything)

      model.add_timestamps_with_timezone(:foo, columns: [:created_at, :deleted_at, :processed_at])
    end

    it 'cannot add unacceptable column names' do
      expect do
        model.add_timestamps_with_timezone(:foo, columns: [:bar])
      end.to raise_error %r{Illegal timestamp column name}
    end
  end

  describe '#add_concurrent_index' do
    context 'outside a transaction' do
      before do
        allow(model).to receive(:transaction_open?).and_return(false)
        allow(model).to receive(:disable_statement_timeout).and_call_original
      end

      it 'creates the index concurrently' do
        expect(model).to receive(:add_index)
          .with(:users, :foo, algorithm: :concurrently)

        model.add_concurrent_index(:users, :foo)
      end

      it 'creates unique index concurrently' do
        expect(model).to receive(:add_index)
          .with(:users, :foo, { algorithm: :concurrently, unique: true })

        model.add_concurrent_index(:users, :foo, unique: true)
      end

      context 'when the index exists and is valid' do
        before do
          model.add_index :users, :id, unique: true
        end

        it 'does leaves the existing index' do
          expect(model).to receive(:index_exists?)
            .with(:users, :id, { algorithm: :concurrently, unique: true }).and_call_original

          expect(model).not_to receive(:remove_index)
          expect(model).not_to receive(:add_index)

          model.add_concurrent_index(:users, :id, unique: true)
        end
      end

      context 'when an invalid copy of the index exists' do
        before do
          model.add_index :users, :id, unique: true, name: index_name

          model.connection.execute(<<~SQL)
            UPDATE pg_index
            SET indisvalid = false
            WHERE indexrelid = '#{index_name}'::regclass
          SQL
        end

        context 'when the default name is used' do
          let(:index_name) { model.index_name(:users, :id) }

          it 'drops and recreates the index' do
            expect(model).to receive(:index_exists?)
              .with(:users, :id, { algorithm: :concurrently, unique: true }).and_call_original
            expect(model).to receive(:index_invalid?).with(index_name, schema: nil).and_call_original

            expect(model).to receive(:remove_concurrent_index_by_name).with(:users, index_name)

            expect(model).to receive(:add_index)
              .with(:users, :id, { algorithm: :concurrently, unique: true })

            model.add_concurrent_index(:users, :id, unique: true)
          end
        end

        context 'when a custom name is used' do
          let(:index_name) { 'my_test_index' }

          it 'drops and recreates the index' do
            expect(model).to receive(:index_exists?)
              .with(:users, :id, { algorithm: :concurrently, unique: true, name: index_name }).and_call_original
            expect(model).to receive(:index_invalid?).with(index_name, schema: nil).and_call_original

            expect(model).to receive(:remove_concurrent_index_by_name).with(:users, index_name)

            expect(model).to receive(:add_index)
              .with(:users, :id, { algorithm: :concurrently, unique: true, name: index_name })

            model.add_concurrent_index(:users, :id, unique: true, name: index_name)
          end
        end

        context 'when a qualified table name is used' do
          let(:other_schema) { 'foo_schema' }
          let(:index_name) { 'my_test_index' }
          let(:table_name) { "#{other_schema}.users" }

          before do
            model.connection.execute(<<~SQL)
              CREATE SCHEMA #{other_schema};
              ALTER TABLE users SET SCHEMA #{other_schema};
            SQL
          end

          it 'drops and recreates the index' do
            expect(model).to receive(:index_exists?)
              .with(table_name, :id, { algorithm: :concurrently, unique: true, name: index_name }).and_call_original
            expect(model).to receive(:index_invalid?).with(index_name, schema: other_schema).and_call_original

            expect(model).to receive(:remove_concurrent_index_by_name).with(table_name, index_name)

            expect(model).to receive(:add_index)
              .with(table_name, :id, { algorithm: :concurrently, unique: true, name: index_name })

            model.add_concurrent_index(table_name, :id, unique: true, name: index_name)
          end
        end
      end

      it 'unprepares the async index creation' do
        expect(model).to receive(:add_index)
          .with(:users, :foo, algorithm: :concurrently)

        expect(model).to receive(:unprepare_async_index)
          .with(:users, :foo, algorithm: :concurrently)

        model.add_concurrent_index(:users, :foo)
      end

      context 'when targeting a partition table' do
        let(:schema) { 'public' }
        let(:name) { :_test_partition_01 }
        let(:identifier) { "#{schema}.#{name}" }

        before do
          model.execute(<<~SQL)
            CREATE TABLE public._test_partitioned_table (
              id serial NOT NULL,
              partition_id serial NOT NULL,
              PRIMARY KEY (id, partition_id)
            ) PARTITION BY LIST(partition_id);

            CREATE TABLE #{identifier} PARTITION OF public._test_partitioned_table
            FOR VALUES IN (1);
          SQL
        end

        context 'when allow_partition is true' do
          it 'creates the index concurrently' do
            expect(model).to receive(:add_index).with(:_test_partition_01, :foo, algorithm: :concurrently)

            model.add_concurrent_index(:_test_partition_01, :foo, allow_partition: true)
          end
        end

        context 'when allow_partition is not provided' do
          it 'raises ArgumentError' do
            expect { model.add_concurrent_index(:_test_partition_01, :foo) }
              .to raise_error(ArgumentError, /use add_concurrent_partitioned_index/)
          end
        end
      end
    end

    context 'inside a transaction' do
      it 'raises RuntimeError' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect { model.add_concurrent_index(:users, :foo) }
          .to raise_error(RuntimeError)
      end
    end
  end

  describe '#remove_concurrent_index' do
    context 'outside a transaction' do
      before do
        allow(model).to receive(:transaction_open?).and_return(false)
        allow(model).to receive(:index_exists?).and_return(true)
        allow(model).to receive(:disable_statement_timeout).and_call_original
      end

      describe 'by column name' do
        it 'removes the index concurrently' do
          expect(model).to receive(:remove_index)
            .with(:users, { algorithm: :concurrently, column: :foo })

          model.remove_concurrent_index(:users, :foo)
        end

        it 'does nothing if the index does not exist' do
          expect(model).to receive(:index_exists?)
            .with(:users, :foo, { algorithm: :concurrently, unique: true }).and_return(false)
          expect(model).not_to receive(:remove_index)

          model.remove_concurrent_index(:users, :foo, unique: true)
        end

        it 'unprepares the async index creation' do
          expect(model).to receive(:remove_index)
            .with(:users, { algorithm: :concurrently, column: :foo })

          expect(model).to receive(:unprepare_async_index)
            .with(:users, :foo, { algorithm: :concurrently })

          model.remove_concurrent_index(:users, :foo)
        end

        context 'when targeting a partition table' do
          let(:schema) { 'public' }
          let(:partition_table_name) { :_test_partition_01 }
          let(:identifier) { "#{schema}.#{partition_table_name}" }
          let(:index_name) { :_test_partitioned_index }
          let(:partition_index_name) { :_test_partition_01_partition_id_idx }
          let(:column_name) { 'partition_id' }

          before do
            model.execute(<<~SQL)
              CREATE TABLE public._test_partitioned_table (
                id serial NOT NULL,
                partition_id serial NOT NULL,
                PRIMARY KEY (id, partition_id)
              ) PARTITION BY LIST(partition_id);

              CREATE INDEX #{index_name} ON public._test_partitioned_table(#{column_name});

              CREATE TABLE #{identifier} PARTITION OF public._test_partitioned_table
              FOR VALUES IN (1);
            SQL
          end

          context 'when dropping an index on the partition table' do
            it 'raises ArgumentError' do
              expect { model.remove_concurrent_index(partition_table_name, column_name) }
                .to raise_error(ArgumentError, /use remove_concurrent_partitioned_index_by_name/)
            end
          end
        end

        describe 'by index name' do
          before do
            allow(model).to receive(:index_exists_by_name?).with(:users, "index_x_by_y").and_return(true)
          end

          it 'removes the index concurrently by index name' do
            expect(model).to receive(:remove_index)
              .with(:users, { algorithm: :concurrently, name: "index_x_by_y" })

            model.remove_concurrent_index_by_name(:users, "index_x_by_y")
          end

          it 'does nothing if the index does not exist' do
            expect(model).to receive(:index_exists_by_name?).with(:users, "index_x_by_y").and_return(false)
            expect(model).not_to receive(:remove_index)

            model.remove_concurrent_index_by_name(:users, "index_x_by_y")
          end

          it 'removes the index with keyword arguments' do
            expect(model).to receive(:remove_index)
              .with(:users, { algorithm: :concurrently, name: "index_x_by_y" })

            model.remove_concurrent_index_by_name(:users, name: "index_x_by_y")
          end

          it 'raises an error if the index is blank' do
            expect do
              model.remove_concurrent_index_by_name(:users, wrong_key: "index_x_by_y")
            end.to raise_error 'remove_concurrent_index_by_name must get an index name as the second argument'
          end

          it 'unprepares the async index creation' do
            expect(model).to receive(:remove_index)
              .with(:users, { algorithm: :concurrently, name: "index_x_by_y" })

            expect(model).to receive(:unprepare_async_index_by_name)
              .with(:users, "index_x_by_y", { algorithm: :concurrently })

            model.remove_concurrent_index_by_name(:users, "index_x_by_y")
          end

          context 'when targeting a partition table' do
            let(:schema) { 'public' }
            let(:partition_table_name) { :_test_partition_01 }
            let(:identifier) { "#{schema}.#{partition_table_name}" }
            let(:index_name) { :_test_partitioned_index }
            let(:partition_index_name) { :_test_partition_01_partition_id_idx }

            before do
              model.execute(<<~SQL)
                CREATE TABLE public._test_partitioned_table (
                  id serial NOT NULL,
                  partition_id serial NOT NULL,
                  PRIMARY KEY (id, partition_id)
                ) PARTITION BY LIST(partition_id);

                CREATE INDEX #{index_name} ON public._test_partitioned_table(partition_id);

                CREATE TABLE #{identifier} PARTITION OF public._test_partitioned_table
                FOR VALUES IN (1);
              SQL
            end

            context 'when dropping an index on the partition table' do
              it 'raises ArgumentError' do
                expect { model.remove_concurrent_index_by_name(partition_table_name, partition_index_name) }
                  .to raise_error(ArgumentError, /use remove_concurrent_partitioned_index_by_name/)
              end
            end
          end
        end
      end
    end

    context 'inside a transaction' do
      it 'raises RuntimeError' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect { model.remove_concurrent_index(:users, :foo) }
          .to raise_error(RuntimeError)
      end
    end
  end

  describe '#remove_foreign_key_if_exists' do
    context 'when the foreign key does not exist' do
      before do
        allow(model).to receive(:foreign_key_exists?).and_return(false)
      end

      it 'does nothing' do
        expect(model).not_to receive(:remove_foreign_key)

        model.remove_foreign_key_if_exists(:projects, :users, column: :user_id)
      end
    end

    context 'when the foreign key exists' do
      before do
        allow(model).to receive(:foreign_key_exists?).and_return(true)
      end

      it 'removes the foreign key' do
        expect(model).to receive(:remove_foreign_key).with(:projects, :users, { column: :user_id })

        model.remove_foreign_key_if_exists(:projects, :users, column: :user_id)
      end

      context 'when the target table is not given' do
        it 'passes the options as the second parameter' do
          expect(model).to receive(:remove_foreign_key).with(:projects, { column: :user_id })

          model.remove_foreign_key_if_exists(:projects, column: :user_id)
        end
      end

      context 'when the reverse_lock_order option is given' do
        it 'requests for lock before removing the foreign key' do
          expect(model).to receive(:transaction_open?).and_return(true)
          expect(model).to receive(:execute).with(/LOCK TABLE users, projects/)
          expect(model).not_to receive(:remove_foreign_key).with(:projects, :users)

          model.remove_foreign_key_if_exists(:projects, :users, column: :user_id, reverse_lock_order: true)
        end

        context 'when not inside a transaction' do
          it 'does not lock' do
            expect(model).to receive(:transaction_open?).and_return(false)
            expect(model).not_to receive(:execute).with(/LOCK TABLE users, projects/)
            expect(model).to receive(:remove_foreign_key).with(:projects, :users, { column: :user_id })

            model.remove_foreign_key_if_exists(:projects, :users, column: :user_id, reverse_lock_order: true)
          end
        end
      end
    end
  end

  describe '#add_concurrent_foreign_key' do
    before do
      allow(model).to receive(:foreign_key_exists?).and_return(false)
    end

    context 'inside a transaction' do
      it 'raises an error' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect do
          model.add_concurrent_foreign_key(:projects, :users, column: :user_id)
        end.to raise_error(RuntimeError)
      end
    end

    context 'outside a transaction' do
      before do
        allow(model).to receive(:transaction_open?).and_return(false)
      end

      context 'target column' do
        it 'defaults to (id) when no custom target column is provided' do
          expect(model).to receive(:with_lock_retries).and_call_original
          expect(model).to receive(:disable_statement_timeout).and_call_original
          expect(model).to receive(:statement_timeout_disabled?).and_return(false)
          expect(model).to receive(:execute).with(/SET statement_timeout TO/)
          expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
          expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

          expect(model).to receive(:execute).with(/REFERENCES users \(id\)/)

          model.add_concurrent_foreign_key(:projects, :users,
            column: :user_id)
        end

        it 'references the custom taget column when provided' do
          expect(model).to receive(:with_lock_retries).and_call_original
          expect(model).to receive(:disable_statement_timeout).and_call_original
          expect(model).to receive(:statement_timeout_disabled?).and_return(false)
          expect(model).to receive(:execute).with(/SET statement_timeout TO/)
          expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
          expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

          expect(model).to receive(:execute).with(/REFERENCES users \(id_convert_to_bigint\)/)

          model.add_concurrent_foreign_key(:projects, :users,
            column: :user_id,
            target_column: :id_convert_to_bigint)
        end
      end

      context 'ON DELETE statements' do
        context 'on_delete: :nullify' do
          it 'appends ON DELETE SET NULL statement' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/SET statement_timeout TO/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

            expect(model).to receive(:execute).with(/ON DELETE SET NULL/)

            model.add_concurrent_foreign_key(:projects, :users,
              column: :user_id,
              on_delete: :nullify)
          end
        end

        context 'on_delete: :cascade' do
          it 'appends ON DELETE CASCADE statement' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/SET statement_timeout TO/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

            expect(model).to receive(:execute).with(/ON DELETE CASCADE/)

            model.add_concurrent_foreign_key(:projects, :users,
              column: :user_id,
              on_delete: :cascade)
          end
        end

        context 'on_delete: nil' do
          it 'appends no ON DELETE statement' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/SET statement_timeout TO/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

            expect(model).not_to receive(:execute).with(/ON DELETE/)

            model.add_concurrent_foreign_key(:projects, :users,
              column: :user_id,
              on_delete: nil)
          end
        end
      end

      context 'ON UPDATE statements' do
        context 'on_update: :nullify' do
          it 'appends ON UPDATE SET NULL statement' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/SET statement_timeout TO/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

            expect(model).to receive(:execute).with(/ON UPDATE SET NULL/)

            model.add_concurrent_foreign_key(:projects, :users,
              column: :user_id,
              on_update: :nullify)
          end
        end

        context 'on_update: :cascade' do
          it 'appends ON UPDATE CASCADE statement' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/SET statement_timeout TO/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

            expect(model).to receive(:execute).with(/ON UPDATE CASCADE/)

            model.add_concurrent_foreign_key(:projects, :users,
              column: :user_id,
              on_update: :cascade)
          end
        end

        context 'on_update: nil' do
          it 'appends no ON UPDATE statement' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/SET statement_timeout TO/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

            expect(model).not_to receive(:execute).with(/ON UPDATE/)

            model.add_concurrent_foreign_key(:projects, :users,
              column: :user_id,
              on_update: nil)
          end
        end

        context 'when on_update is not provided' do
          it 'appends no ON UPDATE statement' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/SET statement_timeout TO/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

            expect(model).not_to receive(:execute).with(/ON UPDATE/)

            model.add_concurrent_foreign_key(:projects, :users,
              column: :user_id)
          end
        end
      end

      context 'when no custom key name is supplied' do
        it 'creates a concurrent foreign key and validates it' do
          expect(model).to receive(:with_lock_retries).and_call_original
          expect(model).to receive(:disable_statement_timeout).and_call_original
          expect(model).to receive(:statement_timeout_disabled?).and_return(false)
          expect(model).to receive(:execute).with(/SET statement_timeout TO/)
          expect(model).to receive(:execute).ordered.with(/NOT VALID/)
          expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
          expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

          model.add_concurrent_foreign_key(:projects, :users, column: :user_id)
        end

        it 'does not create a foreign key if it exists already' do
          name = model.concurrent_foreign_key_name(:projects, :user_id)
          expect(model).to receive(:foreign_key_exists?).with(:projects, :users,
            column: :user_id,
            on_update: nil,
            on_delete: :cascade,
            name: name,
            primary_key: :id).and_return(true)

          expect(model).not_to receive(:execute).with(/ADD CONSTRAINT/)
          expect(model).to receive(:execute).with(/VALIDATE CONSTRAINT/)

          model.add_concurrent_foreign_key(:projects, :users, column: :user_id)
        end
      end

      context 'when a custom key name is supplied' do
        context 'for creating a new foreign key for a column that does not presently exist' do
          it 'creates a new foreign key' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/SET statement_timeout TO/)
            expect(model).to receive(:execute).ordered.with(/NOT VALID/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT.+foo/)
            expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

            model.add_concurrent_foreign_key(:projects, :users, column: :user_id, name: :foo)
          end
        end

        context 'for creating a duplicate foreign key for a column that presently exists' do
          context 'when the supplied key name is the same as the existing foreign key name' do
            it 'does not create a new foreign key' do
              expect(model).to receive(:foreign_key_exists?).with(:projects, :users,
                name: :foo,
                primary_key: :id,
                on_update: nil,
                on_delete: :cascade,
                column: :user_id).and_return(true)

              expect(model).not_to receive(:execute).with(/ADD CONSTRAINT/)
              expect(model).to receive(:execute).with(/VALIDATE CONSTRAINT/)

              model.add_concurrent_foreign_key(:projects, :users, column: :user_id, name: :foo)
            end
          end

          context 'when the supplied key name is different from the existing foreign key name' do
            it 'creates a new foreign key' do
              expect(model).to receive(:with_lock_retries).and_call_original
              expect(model).to receive(:disable_statement_timeout).and_call_original
              expect(model).to receive(:statement_timeout_disabled?).and_return(false)
              expect(model).to receive(:execute).with(/SET statement_timeout TO/)
              expect(model).to receive(:execute).ordered.with(/NOT VALID/)
              expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT.+bar/)
              expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

              model.add_concurrent_foreign_key(:projects, :users, column: :user_id, name: :bar)
            end
          end
        end
      end

      describe 'validate option' do
        let(:args) { [:projects, :users] }
        let(:options) { { column: :user_id, on_delete: nil } }

        context 'when validate is supplied with a falsey value' do
          it_behaves_like 'skips validation', validate: false
          it_behaves_like 'skips validation', validate: nil
        end

        context 'when validate is supplied with a truthy value' do
          it_behaves_like 'performs validation', validate: true
          it_behaves_like 'performs validation', validate: :whatever
        end

        context 'when validate is not supplied' do
          it_behaves_like 'performs validation', {}
        end

        context "when a ForeignKeyViolation occurs" do
          let(:source) { 'projects' }
          let(:constraint_name) { 'fk_projects_users_id' }
          let(:options) { { column: :user_id, name: constraint_name } }

          it "drops the constraint and raises an error", :aggregate_failures do
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(
              "ALTER TABLE projects ADD CONSTRAINT fk_projects_users_id FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE NOT VALID;"
            )
            expect(model).to receive(:execute).with(/SET statement_timeout TO/).ordered
            expect(model).to receive(:execute).with(/ALTER TABLE .* VALIDATE CONSTRAINT/).and_raise(PG::ForeignKeyViolation.new("foreign key violation")).ordered
            expect(model).to receive(:execute).with(/RESET statement_timeout/).ordered
            expect(model).to receive(:execute).with(/ALTER TABLE #{source} DROP CONSTRAINT #{constraint_name}/).ordered

            expect do
              model.add_concurrent_foreign_key(source, :users, **options)
            end.to raise_error %r{Migration failed intentionally due to ForeignKeyViolation}
          end
        end
      end

      context 'when the reverse_lock_order flag is set' do
        it 'explicitly locks the tables in target-source order', :aggregate_failures do
          expect(model).to receive(:with_lock_retries).and_call_original
          expect(model).to receive(:disable_statement_timeout).and_call_original
          expect(model).to receive(:statement_timeout_disabled?).and_return(false)
          expect(model).to receive(:execute).with(/SET statement_timeout TO/)
          expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
          expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

          expect(model).to receive(:execute).with('LOCK TABLE users, projects IN SHARE ROW EXCLUSIVE MODE')
          expect(model).to receive(:execute).with(/REFERENCES users \(id\)/)

          model.add_concurrent_foreign_key(:projects, :users, column: :user_id, reverse_lock_order: true)
        end
      end

      context 'when creating foreign key for a group of columns' do
        it 'references the custom target columns when provided', :aggregate_failures do
          expect(model).to receive(:with_lock_retries).and_yield
          expect(model).to receive(:execute).with(
            "ALTER TABLE projects " \
            "ADD CONSTRAINT fk_multiple_columns " \
            "FOREIGN KEY \(partition_number, user_id\) " \
            "REFERENCES users \(partition_number, id\) " \
            "ON UPDATE CASCADE " \
            "ON DELETE CASCADE " \
            "NOT VALID;"
          )

          model.add_concurrent_foreign_key(
            :projects,
            :users,
            column: [:partition_number, :user_id],
            target_column: [:partition_number, :id],
            validate: false,
            name: :fk_multiple_columns,
            on_update: :cascade
          )
        end

        context 'when foreign key is already defined' do
          before do
            expect(model).to receive(:foreign_key_exists?).with(
              :projects,
              :users,
              {
                column: [:partition_number, :user_id],
                name: :fk_multiple_columns,
                on_update: :cascade,
                on_delete: :cascade,
                primary_key: [:partition_number, :id]
              }
            ).and_return(true)
          end

          it 'does not create foreign key', :aggregate_failures do
            expect(model).not_to receive(:with_lock_retries).and_yield
            expect(model).not_to receive(:execute).with(/FOREIGN KEY/)

            model.add_concurrent_foreign_key(
              :projects,
              :users,
              column: [:partition_number, :user_id],
              target_column: [:partition_number, :id],
              on_update: :cascade,
              validate: false,
              name: :fk_multiple_columns
            )
          end
        end
      end

      context 'when creating foreign key on a partitioned table' do
        let(:source) { :_test_source_partitioned_table }
        let(:dest) { :_test_dest_partitioned_table }
        let(:args) { [source, dest] }
        let(:options) { { column: [:partition_id, :owner_id], target_column: [:partition_id, :id] } }

        before do
          model.execute(<<~SQL)
            CREATE TABLE public.#{source} (
              id serial NOT NULL,
              partition_id serial NOT NULL,
              owner_id bigint NOT NULL,
              PRIMARY KEY (id, partition_id)
            ) PARTITION BY LIST(partition_id);

            CREATE TABLE #{source}_1
              PARTITION OF public.#{source}
              FOR VALUES IN (1);

            CREATE TABLE public.#{dest} (
              id serial NOT NULL,
              partition_id serial NOT NULL,
              PRIMARY KEY (id, partition_id)
            );
          SQL
        end

        it 'creates the FK without using NOT VALID', :aggregate_failures do
          allow(model).to receive(:execute).and_call_original

          expect(model).to receive(:with_lock_retries).and_yield

          expect(model).to receive(:execute).with(
            "ALTER TABLE #{source} " \
            "ADD CONSTRAINT fk_multiple_columns " \
            "FOREIGN KEY \(partition_id, owner_id\) " \
            "REFERENCES #{dest} \(partition_id, id\) " \
            "ON UPDATE CASCADE ON DELETE CASCADE ;"
          )

          model.add_concurrent_foreign_key(
            *args,
            name: :fk_multiple_columns,
            on_update: :cascade,
            allow_partitioned: true,
            **options
          )
        end

        it 'raises an error if allow_partitioned is not set' do
          expect(model).not_to receive(:with_lock_retries).and_yield
          expect(model).not_to receive(:execute).with(/FOREIGN KEY/)

          expect { model.add_concurrent_foreign_key(*args, **options) }
            .to raise_error ArgumentError, /use add_concurrent_partitioned_foreign_key/
        end

        context 'when the reverse_lock_order flag is set' do
          it 'explicitly locks the tables in target-source order', :aggregate_failures do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/SET statement_timeout TO/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

            expect(model).to receive(:execute).with("LOCK TABLE #{dest}, #{source} IN ACCESS EXCLUSIVE MODE")
            expect(model).to receive(:execute).with(/REFERENCES #{dest} \(partition_id, id\)/)

            model.add_concurrent_foreign_key(*args, reverse_lock_order: true, allow_partitioned: true, **options)
          end
        end
      end
    end
  end

  describe '#validate_foreign_key' do
    context 'when name is provided' do
      it 'does not infer the foreign key constraint name' do
        expect(model).to receive(:foreign_key_exists?).with(:projects, name: :foo).and_return(true)

        aggregate_failures do
          expect(model).not_to receive(:concurrent_foreign_key_name)
          expect(model).to receive(:disable_statement_timeout).and_call_original
          expect(model).to receive(:statement_timeout_disabled?).and_return(false)
          expect(model).to receive(:execute).with(/SET statement_timeout TO/)
          expect(model).to receive(:execute).ordered.with(/ALTER TABLE projects VALIDATE CONSTRAINT/)
          expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)
        end

        model.validate_foreign_key(:projects, :user_id, name: :foo)
      end
    end

    context 'when name is not provided' do
      it 'infers the foreign key constraint name' do
        expect(model).to receive(:foreign_key_exists?).with(:projects, name: anything).and_return(true)

        aggregate_failures do
          expect(model).to receive(:concurrent_foreign_key_name)
          expect(model).to receive(:disable_statement_timeout).and_call_original
          expect(model).to receive(:statement_timeout_disabled?).and_return(false)
          expect(model).to receive(:execute).with(/SET statement_timeout TO/)
          expect(model).to receive(:execute).ordered.with(/ALTER TABLE projects VALIDATE CONSTRAINT/)
          expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)
        end

        model.validate_foreign_key(:projects, :user_id)
      end

      context 'when the inferred foreign key constraint does not exist' do
        it 'raises an error' do
          expect(model).to receive(:foreign_key_exists?).and_return(false)

          error_message = /Could not find foreign key "fk_name" on table "projects"/
          expect { model.validate_foreign_key(:projects, :user_id, name: :fk_name) }.to raise_error(error_message)
        end
      end
    end
  end

  describe '#concurrent_foreign_key_name' do
    it 'returns the name for a foreign key' do
      name = model.concurrent_foreign_key_name(:this_is_a_very_long_table_name,
        :with_a_very_long_column_name)

      expect(name).to be_an_instance_of(String)
      expect(name.length).to eq(13)
    end

    context 'when using multiple columns' do
      it 'returns the name of the foreign key', :aggregate_failures do
        result = model.concurrent_foreign_key_name(:table_name, [:partition_number, :id])

        expect(result).to be_an_instance_of(String)
        expect(result.length).to eq(13)
      end
    end
  end

  describe '#foreign_key_exists?' do
    let(:referenced_table_name) { :_test_gitlab_main_referenced }
    let(:referencing_table_name) { :_test_gitlab_main_referencing }
    let(:schema) { 'public' }
    let(:identifier) { "#{schema}.#{referencing_table_name}" }

    before do
      model.connection.execute(<<~SQL)
        create table #{referenced_table_name} (
          id bigserial primary key not null
        );
        create table #{referencing_table_name} (
          id bigserial primary key not null,
          non_standard_id bigint not null,
          constraint fk_referenced foreign key (non_standard_id)
            references #{referenced_table_name}(id) on delete cascade
        );
      SQL
    end

    shared_examples_for 'foreign key checks' do
      it 'finds existing foreign keys by column' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table, column: :non_standard_id)).to be_truthy
      end

      it 'finds existing foreign keys by name' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table, name: :fk_referenced)).to be_truthy
      end

      it 'finds existing foreign_keys by name and column' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table, name: :fk_referenced, column: :non_standard_id)).to be_truthy
      end

      it 'finds existing foreign_keys by name, column and on_delete' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table, name: :fk_referenced, column: :non_standard_id, on_delete: :cascade)).to be_truthy
      end

      it 'finds existing foreign keys by target table only' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table)).to be_truthy
      end

      it 'finds existing foreign_keys by identifier' do
        expect(model.foreign_key_exists?(identifier, target_table)).to be_truthy
      end

      it 'compares by column name if given' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table, column: :user_id)).to be_falsey
      end

      it 'compares by target column name if given' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table, primary_key: :user_id)).to be_falsey
        expect(model.foreign_key_exists?(referencing_table_name, target_table, primary_key: :id)).to be_truthy
      end

      it 'compares by foreign key name if given' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table, name: :non_existent_foreign_key_name)).to be_falsey
      end

      it 'compares by foreign key name and column if given' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table, name: :non_existent_foreign_key_name, column: :non_standard_id)).to be_falsey
      end

      it 'compares by foreign key name, column and on_delete if given' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table, name: :fk_referenced, column: :non_standard_id, on_delete: :nullify)).to be_falsey
      end
    end

    context 'without specifying a target table' do
      let(:target_table) { nil }

      it_behaves_like 'foreign key checks'
    end

    context 'specifying a target table' do
      let(:target_table) { referenced_table_name }

      it_behaves_like 'foreign key checks'
    end

    context 'if the schema cache does not include the constrained_columns column' do
      let(:target_table) { nil }

      around do |ex|
        model.transaction do
          require_relative '../../../fixtures/migrations/db/migrate/schema_cache_migration_test'

          # Uses the init_schema migration, as it is always present in the codebase (not affected by squashing process)
          require_migration!('init_schema')

          InitSchema.prepend(SchemaCacheMigrationTest)
          InitSchema.new.down
          Gitlab::Database::PostgresForeignKey.reset_column_information
          Gitlab::Database::PostgresForeignKey.columns_hash # Force populate the column hash in the old schema
          InitSchema.new.up

          # Rolling back reverts the schema cache information, so we need to run the example here before the rollback.
          ex.run

          raise ActiveRecord::Rollback
        end

        # make sure that we're resetting the schema cache here so that we don't leak the change to other tests.
        Gitlab::Database::PostgresForeignKey.reset_column_information
        # Double-check that the column information is back to normal
        expect(Gitlab::Database::PostgresForeignKey.columns_hash.keys).to include('constrained_columns')
      end

      # This test verifies that the situation we're trying to set up for the shared examples is actually being
      # set up correctly
      it 'correctly sets up the test without the column in the columns_hash' do
        expect(Gitlab::Database::PostgresForeignKey.columns_hash.keys).not_to include('constrained_columns')
      end

      it_behaves_like 'foreign key checks'
    end

    it 'compares by target table if no column given' do
      expect(model.foreign_key_exists?(:projects, :other_table)).to be_falsey
    end

    it 'raises an error if an invalid on_delete is specified' do
      # The correct on_delete key is "nullify"
      expect { model.foreign_key_exists?(referenced_table_name, on_delete: :set_null) }.to raise_error(ArgumentError)
    end

    context 'with foreign key using multiple columns' do
      let(:p_referenced_table_name) { :_test_gitlab_main_p_referenced }
      let(:p_referencing_table_name) { :_test_gitlab_main_p_referencing }

      before do
        model.connection.execute(<<~SQL)
          create table #{p_referenced_table_name} (
            id bigserial not null,
            partition_number bigint not null default 100,
            primary key (partition_number, id)
          );
          create table #{p_referencing_table_name} (
            id bigserial primary key not null,
            partition_number bigint not null,
            constraint fk_partitioning foreign key (partition_number, id)
              references #{p_referenced_table_name} (partition_number, id) on delete cascade
          );
        SQL
      end

      it 'finds existing foreign keys by columns' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          column: [:partition_number, :id])).to be_truthy
      end

      it 'finds existing foreign keys by name' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          name: :fk_partitioning)).to be_truthy
      end

      it 'finds existing foreign_keys by name and column' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          name: :fk_partitioning, column: [:partition_number, :id])).to be_truthy
      end

      it 'finds existing foreign_keys by name, column and on_delete' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          name: :fk_partitioning, column: [:partition_number, :id], on_delete: :cascade)).to be_truthy
      end

      it 'finds existing foreign keys by target table only' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name)).to be_truthy
      end

      it 'compares by column name if given' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          column: :id)).to be_falsey
      end

      it 'compares by target column name if given' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          primary_key: :user_id)).to be_falsey
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          primary_key: [:partition_number, :id])).to be_truthy
      end

      it 'compares by foreign key name if given' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          name: :non_existent_foreign_key_name)).to be_falsey
      end

      it 'compares by foreign key name and column if given' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          name: :non_existent_foreign_key_name, column: [:partition_number, :id])).to be_falsey
      end

      it 'compares by foreign key name, column and on_delete if given' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          name: :fk_partitioning, column: [:partition_number, :id], on_delete: :nullify)).to be_falsey
      end
    end
  end

  describe '#true_value' do
    it 'returns the appropriate value' do
      expect(model.true_value).to eq("'t'")
    end
  end

  describe '#false_value' do
    it 'returns the appropriate value' do
      expect(model.false_value).to eq("'f'")
    end
  end

  describe '#update_column_in_batches' do
    context 'when running outside of a transaction' do
      before do
        expect(model).to receive(:transaction_open?).and_return(false)

        create_list(:project, 5)
      end

      it 'updates all the rows in a table' do
        model.update_column_in_batches(:projects, :description_html, 'foo')

        expect(Project.where(description_html: 'foo').count).to eq(5)
      end

      it 'updates boolean values correctly' do
        model.update_column_in_batches(:projects, :archived, true)

        expect(Project.where(archived: true).count).to eq(5)
      end

      context 'when a block is supplied' do
        it 'yields an Arel table and query object to the supplied block' do
          first_id = Project.first.id

          model.update_column_in_batches(:projects, :archived, true) do |t, query|
            query.where(t[:id].eq(first_id))
          end

          expect(Project.where(archived: true).count).to eq(1)
        end
      end

      context 'when the value is Arel.sql (Arel::Nodes::SqlLiteral)' do
        it 'updates the value as a SQL expression' do
          model.update_column_in_batches(:projects, :star_count, Arel.sql('1+1'))

          expect(Project.sum(:star_count)).to eq(2 * Project.count)
        end
      end

      context 'when the table is write-locked' do
        let(:test_table) { :_test_table }
        let(:lock_writes_manager) do
          Gitlab::Database::LockWritesManager.new(
            table_name: test_table,
            connection: model.connection,
            database_name: 'main',
            with_retries: false
          )
        end

        before do
          model.connection.execute(<<~SQL)
            CREATE TABLE #{test_table} (id integer NOT NULL, value integer NOT NULL DEFAULT 0);

            INSERT INTO #{test_table} (id, value)
            VALUES (1, 1), (2, 2), (3, 3)
          SQL

          lock_writes_manager.lock_writes
        end

        it 'disables the write-lock trigger function' do
          expect do
            model.update_column_in_batches(test_table, :value, Arel.sql('1+1'), disable_lock_writes: true)
          end.not_to raise_error
        end

        it 'raises an error if it does not disable the trigger function' do
          expect do
            model.update_column_in_batches(test_table, :value, Arel.sql('1+1'), disable_lock_writes: false)
          end.to raise_error(ActiveRecord::StatementInvalid, /Table: "#{test_table}" is write protected/)
        end
      end
    end

    context 'when running inside the transaction' do
      it 'raises RuntimeError' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect do
          model.update_column_in_batches(:projects, :star_count, Arel.sql('1+1'))
        end.to raise_error(RuntimeError)
      end
    end
  end

  describe '#rename_column_concurrently' do
    context 'in a transaction' do
      it 'raises RuntimeError' do
        allow(model).to receive(:transaction_open?).and_return(true)

        expect { model.rename_column_concurrently(:users, :old, :new) }
          .to raise_error(RuntimeError)
      end
    end

    context 'outside a transaction' do
      let(:old_column) do
        double(:column,
          type: :integer,
          limit: 8,
          default: 0,
          null: false,
          precision: 5,
          scale: 1)
      end

      let(:trigger_name) { model.rename_trigger_name(:users, :old, :new) }

      before do
        allow(model).to receive(:transaction_open?).and_return(false)
      end

      context 'when the column to rename exists' do
        before do
          allow(model).to receive(:column_for).and_return(old_column)
        end

        it 'renames a column concurrently' do
          expect(Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection).to receive(:with_suppressed).and_yield

          expect(model).to receive(:check_trigger_permissions!).with(:users)

          expect(model).to receive(:install_rename_triggers)
            .with(:users, :old, :new)

          expect(model).to receive(:add_column)
            .with(:users, :new, :integer,
              limit: old_column.limit,
              precision: old_column.precision,
              scale: old_column.scale)

          expect(model).to receive(:change_column_default)
            .with(:users, :new, old_column.default)

          expect(model).to receive(:update_column_in_batches)

          expect(model).to receive(:add_not_null_constraint).with(:users, :new)

          expect(model).to receive(:copy_indexes).with(:users, :old, :new)
          expect(model).to receive(:copy_foreign_keys).with(:users, :old, :new)
          expect(model).to receive(:copy_check_constraints).with(:users, :old, :new)

          model.rename_column_concurrently(:users, :old, :new)
        end

        context 'with existing records and type casting' do
          let(:trigger_name) { model.rename_trigger_name(:users, :id, :new) }
          let(:user) { create(:user) }
          let(:copy_trigger) { double('copy trigger') }
          let(:connection) { ActiveRecord::Migration.connection }

          before do
            expect(Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection).to receive(:with_suppressed).and_yield
            expect(Gitlab::Database::UnidirectionalCopyTrigger).to receive(:on_table)
              .with(:users, connection: connection).and_return(copy_trigger)
          end

          it 'copies the value to the new column using the type_cast_function', :aggregate_failures do
            expect(model).to receive(:copy_indexes).with(:users, :id, :new)
            expect(model).to receive(:add_not_null_constraint).with(:users, :new)
            expect(model).to receive(:execute).with("SELECT set_config('lock_writes.users', 'false', true)")
            expect(model).to receive(:execute).with("UPDATE \"users\" SET \"new\" = cast_to_jsonb_with_default(\"users\".\"id\") WHERE \"users\".\"id\" >= #{user.id}")
            expect(copy_trigger).to receive(:create).with(:id, :new, trigger_name: nil)

            model.rename_column_concurrently(:users, :id, :new, type_cast_function: 'cast_to_jsonb_with_default')
          end
        end

        it 'passes the batch_column_name' do
          expect(model).to receive(:column_exists?).with(:users, :other_batch_column).and_return(true)
          expect(model).to receive(:check_trigger_permissions!).and_return(true)

          expect(model).to receive(:create_column_from).with(
            :users, :old, :new, type: nil, batch_column_name: :other_batch_column, type_cast_function: nil
          ).and_return(true)

          expect(model).to receive(:install_rename_triggers).and_return(true)

          model.rename_column_concurrently(:users, :old, :new, batch_column_name: :other_batch_column)
        end

        it 'passes the type_cast_function' do
          expect(model).to receive(:create_column_from).with(
            :users, :old, :new, type: nil, batch_column_name: :id, type_cast_function: 'JSON'
          ).and_return(true)

          model.rename_column_concurrently(:users, :old, :new, type_cast_function: 'JSON')
        end

        it 'raises an error with invalid batch_column_name' do
          expect do
            model.rename_column_concurrently(:users, :old, :new, batch_column_name: :invalid)
          end.to raise_error(RuntimeError, /Column invalid does not exist on users/)
        end

        context 'when default is false' do
          let(:old_column) do
            double(:column,
              type: :boolean,
              limit: nil,
              default: false,
              null: false,
              precision: nil,
              scale: nil)
          end

          it 'copies the default to the new column' do
            expect(Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection).to receive(:with_suppressed).and_yield

            expect(model).to receive(:change_column_default)
              .with(:users, :new, old_column.default)

            expect(model).to receive(:copy_check_constraints)
              .with(:users, :old, :new)

            model.rename_column_concurrently(:users, :old, :new)
          end
        end
      end

      context 'when the table in the other database is write-locked' do
        let(:test_table) { :_test_table }
        let(:lock_writes_manager) do
          Gitlab::Database::LockWritesManager.new(
            table_name: test_table,
            connection: model.connection,
            database_name: 'main',
            with_retries: false
          )
        end

        before do
          model.connection.execute(<<~SQL)
            CREATE TABLE #{test_table} (id integer NOT NULL, value integer NOT NULL DEFAULT 0);

            INSERT INTO #{test_table} (id, value)
            VALUES (1, 1), (2, 2), (3, 3)
          SQL

          lock_writes_manager.lock_writes
        end

        it 'does not raise an error when renaming the column' do
          expect do
            model.rename_column_concurrently(test_table, :value, :new_value)
          end.not_to raise_error
        end
      end

      context 'when the column to be renamed does not exist' do
        before do
          allow(model).to receive(:columns).and_return([])
        end

        it 'raises an error with appropriate message' do
          expect(model).to receive(:check_trigger_permissions!).with(:users)

          error_message = /Could not find column "missing_column" on table "users"/
          expect { model.rename_column_concurrently(:users, :missing_column, :new) }.to raise_error(error_message)
        end
      end
    end
  end

  describe '#undo_rename_column_concurrently' do
    it 'reverses the operations of rename_column_concurrently' do
      expect(model).to receive(:check_trigger_permissions!).with(:users)

      expect(model).to receive(:remove_rename_triggers)
        .with(:users, /trigger_.{12}/)

      expect(model).to receive(:remove_column).with(:users, :new)

      model.undo_rename_column_concurrently(:users, :old, :new)
    end
  end

  describe '#cleanup_concurrent_column_rename' do
    it 'cleans up the renaming procedure' do
      expect(model).to receive(:check_trigger_permissions!).with(:users)

      expect(model).to receive(:remove_rename_triggers)
        .with(:users, /trigger_.{12}/)

      expect(model).to receive(:remove_column).with(:users, :old)

      model.cleanup_concurrent_column_rename(:users, :old, :new)
    end
  end

  describe '#undo_cleanup_concurrent_column_rename' do
    context 'in a transaction' do
      it 'raises RuntimeError' do
        allow(model).to receive(:transaction_open?).and_return(true)

        expect { model.undo_cleanup_concurrent_column_rename(:users, :old, :new) }
          .to raise_error(RuntimeError)
      end
    end

    context 'outside a transaction' do
      let(:new_column) do
        double(:column,
          type: :integer,
          limit: 8,
          default: 0,
          null: false,
          precision: 5,
          scale: 1)
      end

      let(:trigger_name) { model.rename_trigger_name(:users, :old, :new) }

      before do
        allow(model).to receive(:transaction_open?).and_return(false)
        allow(model).to receive(:column_for).and_return(new_column)
      end

      it 'reverses the operations of cleanup_concurrent_column_rename' do
        expect(Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection).to receive(:with_suppressed).and_yield

        expect(model).to receive(:check_trigger_permissions!).with(:users)

        expect(model).to receive(:install_rename_triggers)
          .with(:users, :old, :new)

        expect(model).to receive(:add_column)
          .with(:users, :old, :integer,
            limit: new_column.limit,
            precision: new_column.precision,
            scale: new_column.scale)

        expect(model).to receive(:change_column_default)
          .with(:users, :old, new_column.default)

        expect(model).to receive(:update_column_in_batches)

        expect(model).to receive(:add_not_null_constraint).with(:users, :old)

        expect(model).to receive(:copy_indexes).with(:users, :new, :old)
        expect(model).to receive(:copy_foreign_keys).with(:users, :new, :old)
        expect(model).to receive(:copy_check_constraints).with(:users, :new, :old)

        model.undo_cleanup_concurrent_column_rename(:users, :old, :new)
      end

      it 'passes the batch_column_name' do
        expect(model).to receive(:column_exists?).with(:users, :other_batch_column).and_return(true)
        expect(model).to receive(:check_trigger_permissions!).and_return(true)

        expect(model).to receive(:create_column_from).with(
          :users, :new, :old, type: nil, batch_column_name: :other_batch_column
        ).and_return(true)

        expect(model).to receive(:install_rename_triggers).and_return(true)

        model.undo_cleanup_concurrent_column_rename(:users, :old, :new, batch_column_name: :other_batch_column)
      end

      it 'raises an error with invalid batch_column_name' do
        expect do
          model.undo_cleanup_concurrent_column_rename(:users, :old, :new, batch_column_name: :invalid)
        end.to raise_error(RuntimeError, /Column invalid does not exist on users/)
      end

      context 'when default is false' do
        let(:new_column) do
          double(:column,
            type: :boolean,
            limit: nil,
            default: false,
            null: false,
            precision: nil,
            scale: nil)
        end

        it 'copies the default to the old column' do
          expect(Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection).to receive(:with_suppressed).and_yield

          expect(model).to receive(:change_column_default)
            .with(:users, :old, new_column.default)

          expect(model).to receive(:copy_check_constraints)
            .with(:users, :new, :old)

          model.undo_cleanup_concurrent_column_rename(:users, :old, :new)
        end
      end
    end
  end

  describe '#change_column_type_concurrently' do
    it 'changes the column type' do
      expect(model).to receive(:rename_column_concurrently)
        .with('users', 'username', 'username_for_type_change', type: :text, type_cast_function: nil, batch_column_name: :id)

      model.change_column_type_concurrently('users', 'username', :text)
    end

    it 'passed the batch column name' do
      expect(model).to receive(:rename_column_concurrently)
        .with('users', 'username', 'username_for_type_change', type: :text, type_cast_function: nil, batch_column_name: :user_id)

      model.change_column_type_concurrently('users', 'username', :text, batch_column_name: :user_id)
    end

    context 'with type cast' do
      it 'changes the column type with casting the value to the new type' do
        expect(model).to receive(:rename_column_concurrently)
          .with('users', 'username', 'username_for_type_change', type: :text, type_cast_function: 'JSON', batch_column_name: :id)

        model.change_column_type_concurrently('users', 'username', :text, type_cast_function: 'JSON')
      end
    end
  end

  describe '#undo_change_column_type_concurrently' do
    it 'reverses the operations of change_column_type_concurrently' do
      expect(model).to receive(:check_trigger_permissions!).with(:users)

      expect(model).to receive(:remove_rename_triggers)
        .with(:users, /trigger_.{12}/)

      expect(model).to receive(:remove_column).with(:users, "old_for_type_change")

      model.undo_change_column_type_concurrently(:users, :old)
    end
  end

  describe '#cleanup_concurrent_column_type_change' do
    it 'cleans up the type changing procedure' do
      expect(model).to receive(:cleanup_concurrent_column_rename)
        .with('users', 'username', 'username_for_type_change')

      expect(model).to receive(:rename_column)
        .with('users', 'username_for_type_change', 'username')

      model.cleanup_concurrent_column_type_change('users', 'username')
    end
  end

  describe '#undo_cleanup_concurrent_column_type_change' do
    context 'in a transaction' do
      it 'raises RuntimeError' do
        allow(model).to receive(:transaction_open?).and_return(true)

        expect { model.undo_cleanup_concurrent_column_type_change(:users, :old, :new) }
          .to raise_error(RuntimeError)
      end
    end

    context 'outside a transaction' do
      let(:temp_column) { "old_for_type_change" }

      let(:temp_undo_cleanup_column) do
        identifier = "users_old_for_type_change"
        hashed_identifier = Digest::SHA256.hexdigest(identifier).first(10)
        "tmp_undo_cleanup_column_#{hashed_identifier}"
      end

      let(:trigger_name) { model.rename_trigger_name(:users, :old, :old_for_type_change) }

      before do
        allow(model).to receive(:transaction_open?).and_return(false)
      end

      it 'reverses the operations of cleanup_concurrent_column_type_change' do
        expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_ddl_mode!)

        expect(model).to receive(:check_trigger_permissions!).with(:users)

        expect(model).to receive(:create_column_from).with(
          :users,
          :old,
          temp_undo_cleanup_column,
          type: :string,
          batch_column_name: :id,
          type_cast_function: nil,
          limit: nil
        ).and_return(true)

        expect(model).to receive(:rename_column)
          .with(:users, :old, temp_column)

        expect(model).to receive(:rename_column)
          .with(:users, temp_undo_cleanup_column, :old)

        expect(model).to receive(:install_rename_triggers)
          .with(:users, :old, 'old_for_type_change')

        model.undo_cleanup_concurrent_column_type_change(:users, :old, :string)
      end

      it 'passes the type_cast_function, batch_column_name and limit' do
        expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_ddl_mode!)

        expect(model).to receive(:column_exists?).with(:users, :other_batch_column).and_return(true)
        expect(model).to receive(:check_trigger_permissions!).with(:users)

        expect(model).to receive(:create_column_from).with(
          :users,
          :old,
          temp_undo_cleanup_column,
          type: :string,
          batch_column_name: :other_batch_column,
          type_cast_function: :custom_type_cast_function,
          limit: 8
        ).and_return(true)

        expect(model).to receive(:rename_column)
          .with(:users, :old, temp_column)

        expect(model).to receive(:rename_column)
          .with(:users, temp_undo_cleanup_column, :old)

        expect(model).to receive(:install_rename_triggers)
          .with(:users, :old, 'old_for_type_change')

        model.undo_cleanup_concurrent_column_type_change(
          :users,
          :old,
          :string,
          type_cast_function: :custom_type_cast_function,
          batch_column_name: :other_batch_column,
          limit: 8
        )
      end

      it 'raises an error with invalid batch_column_name' do
        expect do
          model.undo_cleanup_concurrent_column_type_change(:users, :old, :new, batch_column_name: :invalid)
        end.to raise_error(RuntimeError, /Column invalid does not exist on users/)
      end
    end
  end

  describe '#install_rename_triggers' do
    let(:connection) { ActiveRecord::Migration.connection }

    it 'installs the triggers' do
      copy_trigger = double('copy trigger')

      expect(Gitlab::Database::UnidirectionalCopyTrigger).to receive(:on_table)
        .with(:users, connection: connection).and_return(copy_trigger)

      expect(copy_trigger).to receive(:create).with(:old, :new, trigger_name: 'foo')

      model.install_rename_triggers(:users, :old, :new, trigger_name: 'foo')
    end
  end

  describe '#remove_rename_triggers' do
    let(:connection) { ActiveRecord::Migration.connection }

    it 'removes the function and trigger' do
      copy_trigger = double('copy trigger')

      expect(Gitlab::Database::UnidirectionalCopyTrigger).to receive(:on_table)
        .with('bar', connection: connection).and_return(copy_trigger)

      expect(copy_trigger).to receive(:drop).with('foo')

      model.remove_rename_triggers('bar', 'foo')
    end
  end

  describe '#rename_trigger_name' do
    it 'returns a String' do
      expect(model.rename_trigger_name(:users, :foo, :bar))
        .to match(/trigger_.{12}/)
    end
  end

  describe '#install_sharding_key_assignment_trigger' do
    let(:trigger) { double }
    let(:connection) { ActiveRecord::Base.connection }

    it do
      expect(Gitlab::Database::Triggers::AssignDesiredShardingKey).to receive(:new)
        .with(table: :test_table, sharding_key: :project_id, parent_table: :parent_table, parent_table_primary_key: :project_id,
          parent_sharding_key: :parent_project_id, foreign_key: :foreign_key, connection: connection,
          trigger_name: 'trigger_name').and_return(trigger)

      expect(trigger).to receive(:create)

      model.install_sharding_key_assignment_trigger(table: :test_table, sharding_key: :project_id, parent_table: :parent_table,
        parent_table_primary_key: :project_id, parent_sharding_key: :parent_project_id, foreign_key: :foreign_key,
        trigger_name: 'trigger_name')
    end
  end

  describe '#remove_sharding_key_assignment_trigger' do
    let(:trigger) { double }
    let(:connection) { ActiveRecord::Base.connection }

    it do
      expect(Gitlab::Database::Triggers::AssignDesiredShardingKey).to receive(:new)
        .with(table: :test_table, sharding_key: :project_id, parent_table: :parent_table, parent_table_primary_key: :project_id,
          parent_sharding_key: :parent_project_id, foreign_key: :foreign_key, connection: connection,
          trigger_name: 'trigger_name').and_return(trigger)

      expect(trigger).to receive(:drop)

      model.remove_sharding_key_assignment_trigger(table: :test_table, sharding_key: :project_id, parent_table: :parent_table,
        parent_table_primary_key: :project_id, parent_sharding_key: :parent_project_id, foreign_key: :foreign_key,
        trigger_name: 'trigger_name')
    end
  end

  describe '#indexes_for' do
    it 'returns the indexes for a column' do
      idx1 = double(:idx, columns: %w[project_id])
      idx2 = double(:idx, columns: %w[user_id])

      allow(model).to receive(:indexes).with('table').and_return([idx1, idx2])

      expect(model.indexes_for('table', :user_id)).to eq([idx2])
    end
  end

  describe '#foreign_keys_for' do
    it 'returns the foreign keys for a column' do
      fk1 = double(:fk, column: 'project_id')
      fk2 = double(:fk, column: 'user_id')

      allow(model).to receive(:foreign_keys).with('table').and_return([fk1, fk2])

      expect(model.foreign_keys_for('table', :user_id)).to eq([fk2])
    end
  end

  describe '#copy_indexes' do
    context 'when index name is too long' do
      it 'does not fail' do
        index = double(:index,
          columns: %w[uuid],
          name: 'index_vuln_findings_on_uuid_including_vuln_id_1',
          using: nil,
          where: nil,
          opclasses: {},
          unique: true,
          lengths: [],
          orders: [])

        allow(model).to receive(:indexes_for).with(:vulnerability_occurrences, 'uuid')
          .and_return([index])

        expect(model).to receive(:add_concurrent_index)
          .with(:vulnerability_occurrences,
            %w[tmp_undo_cleanup_column_8cbf300838],
            {
             unique: true,
             name: 'idx_copy_191a1af1a0',
             length: [],
             order: []
            })

        model.copy_indexes(:vulnerability_occurrences, :uuid, :tmp_undo_cleanup_column_8cbf300838)
      end
    end

    context 'using a regular index using a single column' do
      it 'copies the index' do
        index = double(:index,
          columns: %w[project_id],
          name: 'index_on_issues_project_id',
          using: nil,
          where: nil,
          opclasses: {},
          unique: false,
          lengths: [],
          orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id')
          .and_return([index])

        expect(model).to receive(:add_concurrent_index)
          .with(:issues,
            %w[gl_project_id],
            {
             unique: false,
             name: 'index_on_issues_gl_project_id',
             length: [],
             order: []
            })

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    context 'using a regular index with multiple columns' do
      it 'copies the index' do
        index = double(:index,
          columns: %w[project_id foobar],
          name: 'index_on_issues_project_id_foobar',
          using: nil,
          where: nil,
          opclasses: {},
          unique: false,
          lengths: [],
          orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id')
          .and_return([index])

        expect(model).to receive(:add_concurrent_index)
          .with(:issues,
            %w[gl_project_id foobar],
            {
             unique: false,
             name: 'index_on_issues_gl_project_id_foobar',
             length: [],
             order: []
            })

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    context 'using an index with a WHERE clause' do
      it 'copies the index' do
        index = double(:index,
          columns: %w[project_id],
          name: 'index_on_issues_project_id',
          using: nil,
          where: 'foo',
          opclasses: {},
          unique: false,
          lengths: [],
          orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id')
          .and_return([index])

        expect(model).to receive(:add_concurrent_index)
          .with(:issues,
            %w[gl_project_id],
            {
             unique: false,
             name: 'index_on_issues_gl_project_id',
             length: [],
             order: [],
             where: 'foo'
            })

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    context 'using an index with a USING clause' do
      it 'copies the index' do
        index = double(:index,
          columns: %w[project_id],
          name: 'index_on_issues_project_id',
          where: nil,
          using: 'foo',
          opclasses: {},
          unique: false,
          lengths: [],
          orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id')
          .and_return([index])

        expect(model).to receive(:add_concurrent_index)
          .with(:issues,
            %w[gl_project_id],
            {
             unique: false,
             name: 'index_on_issues_gl_project_id',
             length: [],
             order: [],
             using: 'foo'
            })

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    context 'using an index with custom operator classes' do
      it 'copies the index' do
        index = double(:index,
          columns: %w[project_id],
          name: 'index_on_issues_project_id',
          using: nil,
          where: nil,
          opclasses: { 'project_id' => 'bar' },
          unique: false,
          lengths: [],
          orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id')
          .and_return([index])

        expect(model).to receive(:add_concurrent_index)
          .with(:issues,
            %w[gl_project_id],
            {
             unique: false,
             name: 'index_on_issues_gl_project_id',
             length: [],
             order: [],
             opclass: { 'gl_project_id' => 'bar' }
            })

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    context 'using an index with multiple columns and custom operator classes' do
      it 'copies the index' do
        index = double(:index,
          {
            columns: %w[project_id foobar],
            name: 'index_on_issues_project_id_foobar',
            using: :gin,
            where: nil,
            opclasses: { 'project_id' => 'bar', 'foobar' => :gin_trgm_ops },
            unique: false,
            lengths: [],
            orders: []
          })

        allow(model).to receive(:indexes_for).with(:issues, 'project_id')
          .and_return([index])

        expect(model).to receive(:add_concurrent_index)
          .with(:issues,
            %w[gl_project_id foobar],
            {
             unique: false,
             name: 'index_on_issues_gl_project_id_foobar',
             length: [],
             order: [],
             opclass: { 'gl_project_id' => 'bar', 'foobar' => :gin_trgm_ops },
             using: :gin
            })

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    context 'using an index with multiple columns and a custom operator class on the non affected column' do
      it 'copies the index' do
        index = double(:index,
          {
            columns: %w[project_id foobar],
            name: 'index_on_issues_project_id_foobar',
            using: :gin,
            where: nil,
            opclasses: { 'foobar' => :gin_trgm_ops },
            unique: false,
            lengths: [],
            orders: []
          })

        allow(model).to receive(:indexes_for).with(:issues, 'project_id')
          .and_return([index])

        expect(model).to receive(:add_concurrent_index)
          .with(:issues,
            %w[gl_project_id foobar],
            {
             unique: false,
             name: 'index_on_issues_gl_project_id_foobar',
             length: [],
             order: [],
             opclass: { 'foobar' => :gin_trgm_ops },
             using: :gin
            })

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    describe 'using an index of which the name does not contain the source column' do
      it 'raises RuntimeError' do
        index = double(:index,
          columns: %w[project_id],
          name: 'index_foobar_index',
          using: nil,
          where: nil,
          opclasses: {},
          unique: false,
          lengths: [],
          orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id')
          .and_return([index])

        expect { model.copy_indexes(:issues, :project_id, :gl_project_id) }
          .to raise_error(RuntimeError)
      end
    end
  end

  describe '#copy_foreign_keys' do
    it 'copies foreign keys from one column to another' do
      fk = double(:fk,
        from_table: 'issues',
        to_table: 'projects',
        on_delete: :cascade)

      allow(model).to receive(:foreign_keys_for).with(:issues, :project_id)
        .and_return([fk])

      expect(model).to receive(:add_concurrent_foreign_key)
        .with('issues', 'projects', column: :gl_project_id, on_delete: :cascade)

      model.copy_foreign_keys(:issues, :project_id, :gl_project_id)
    end
  end

  describe '#column_for' do
    it 'returns a column object for an existing column' do
      column = model.column_for(:users, :id)

      expect(column.name).to eq('id')
    end

    it 'raises an error when a column does not exist' do
      error_message = /Could not find column "kittens" on table "users"/
      expect { model.column_for(:users, :kittens) }.to raise_error(error_message)
    end
  end

  describe '#replace_sql' do
    it 'builds the sql with correct functions' do
      expect(model.replace_sql(Arel::Table.new(:users)[:first_name], "Alice", "Eve").to_s)
        .to include('regexp_replace')
    end

    describe 'results' do
      let!(:user) { create(:user, name: 'Kathy Alice Aliceson') }

      it 'replaces the correct part of the string' do
        allow(model).to receive(:transaction_open?).and_return(false)
        query = model.replace_sql(Arel::Table.new(:users)[:name], 'Alice', 'Eve')

        model.update_column_in_batches(:users, :name, query)

        expect(user.reload.name).to eq('Kathy Eve Aliceson')
      end
    end
  end

  describe '#check_trigger_permissions!' do
    it 'does nothing when the user has the correct permissions' do
      expect { model.check_trigger_permissions!('users') }
        .not_to raise_error
    end

    it 'raises RuntimeError when the user does not have the correct permissions' do
      allow(Gitlab::Database::Grant).to receive(:create_and_execute_trigger?)
        .with('kittens')
        .and_return(false)

      expect { model.check_trigger_permissions!('kittens') }
        .to raise_error(RuntimeError, /Your database user is not allowed/)
    end
  end

  describe '#convert_to_bigint_column' do
    it 'returns the name of the temporary column used to convert to bigint' do
      expect(model.convert_to_bigint_column(:id)).to eq('id_convert_to_bigint')
    end
  end

  describe '#convert_to_type_column' do
    it 'returns the name of the temporary column used to convert to bigint' do
      expect(model.convert_to_type_column(:id, :int, :bigint)).to eq('id_convert_int_to_bigint')
    end

    it 'returns the name of the temporary column used to convert to uuid' do
      expect(model.convert_to_type_column(:uuid, :string, :uuid)).to eq('uuid_convert_string_to_uuid')
    end
  end

  describe '#index_exists_by_name?' do
    it 'returns true if an index exists' do
      ActiveRecord::Migration.connection.execute(
        'CREATE INDEX test_index_for_index_exists ON projects (path);'
      )

      expect(model.index_exists_by_name?(:projects, 'test_index_for_index_exists'))
        .to be_truthy
    end

    it 'returns false if the index does not exist' do
      expect(model.index_exists_by_name?(:projects, 'this_does_not_exist'))
        .to be_falsy
    end

    context 'when an index with a function exists' do
      before do
        ActiveRecord::Migration.connection.execute(
          'CREATE INDEX test_index ON projects (LOWER(path));'
        )
      end

      it 'returns true if an index exists' do
        expect(model.index_exists_by_name?(:projects, 'test_index'))
          .to be_truthy
      end
    end

    context 'when an index exists for a table with the same name in another schema' do
      before do
        ActiveRecord::Migration.connection.execute(
          'CREATE SCHEMA new_test_schema'
        )

        ActiveRecord::Migration.connection.execute(
          'CREATE TABLE new_test_schema.projects (id integer, name character varying)'
        )

        ActiveRecord::Migration.connection.execute(
          'CREATE INDEX test_index_on_name ON new_test_schema.projects (LOWER(name));'
        )
      end

      it 'returns false if the index does not exist in the current schema' do
        expect(model.index_exists_by_name?(:projects, 'test_index_on_name'))
          .to be_falsy
      end
    end
  end

  describe '#create_or_update_plan_limit' do
    before do
      stub_const('Plan', Class.new(ActiveRecord::Base))
      stub_const('PlanLimits', Class.new(ActiveRecord::Base))

      Plan.class_eval do
        self.table_name = 'plans'
      end

      PlanLimits.class_eval do
        self.table_name = 'plan_limits'
      end
    end

    it 'properly escapes names' do
      expect(model).to receive(:execute).with <<~SQL
        INSERT INTO plan_limits (plan_id, "project_hooks")
        SELECT id, '10' FROM plans WHERE name = 'free' LIMIT 1
        ON CONFLICT (plan_id) DO UPDATE SET "project_hooks" = EXCLUDED."project_hooks";
      SQL

      model.create_or_update_plan_limit('project_hooks', 'free', 10)
    end

    context 'when plan does not exist' do
      it 'does not create any plan limits' do
        expect { model.create_or_update_plan_limit('project_hooks', 'plan_name', 10) }
          .not_to change { PlanLimits.count }
      end
    end

    context 'when plan does exist' do
      let!(:plan) { Plan.create!(name: 'plan_name') }

      context 'when limit does not exist' do
        it 'inserts a new plan limits' do
          expect { model.create_or_update_plan_limit('project_hooks', 'plan_name', 10) }
            .to change { PlanLimits.count }.by(1)

          expect(PlanLimits.pluck(:project_hooks)).to contain_exactly(10)
        end
      end

      context 'when limit does exist' do
        let!(:plan_limit) { PlanLimits.create!(plan_id: plan.id) }

        it 'updates an existing plan limits' do
          expect { model.create_or_update_plan_limit('project_hooks', 'plan_name', 999) }
            .not_to change { PlanLimits.count }

          expect(plan_limit.reload.project_hooks).to eq(999)
        end
      end
    end
  end

  describe '#backfill_iids' do
    include MigrationsHelpers

    let_it_be(:issue_base_type_enum) { 0 }
    let_it_be(:issue_type) { table(:work_item_types).find_by(base_type: issue_base_type_enum) }

    let(:issue_class) do
      Class.new(ActiveRecord::Base) do
        include AtomicInternalId

        self.table_name = 'issues'
        self.inheritance_column = :_type_disabled

        belongs_to :project, class_name: "::Project", inverse_of: nil

        has_internal_id :iid,
          scope: :project,
          init: ->(s, _scope) { s&.project&.issues&.maximum(:iid) },
          presence: false

        before_validation -> { self.work_item_type_id = ::WorkItems::Type.default_issue_type.id }
      end
    end

    let_it_be(:organizations)  { table(:organizations) }
    let_it_be(:namespaces)     { table(:namespaces) }
    let_it_be(:projects)       { table(:projects) }
    let_it_be(:issues)         { table(:issues) }

    let_it_be(:organization) { organizations.create!(name: 'organization', path: 'organization') }

    def setup
      namespace = namespaces.create!(
        name: 'foo',
        path: 'foo',
        type: Namespaces::UserNamespace.sti_name,
        organization_id: organization.id
      )

      project_namespace = namespaces.create!(
        name: 'project-foo',
        path: 'project-foo',
        type: 'Project',
        organization_id: organization.id,
        parent_id: namespace.id,
        visibility_level: 20
      )

      projects.create!(
        namespace_id: namespace.id,
        project_namespace_id: project_namespace.id,
        organization_id: organization.id
      )
    end

    it 'generates iids properly for models created after the migration' do
      project = setup

      model.backfill_iids('issues')

      issue = issue_class.create!(project_id: project.id, namespace_id: project.project_namespace_id)

      expect(issue.iid).to eq(1)
    end

    it 'generates iids properly for models created after the migration when iids are backfilled' do
      project = setup
      issue_a = issues.create!(project_id: project.id, namespace_id: project.project_namespace_id, work_item_type_id: issue_type.id)

      model.backfill_iids('issues')

      issue_b = issue_class.create!(project_id: project.id, namespace_id: project.project_namespace_id)

      expect(issue_a.reload.iid).to eq(1)
      expect(issue_b.iid).to eq(2)
    end

    it 'generates iids properly for models created after the migration across multiple projects' do
      project_a = setup
      project_b = setup
      issues.create!(project_id: project_a.id, namespace_id: project_a.project_namespace_id, work_item_type_id: issue_type.id)
      issues.create!(project_id: project_b.id, namespace_id: project_b.project_namespace_id, work_item_type_id: issue_type.id)
      issues.create!(project_id: project_b.id, namespace_id: project_b.project_namespace_id, work_item_type_id: issue_type.id)

      model.backfill_iids('issues')

      issue_a = issue_class.create!(project_id: project_a.id, namespace_id: project_a.project_namespace_id, work_item_type_id: issue_type.id)
      issue_b = issue_class.create!(project_id: project_b.id, namespace_id: project_b.project_namespace_id, work_item_type_id: issue_type.id)

      expect(issue_a.iid).to eq(2)
      expect(issue_b.iid).to eq(3)
    end

    context 'when the first model is created for a project after the migration' do
      it 'generates an iid' do
        project_a = setup
        project_b = setup
        issue_a = issues.create!(project_id: project_a.id, namespace_id: project_a.project_namespace_id, work_item_type_id: issue_type.id)

        model.backfill_iids('issues')

        issue_b = issue_class.create!(project_id: project_b.id, namespace_id: project_b.project_namespace_id)

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(1)
      end
    end

    context 'when a row already has an iid set in the database' do
      it 'backfills iids' do
        project = setup
        issue_a = issues.create!(project_id: project.id, namespace_id: project.project_namespace_id, work_item_type_id: issue_type.id, iid: 1)
        issue_b = issues.create!(project_id: project.id, namespace_id: project.project_namespace_id, work_item_type_id: issue_type.id, iid: 2)

        model.backfill_iids('issues')

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(2)
      end

      it 'backfills for multiple projects' do
        project_a = setup
        project_b = setup
        issue_a = issues.create!(project_id: project_a.id, namespace_id: project_a.project_namespace_id, work_item_type_id: issue_type.id, iid: 1)
        issue_b = issues.create!(project_id: project_b.id, namespace_id: project_b.project_namespace_id, work_item_type_id: issue_type.id, iid: 1)
        issue_c = issues.create!(project_id: project_a.id, namespace_id: project_a.project_namespace_id, work_item_type_id: issue_type.id, iid: 2)

        model.backfill_iids('issues')

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(1)
        expect(issue_c.reload.iid).to eq(2)
      end
    end
  end

  describe '#add_primary_key_using_index' do
    it "executes the statement to add the primary key" do
      expect(model).to receive(:execute).with(/ALTER TABLE "_test_table" ADD CONSTRAINT "old_name" PRIMARY KEY USING INDEX "new_name"/)

      model.add_primary_key_using_index(:_test_table, :old_name, :new_name)
    end
  end

  context 'when changing the primary key of a given table' do
    before do
      model.create_table(:_test_table, primary_key: :id) do |t|
        t.integer :partition_number, default: 1
      end

      model.add_index(:_test_table, :id, unique: true, name: :old_index_name)
      model.add_index(:_test_table, [:id, :partition_number], unique: true, name: :new_index_name)
    end

    describe '#swap_primary_key' do
      it 'executes statements to swap primary key', :aggregate_failures do
        expect(model).to receive(:with_lock_retries).with(raise_on_exhaustion: true).ordered.and_yield
        expect(model).to receive(:execute).with(/ALTER TABLE "_test_table" DROP CONSTRAINT "_test_table_pkey" CASCADE/).and_call_original
        expect(model).to receive(:execute).with(/ALTER TABLE "_test_table" ADD CONSTRAINT "_test_table_pkey" PRIMARY KEY USING INDEX "new_index_name"/).and_call_original

        model.swap_primary_key(:_test_table, :_test_table_pkey, :new_index_name)
      end

      context 'when new index does not exist' do
        before do
          model.remove_index(:_test_table, column: [:id, :partition_number])
        end

        it 'raises ActiveRecord::StatementInvalid' do
          expect do
            model.swap_primary_key(:_test_table, :_test_table_pkey, :new_index_name)
          end.to raise_error(ActiveRecord::StatementInvalid)
        end
      end
    end

    describe '#unswap_primary_key' do
      it 'executes statements to unswap primary key' do
        expect(model).to receive(:with_lock_retries).with(raise_on_exhaustion: true).ordered.and_yield
        expect(model).to receive(:execute).with(/ALTER TABLE "_test_table" DROP CONSTRAINT "_test_table_pkey" CASCADE/).ordered.and_call_original
        expect(model).to receive(:execute).with(/ALTER TABLE "_test_table" ADD CONSTRAINT "_test_table_pkey" PRIMARY KEY USING INDEX "old_index_name"/).ordered.and_call_original

        model.unswap_primary_key(:_test_table, :_test_table_pkey, :old_index_name)
      end
    end
  end

  describe '#drop_sequence' do
    it "executes the statement to drop the sequence" do
      expect(model).to receive(:execute).with(/ALTER TABLE "_test_table" ALTER COLUMN "test_column" DROP DEFAULT;\nDROP SEQUENCE IF EXISTS "_test_table_id_seq"/)

      model.drop_sequence(:_test_table, :test_column, :_test_table_id_seq)
    end
  end

  describe '#add_sequence' do
    it "executes the statement to add the sequence" do
      expect(model).to receive(:execute).with "CREATE SEQUENCE \"_test_table_id_seq\" START 1;\nALTER TABLE \"_test_table\" ALTER COLUMN \"test_column\" SET DEFAULT nextval(\'_test_table_id_seq\')\n"

      model.add_sequence(:_test_table, :test_column, :_test_table_id_seq, 1)
    end
  end

  describe '#remove_column_default' do
    let(:test_table) { :_test_defaults_table }
    let(:drop_default_statement) do
      /ALTER TABLE "#{test_table}" ALTER COLUMN "#{column_name}" SET DEFAULT NULL/
    end

    subject(:recorder) do
      ActiveRecord::QueryRecorder.new do
        model.remove_column_default(test_table, column_name)
      end
    end

    before do
      model.create_table(test_table) do |t|
        t.integer :int_with_default, default: 100
        t.integer :int_with_default_function, default: -> { 'ceil(random () * 100)::int' }
        t.integer :int_without_default
      end
    end

    context 'with default values' do
      let(:column_name) { :int_with_default }

      it { expect(recorder.log).to include(drop_default_statement) }
    end

    context 'with default functions' do
      let(:column_name) { :int_with_default_function }

      it { expect(recorder.log).to include(drop_default_statement) }
    end

    context 'without any defaults' do
      let(:column_name) { :int_without_default }

      it { expect(recorder.log).to be_empty }
    end
  end

  describe '#lock_tables' do
    subject(:recorder) do
      ActiveRecord::QueryRecorder.new { statement }
    end

    let(:statement) { model.lock_tables(:ci_builds, :ci_pipelines) }

    it 'locks the tables' do
      expect(recorder.log).to include(/LOCK TABLE "ci_builds", "ci_pipelines" IN ACCESS EXCLUSIVE MODE/)
    end

    context 'when only is provided' do
      let(:statement) { model.lock_tables(:p_ci_builds, only: true) }

      it 'locks the tables' do
        expect(recorder.log).to include(/LOCK TABLE ONLY "p_ci_builds" IN ACCESS EXCLUSIVE MODE/)
      end
    end

    context 'when nowait is provided' do
      let(:statement) { model.lock_tables(:p_ci_builds, nowait: true) }

      it 'locks the tables' do
        expect(recorder.log).to include(/LOCK TABLE "p_ci_builds" IN ACCESS EXCLUSIVE MODE NOWAIT/)
      end
    end
  end

  describe '#column_is_nullable?' do
    # This is defined as a private method of this module, and normally would not warrant
    # dedicated test coverage. But that being said, it has no test coverage at all (it's
    # only stubbed in the ConstraintsHelpers spec) so I'm adding testing here until we
    # figure out how to test it properly through the public methods that use it.

    context 'when a plain table name is passed' do
      subject { model.send(:column_is_nullable?, 'table_name', 'column_name') }

      it 'defaults to querying for the table defined in the current_schema' do
        expect(model.connection).to receive(:select_value)
          .with(/c\.table_schema = 'public'\s+AND c.table_name = 'table_name'\s+AND c.column_name = 'column_name'/)

        subject
      end
    end

    context 'when a table name is passed with a schema prefix' do
      subject { model.send(:column_is_nullable?, 'schema_prefix.table_name', 'column_name') }

      it 'correctly parses out the schema prefix and uses it instead of current_schema' do
        expect(model.connection).to receive(:select_value)
          .with(/c\.table_schema = 'schema_prefix'\s+AND c.table_name = 'table_name'\s+AND c.column_name = 'column_name'/)

        subject
      end
    end
  end

  describe 'bigint conversion helpers' do
    include MigrationsHelpers
    include Database::TriggerHelpers

    let(:migration_class) do
      Class.new(Gitlab::Database::Migration[2.2]) do
        milestone '17.4'
        restrict_gitlab_migration gitlab_schema: :gitlab_main

        def type_from_path(_)
          :regular
        end
      end
    end

    describe 'complete bigint conversion migration process' do
      let(:context) { migration_class.new }
      let(:table_name) { :_test_table }
      let(:model) { table(table_name) }
      let(:column_names) { [:id, :namespace_id, :traversal_ids, :parent_id] }
      let(:create_table) do
        migration_class.new.create_table table_name, id: false do |t|
          t.integer :id, primary_key: true
          t.integer :namespace_id, null: false
          t.integer :traversal_ids, null: false, array: true, default: []
          t.integer :parent_id
        end
      end

      before do
        allow_next_instance_of(migration_class) do |instance|
          allow(instance).to receive_messages(
            puts: nil,
            transaction_open?: false
          )
          allow(instance.connection).to receive_messages(
            puts: nil,
            transaction_open?: false
          )
        end
        # to prevent it from writing to the actual file
        stub_const(
          'Gitlab::Database::Migrations::Conversions::BigintConverter::YAML_FILE_PATH',
          'tmp/integer_ids_not_yet_initialized_to_bigint.yml'
        )
      end

      it 'correctly converts the integer columns to bigint' do
        create_table
        first_record = model.create!(namespace_id: 11, traversal_ids: [11], parent_id: nil)
        second_record = model.create!(namespace_id: 22, traversal_ids: [22], parent_id: 111)

        expect do
          migration_class.new.initialize_conversion_of_integer_to_bigint(table_name, column_names)
        end.to change { all_column_names }.to(
          include(
            *%w[id_convert_to_bigint namespace_id_convert_to_bigint traversal_ids_convert_to_bigint
              parent_id_convert_to_bigint]
          )
        )

        expect(context.column_for(table_name, :id_convert_to_bigint))
          .to have_attributes(
            sql_type: 'bigint',
            null: false,
            default: '0',
            array: false
          )
        expect(context.column_for(table_name, :namespace_id_convert_to_bigint))
          .to have_attributes(
            sql_type: 'bigint',
            null: false,
            default: '0',
            array: false
          )
        expect(context.column_for(table_name, :traversal_ids_convert_to_bigint))
          .to have_attributes(
            sql_type: 'bigint',
            null: false,
            default: '{}',
            array: true
          )
        expect(context.column_for(table_name, :parent_id_convert_to_bigint))
          .to have_attributes(
            sql_type: 'bigint',
            null: true,
            default: nil,
            array: false
          )

        model.reset_column_information

        expect(first_record.reload)
          .to have_attributes(
            id_convert_to_bigint: 0,
            namespace_id_convert_to_bigint: 0,
            traversal_ids_convert_to_bigint: [],
            parent_id_convert_to_bigint: nil
          )
        expect(second_record.reload)
          .to have_attributes(
            id_convert_to_bigint: 0,
            namespace_id_convert_to_bigint: 0,
            traversal_ids_convert_to_bigint: [],
            parent_id_convert_to_bigint: nil
          )

        expect do
          migration_class.new.backfill_conversion_of_integer_to_bigint(table_name, column_names)
        end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

        batched_migration = Gitlab::Database::BackgroundMigration::BatchedMigration.first
        expect(batched_migration)
          .to have_attributes(
            batch_class_name: 'PrimaryKeyBatchingStrategy',
            job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
            table_name: table_name.to_s,
            column_name: 'id',
            job_arguments: [
              %w[
                id namespace_id traversal_ids parent_id
              ], %w[
                id_convert_to_bigint namespace_id_convert_to_bigint
                traversal_ids_convert_to_bigint parent_id_convert_to_bigint
              ]
            ],
            batch_size: 20_000,
            sub_batch_size: 1000,
            pause_ms: 100,
            interval: 2.minutes
          )

        expect do
          migration_class.new.ensure_backfill_conversion_of_integer_to_bigint_is_finished(table_name, column_names)
        end.to change { batched_migration.reload.finalized? }.to(true)

        expect(first_record.reload)
          .to have_attributes(
            id_convert_to_bigint: 1,
            namespace_id_convert_to_bigint: 11,
            traversal_ids_convert_to_bigint: [11],
            parent_id_convert_to_bigint: nil
          )
        expect(second_record.reload)
          .to have_attributes(
            id_convert_to_bigint: 2,
            namespace_id_convert_to_bigint: 22,
            traversal_ids_convert_to_bigint: [22],
            parent_id_convert_to_bigint: 111
          )

        # Swap columns
        db_migration = migration_class.new.extend(Gitlab::Database::MigrationHelpers::Swapping)
        db_migration.add_index(table_name, :id_convert_to_bigint, name: :idx, unique: true)
        db_migration.swap_primary_key(table_name, :_test_table_pkey, :idx)
        db_migration.swap_columns(table_name, :id, :id_convert_to_bigint)
        db_migration.swap_columns_default(table_name, :id, :id_convert_to_bigint)
        db_migration.swap_columns(table_name, :namespace_id, :namespace_id_convert_to_bigint)
        db_migration.swap_columns_default(table_name, :namespace_id, :namespace_id_convert_to_bigint)
        db_migration.swap_columns(table_name, :traversal_ids, :traversal_ids_convert_to_bigint)
        db_migration.swap_columns_default(table_name, :traversal_ids, :traversal_ids_convert_to_bigint)
        db_migration.swap_columns(table_name, :parent_id, :parent_id_convert_to_bigint)
        db_migration.swap_columns_default(table_name, :parent_id, :parent_id_convert_to_bigint)

        expect do
          migration_class.new.cleanup_conversion_of_integer_to_bigint(table_name, column_names)
        end.to change { all_column_names }.to(
          not_include(
            *%w[
              id_convert_to_bigint namespace_id_convert_to_bigint
              traversal_ids_convert_to_bigint parent_id_convert_to_bigint
            ]
          )
        )

        expect(context.column_for(table_name, :id))
          .to have_attributes(
            sql_type: 'bigint',
            null: false,
            default: nil,
            array: false
          )
        expect(context.column_for(table_name, :namespace_id))
          .to have_attributes(
            sql_type: 'bigint',
            null: false,
            default: nil,
            array: false
          )
        expect(context.column_for(table_name, :traversal_ids))
          .to have_attributes(
            sql_type: 'bigint',
            null: false,
            default: '{}',
            array: true
          )
        expect(context.column_for(table_name, :parent_id))
          .to have_attributes(
            sql_type: 'bigint',
            null: true,
            default: nil,
            array: false
          )

        model.reset_column_information

        expect(first_record.reload)
          .to have_attributes(
            id: 1,
            namespace_id: 11,
            traversal_ids: [11],
            parent_id: nil
          )
        expect(second_record.reload)
          .to have_attributes(
            id: 2,
            namespace_id: 22,
            traversal_ids: [22],
            parent_id: 111
          )

        expect do
          migration_class.new.restore_conversion_of_integer_to_bigint(table_name, column_names)
        end.to change { all_column_names }.to(
          include(
            *%w[
              id_convert_to_bigint namespace_id_convert_to_bigint
              traversal_ids_convert_to_bigint parent_id_convert_to_bigint
            ]
          )
        )

        expect(context.column_for(table_name, :id_convert_to_bigint))
          .to have_attributes(
            sql_type: 'integer',
            null: false,
            default: '0',
            array: false
          )
        expect(context.column_for(table_name, :namespace_id_convert_to_bigint))
          .to have_attributes(
            sql_type: 'integer',
            null: false,
            default: '0',
            array: false
          )
        expect(context.column_for(table_name, :traversal_ids_convert_to_bigint))
          .to have_attributes(
            sql_type: 'integer',
            null: false,
            default: '{}',
            array: true
          )
        expect(context.column_for(table_name, :parent_id_convert_to_bigint))
          .to have_attributes(
            sql_type: 'integer',
            null: true,
            default: nil,
            array: false
          )
      end

      context 'when all of them are bigint' do
        let(:create_table) do
          migration_class.new.create_table table_name, id: false do |t|
            t.bigint :id, primary_key: true
            t.bigint :namespace_id, null: false
            t.bigint :traversal_ids, null: false, array: true, default: []
            t.bigint :parent_id
          end
        end

        it 'executes the migrations with doing nothing' do
          create_table
          model.create!(namespace_id: 11, traversal_ids: [11], parent_id: nil)
          model.create!(namespace_id: 22, traversal_ids: [22], parent_id: 111)

          expect do
            migration_class.new.initialize_conversion_of_integer_to_bigint(table_name, column_names)
          end.not_to change { all_column_names }

          expect do
            migration_class.new.backfill_conversion_of_integer_to_bigint(table_name, column_names)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          expect do
            migration_class.new.ensure_backfill_conversion_of_integer_to_bigint_is_finished(table_name, column_names)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.first.human_status_name }.to('finalized')

          expect do
            migration_class.new.revert_backfill_conversion_of_integer_to_bigint(table_name, column_names)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(-1)

          expect do
            migration_class.new.cleanup_conversion_of_integer_to_bigint(table_name, column_names)
          end.not_to change { all_column_names }
        end
      end

      context 'when there are both integer and bigint columns' do
        let(:create_table) do
          migration_class.new.create_table table_name, id: false do |t|
            t.bigint :id, primary_key: true
            t.integer :namespace_id, null: false
            t.integer :traversal_ids, null: false, array: true, default: []
            t.bigint :parent_id
          end
        end

        it 'correctly converts the integer columns to bigint' do
          create_table
          first_record = model.create!(namespace_id: 11, traversal_ids: [11], parent_id: nil)
          second_record = model.create!(namespace_id: 22, traversal_ids: [22], parent_id: 111)

          expect do
            migration_class.new.initialize_conversion_of_integer_to_bigint(table_name, column_names)
          end.to change { all_column_names }.to(
            include(
              *%w[namespace_id_convert_to_bigint traversal_ids_convert_to_bigint]
            )
          )

          expect(context.column_for(table_name, :namespace_id_convert_to_bigint))
            .to have_attributes(
              sql_type: 'bigint',
              null: false,
              default: '0',
              array: false
            )
          expect(context.column_for(table_name, :traversal_ids_convert_to_bigint))
            .to have_attributes(
              sql_type: 'bigint',
              null: false,
              default: '{}',
              array: true
            )

          model.reset_column_information

          expect(first_record.reload)
            .to have_attributes(
              namespace_id_convert_to_bigint: 0,
              traversal_ids_convert_to_bigint: []
            )
          expect(second_record.reload)
            .to have_attributes(
              namespace_id_convert_to_bigint: 0,
              traversal_ids_convert_to_bigint: []
            )

          expect do
            migration_class.new.backfill_conversion_of_integer_to_bigint(table_name, column_names)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          batched_migration = Gitlab::Database::BackgroundMigration::BatchedMigration.first
          expect(batched_migration)
            .to have_attributes(
              batch_class_name: 'PrimaryKeyBatchingStrategy',
              job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
              table_name: table_name.to_s,
              column_name: 'id',
              job_arguments: [
                %w[
                  id namespace_id traversal_ids parent_id
                ], %w[
                  id_convert_to_bigint namespace_id_convert_to_bigint
                  traversal_ids_convert_to_bigint parent_id_convert_to_bigint
                ]
              ],
              batch_size: 20_000,
              sub_batch_size: 1000,
              pause_ms: 100,
              interval: 2.minutes
            )

          expect do
            migration_class.new.ensure_backfill_conversion_of_integer_to_bigint_is_finished(table_name, column_names)
          end.to change { batched_migration.reload.finalized? }.to(true)

          expect(first_record.reload)
            .to have_attributes(
              namespace_id_convert_to_bigint: 11,
              traversal_ids_convert_to_bigint: [11]
            )
          expect(second_record.reload)
            .to have_attributes(
              namespace_id_convert_to_bigint: 22,
              traversal_ids_convert_to_bigint: [22]
            )

          # Swap columns
          db_migration = migration_class.new.extend(Gitlab::Database::MigrationHelpers::Swapping)
          db_migration.swap_columns(table_name, :namespace_id, :namespace_id_convert_to_bigint)
          db_migration.swap_columns_default(table_name, :namespace_id, :namespace_id_convert_to_bigint)
          db_migration.swap_columns(table_name, :traversal_ids, :traversal_ids_convert_to_bigint)
          db_migration.swap_columns_default(table_name, :traversal_ids, :traversal_ids_convert_to_bigint)

          expect do
            migration_class.new.cleanup_conversion_of_integer_to_bigint(table_name, column_names)
          end.to change { all_column_names }.to(
            not_include(
              *%w[namespace_id_convert_to_bigint traversal_ids_convert_to_bigint]
            )
          )

          expect(context.column_for(table_name, :id))
            .to have_attributes(
              sql_type: 'bigint',
              null: false,
              default: nil,
              array: false
            )
          expect(context.column_for(table_name, :namespace_id))
            .to have_attributes(
              sql_type: 'bigint',
              null: false,
              default: nil,
              array: false
            )
          expect(context.column_for(table_name, :traversal_ids))
            .to have_attributes(
              sql_type: 'bigint',
              null: false,
              default: '{}',
              array: true
            )
          expect(context.column_for(table_name, :parent_id))
            .to have_attributes(
              sql_type: 'bigint',
              null: true,
              default: nil,
              array: false
            )

          model.reset_column_information

          expect(first_record.reload)
            .to have_attributes(
              namespace_id: 11,
              traversal_ids: [11]
            )
          expect(second_record.reload)
            .to have_attributes(
              namespace_id: 22,
              traversal_ids: [22]
            )
        end
      end

      context <<~DESCRIPTION do
        when the initialization and backfill have started
        for columns which are integer on gitlab.com but bigint on self-managed instance
        before this change is introduce
      DESCRIPTION
        let(:create_table) do
          migration_class.new.create_table table_name, id: false do |t|
            t.bigint :id, primary_key: true
            t.integer :namespace_id, null: false
            t.integer :traversal_ids, null: false, array: true, default: []
            t.integer :parent_id
            t.integer :duration
          end
        end

        let(:column_names) { [:namespace_id, :traversal_ids, :parent_id, :duration] }

        it 'correctly converts the integer columns to bigint' do
          create_table
          first_record = model.create!(namespace_id: 11, traversal_ids: [11], parent_id: nil, duration: 888)
          second_record = model.create!(namespace_id: 22, traversal_ids: [22], parent_id: 111, duration: 999)

          expect do
            migration_class.new.initialize_conversion_of_integer_to_bigint(table_name, column_names)
          end.to change { all_column_names }.to(
            include(
              *%w[
                namespace_id_convert_to_bigint traversal_ids_convert_to_bigint
                parent_id_convert_to_bigint duration_convert_to_bigint
              ]
            )
          )

          expect(context.column_for(table_name, :namespace_id_convert_to_bigint))
            .to have_attributes(
              sql_type: 'bigint',
              null: false,
              default: '0',
              array: false
            )
          expect(context.column_for(table_name, :traversal_ids_convert_to_bigint))
            .to have_attributes(
              sql_type: 'bigint',
              null: false,
              default: '{}',
              array: true
            )
          expect(context.column_for(table_name, :parent_id_convert_to_bigint))
            .to have_attributes(
              sql_type: 'bigint',
              null: true,
              default: nil,
              array: false
            )
          expect(context.column_for(table_name, :duration_convert_to_bigint))
            .to have_attributes(
              sql_type: 'bigint',
              null: true,
              default: nil,
              array: false
            )

          model.reset_column_information

          expect(first_record.reload)
            .to have_attributes(
              namespace_id_convert_to_bigint: 0,
              traversal_ids_convert_to_bigint: [],
              parent_id_convert_to_bigint: nil,
              duration_convert_to_bigint: nil
            )
          expect(second_record.reload)
            .to have_attributes(
              namespace_id_convert_to_bigint: 0,
              traversal_ids_convert_to_bigint: [],
              parent_id_convert_to_bigint: nil,
              duration_convert_to_bigint: nil
            )

          expect do
            migration_class.new.backfill_conversion_of_integer_to_bigint(table_name, column_names)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          batched_migration = Gitlab::Database::BackgroundMigration::BatchedMigration.first
          expect(batched_migration)
            .to have_attributes(
              batch_class_name: 'PrimaryKeyBatchingStrategy',
              job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
              table_name: table_name.to_s,
              column_name: 'id',
              job_arguments: [
                %w[
                  namespace_id traversal_ids parent_id duration
                ], %w[
                  namespace_id_convert_to_bigint traversal_ids_convert_to_bigint
                  parent_id_convert_to_bigint duration_convert_to_bigint
                ]
              ],
              batch_size: 20_000,
              sub_batch_size: 1000,
              pause_ms: 100,
              interval: 2.minutes
            )

          db_migration = migration_class.new.extend(Gitlab::Database::MigrationHelpers::Swapping)
          # Change the integer columns to bigint for self-managed
          db_migration.change_column(table_name, :namespace_id, :bigint, null: false)
          db_migration.change_column(table_name, :traversal_ids, :bigint, null: false, array: true, default: [])
          db_migration.change_column(table_name, :parent_id, :bigint)

          expect do
            migration_class.new.ensure_backfill_conversion_of_integer_to_bigint_is_finished(table_name, column_names)
          end.to change { batched_migration.reload.finalized? }.to(true)

          expect(first_record.reload)
            .to have_attributes(
              namespace_id_convert_to_bigint: 11,
              traversal_ids_convert_to_bigint: [11],
              parent_id_convert_to_bigint: nil,
              duration_convert_to_bigint: 888
            )
          expect(second_record.reload)
            .to have_attributes(
              namespace_id_convert_to_bigint: 22,
              traversal_ids_convert_to_bigint: [22],
              parent_id_convert_to_bigint: 111,
              duration_convert_to_bigint: 999
            )

          # Swap columns
          db_migration.swap_columns(table_name, :duration, :duration_convert_to_bigint)
          db_migration.swap_columns_default(table_name, :duration, :duration_convert_to_bigint)

          expect do
            migration_class.new.cleanup_conversion_of_integer_to_bigint(table_name, column_names)
          end.to change { all_column_names }.to(
            not_include(
              *%w[
                namespace_id_convert_to_bigint traversal_ids_convert_to_bigint
                parent_id_convert_to_bigint duration_convert_to_bigint
              ]
            )
          )

          expect(context.column_for(table_name, :id))
            .to have_attributes(
              sql_type: 'bigint',
              null: false,
              default: nil,
              array: false
            )
          expect(context.column_for(table_name, :namespace_id))
            .to have_attributes(
              sql_type: 'bigint',
              null: false,
              default: nil,
              array: false
            )
          expect(context.column_for(table_name, :traversal_ids))
            .to have_attributes(
              sql_type: 'bigint',
              null: false,
              default: '{}',
              array: true
            )
          expect(context.column_for(table_name, :parent_id))
            .to have_attributes(
              sql_type: 'bigint',
              null: true,
              default: nil,
              array: false
            )

          model.reset_column_information

          expect(first_record.reload)
            .to have_attributes(
              namespace_id: 11,
              traversal_ids: [11],
              parent_id: nil,
              duration: 888
            )
          expect(second_record.reload)
            .to have_attributes(
              namespace_id: 22,
              traversal_ids: [22],
              parent_id: 111,
              duration: 999
            )
        end
      end
    end

    describe '#initialize_conversion_of_integer_to_bigint' do
      it 'calls the converter' do
        expect_next_instance_of(Gitlab::Database::Migrations::Conversions::BigintConverter) do |instance|
          expect(instance).to receive(:init)
        end
        migration_class.new.initialize_conversion_of_integer_to_bigint('a_table', %w[column1 column2])
      end
    end

    describe '#restore_conversion_of_integer_to_bigint' do
      it 'calls the converter' do
        expect_next_instance_of(Gitlab::Database::Migrations::Conversions::BigintConverter) do |instance|
          expect(instance).to receive(:restore_cleanup)
        end
        migration_class.new.restore_conversion_of_integer_to_bigint('a_table', %w[column1 column2])
      end
    end

    describe '#revert_initialize_conversion_of_integer_to_bigint' do
      it 'calls the converter' do
        expect_next_instance_of(Gitlab::Database::Migrations::Conversions::BigintConverter) do |instance|
          expect(instance).to receive(:revert_init)
        end
        migration_class.new.revert_initialize_conversion_of_integer_to_bigint('a_table', %w[column1 column2])
      end
    end

    describe '#cleanup_conversion_of_integer_to_bigint' do
      it 'calls the converter' do
        expect_next_instance_of(Gitlab::Database::Migrations::Conversions::BigintConverter) do |instance|
          expect(instance).to receive(:cleanup)
        end
        migration_class.new.cleanup_conversion_of_integer_to_bigint('a_table', %w[column1 column2])
      end
    end

    describe '#backfill_conversion_of_integer_to_bigint' do
      it 'calls the converter' do
        expect_next_instance_of(Gitlab::Database::Migrations::Conversions::BigintConverter) do |instance|
          expect(instance).to receive(:backfill).with(
            batch_size: 20000, job_interval: 2.minutes, pause_ms: 100, primary_key: :id, sub_batch_size: 1000
          )
        end
        migration_class.new.backfill_conversion_of_integer_to_bigint('a_table', %w[column1 column2])
      end
    end

    describe '#ensure_backfill_conversion_of_integer_to_bigint_is_finished' do
      it 'calls the converter' do
        expect_next_instance_of(Gitlab::Database::Migrations::Conversions::BigintConverter) do |instance|
          expect(instance).to receive(:ensure_backfill).with(primary_key: :id)
        end
        migration_class.new.ensure_backfill_conversion_of_integer_to_bigint_is_finished('a_table', %w[column1 column2])
      end
    end

    describe '#revert_backfill_conversion_of_integer_to_bigint' do
      it 'calls the converter' do
        expect_next_instance_of(Gitlab::Database::Migrations::Conversions::BigintConverter) do |instance|
          expect(instance).to receive(:revert_backfill).with(primary_key: :id)
        end
        migration_class.new.revert_backfill_conversion_of_integer_to_bigint('a_table', %w[column1 column2])
      end
    end

    private

    def all_column_names
      context.columns(table_name).map(&:name)
    end
  end
end
