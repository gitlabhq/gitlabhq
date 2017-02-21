require 'spec_helper'

describe Gitlab::Database::MigrationHelpers, lib: true do
  let(:model) do
    ActiveRecord::Migration.new.extend(
      Gitlab::Database::MigrationHelpers
    )
  end

  before { allow(model).to receive(:puts) }

  describe '#add_concurrent_index' do
    context 'outside a transaction' do
      before do
        expect(model).to receive(:transaction_open?).and_return(false)

        unless Gitlab::Database.postgresql?
          allow_any_instance_of(Gitlab::Database::MigrationHelpers).to receive(:disable_statement_timeout)
        end
      end

      context 'using PostgreSQL' do
        before { expect(Gitlab::Database).to receive(:postgresql?).and_return(true) }

        it 'creates the index concurrently' do
          expect(model).to receive(:add_index).
            with(:users, :foo, algorithm: :concurrently)

          model.add_concurrent_index(:users, :foo)
        end

        it 'creates unique index concurrently' do
          expect(model).to receive(:add_index).
            with(:users, :foo, { algorithm: :concurrently, unique: true })

          model.add_concurrent_index(:users, :foo, unique: true)
        end
      end

      context 'using MySQL' do
        it 'creates a regular index' do
          expect(Gitlab::Database).to receive(:postgresql?).and_return(false)

          expect(model).to receive(:add_index).
            with(:users, :foo, {})

          model.add_concurrent_index(:users, :foo)
        end
      end
    end

    context 'inside a transaction' do
      it 'raises RuntimeError' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect { model.add_concurrent_index(:users, :foo) }.
          to raise_error(RuntimeError)
      end
    end
  end

  describe '#add_concurrent_foreign_key' do
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

      context 'using MySQL' do
        it 'creates a regular foreign key' do
          allow(Gitlab::Database).to receive(:mysql?).and_return(true)

          expect(model).to receive(:add_foreign_key).
            with(:projects, :users, column: :user_id, on_delete: :cascade)

          model.add_concurrent_foreign_key(:projects, :users, column: :user_id)
        end
      end

      context 'using PostgreSQL' do
        before do
          allow(Gitlab::Database).to receive(:mysql?).and_return(false)
        end

        it 'creates a concurrent foreign key' do
          expect(model).to receive(:disable_statement_timeout)
          expect(model).to receive(:execute).ordered.with(/NOT VALID/)
          expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)

          model.add_concurrent_foreign_key(:projects, :users, column: :user_id)
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
  end

  describe '#disable_statement_timeout' do
    context 'using PostgreSQL' do
      it 'disables statement timeouts' do
        expect(Gitlab::Database).to receive(:postgresql?).and_return(true)

        expect(model).to receive(:execute).with('SET statement_timeout TO 0')

        model.disable_statement_timeout
      end
    end

    context 'using MySQL' do
      it 'does nothing' do
        expect(Gitlab::Database).to receive(:postgresql?).and_return(false)

        expect(model).not_to receive(:execute)

        model.disable_statement_timeout
      end
    end
  end

  describe '#update_column_in_batches' do
    before do
      create_list(:empty_project, 5)
    end

    it 'updates all the rows in a table' do
      model.update_column_in_batches(:projects, :import_error, 'foo')

      expect(Project.where(import_error: 'foo').count).to eq(5)
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
  end

  describe '#add_column_with_default' do
    context 'outside of a transaction' do
      context 'when a column limit is not set' do
        before do
          expect(model).to receive(:transaction_open?).and_return(false)

          expect(model).to receive(:transaction).and_yield

          expect(model).to receive(:add_column).
            with(:projects, :foo, :integer, default: nil)

          expect(model).to receive(:change_column_default).
            with(:projects, :foo, 10)
        end

        it 'adds the column while allowing NULL values' do
          expect(model).to receive(:update_column_in_batches).
            with(:projects, :foo, 10)

          expect(model).not_to receive(:change_column_null)

          model.add_column_with_default(:projects, :foo, :integer,
                                        default: 10,
                                        allow_null: true)
        end

        it 'adds the column while not allowing NULL values' do
          expect(model).to receive(:update_column_in_batches).
            with(:projects, :foo, 10)

          expect(model).to receive(:change_column_null).
            with(:projects, :foo, false)

          model.add_column_with_default(:projects, :foo, :integer, default: 10)
        end

        it 'removes the added column whenever updating the rows fails' do
          expect(model).to receive(:update_column_in_batches).
            with(:projects, :foo, 10).
            and_raise(RuntimeError)

          expect(model).to receive(:remove_column).
            with(:projects, :foo)

          expect do
            model.add_column_with_default(:projects, :foo, :integer, default: 10)
          end.to raise_error(RuntimeError)
        end

        it 'removes the added column whenever changing a column NULL constraint fails' do
          expect(model).to receive(:change_column_null).
            with(:projects, :foo, false).
            and_raise(RuntimeError)

          expect(model).to receive(:remove_column).
            with(:projects, :foo)

          expect do
            model.add_column_with_default(:projects, :foo, :integer, default: 10)
          end.to raise_error(RuntimeError)
        end
      end

      context 'when a column limit is set' do
        it 'adds the column with a limit' do
          allow(model).to receive(:transaction_open?).and_return(false)
          allow(model).to receive(:transaction).and_yield
          allow(model).to receive(:update_column_in_batches).with(:projects, :foo, 10)
          allow(model).to receive(:change_column_null).with(:projects, :foo, false)
          allow(model).to receive(:change_column_default).with(:projects, :foo, 10)

          expect(model).to receive(:add_column).
            with(:projects, :foo, :integer, default: nil, limit: 8)

          model.add_column_with_default(:projects, :foo, :integer, default: 10, limit: 8)
        end
      end
    end

    context 'inside a transaction' do
      it 'raises RuntimeError' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect do
          model.add_column_with_default(:projects, :foo, :integer, default: 10)
        end.to raise_error(RuntimeError)
      end
    end
  end
end
