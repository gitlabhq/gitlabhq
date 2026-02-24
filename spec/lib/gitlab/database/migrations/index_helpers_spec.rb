# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::IndexHelpers, feature_category: :database do
  let(:model) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  before do
    allow(model).to receive(:puts)
  end

  describe '#add_concurrent_index' do
    context 'when outside a transaction' do
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

    context 'when inside a transaction' do
      it 'raises RuntimeError' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect { model.add_concurrent_index(:users, :foo) }
          .to raise_error(RuntimeError)
      end
    end
  end

  describe '#remove_concurrent_index' do
    context 'when outside a transaction' do
      before do
        allow(model).to receive_messages(transaction_open?: false, index_exists?: true)
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
      end
    end

    context 'when inside a transaction' do
      it 'raises RuntimeError' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect { model.remove_concurrent_index(:users, :foo) }
          .to raise_error(RuntimeError)
      end
    end
  end

  describe '#remove_concurrent_index_by_name' do
    before do
      allow(model).to receive_messages(transaction_open?: false, index_exists?: true)
      allow(model).to receive(:disable_statement_timeout).and_call_original
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
