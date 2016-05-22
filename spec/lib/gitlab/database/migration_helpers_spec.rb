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
      end

      context 'using PostgreSQL' do
        it 'creates the index concurrently' do
          expect(Gitlab::Database).to receive(:postgresql?).and_return(true)

          expect(model).to receive(:add_index).
            with(:users, :foo, algorithm: :concurrently)

          model.add_concurrent_index(:users, :foo)
        end
      end

      context 'using MySQL' do
        it 'creates a regular index' do
          expect(Gitlab::Database).to receive(:postgresql?).and_return(false)

          expect(model).to receive(:add_index).
            with(:users, :foo)

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
  end

  describe '#add_column_with_default' do
    context 'outside of a transaction' do
      before do
        expect(model).to receive(:transaction_open?).and_return(false)

        expect(model).to receive(:transaction).twice.and_yield

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
