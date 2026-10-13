# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::SwapColumns, feature_category: :database do
  describe '#execute' do
    let(:connection) { ApplicationRecord.connection }
    let(:sql) do
      <<~SQL
        CREATE TABLE #{table} (
          id integer NOT NULL,
          #{column1} integer DEFAULT 8 NOT NULL,
          #{column2} bigint DEFAULT 100 NOT NULL
        );
      SQL
    end

    let(:migration_context) do
      Gitlab::Database::Migration[2.1]
        .new('name', 'version')
        .extend(Gitlab::Database::MigrationHelpers::Swapping)
    end

    let(:table) { :_test_swap_columns_and_defaults }
    let(:column1) { :integer_column }
    let(:column2) { :bigint_column }

    subject(:execute_service) do
      described_class.new(
        migration_context: migration_context,
        table: table,
        column1: column1,
        column2: column2
      ).execute
    end

    before do
      connection.execute(sql)
    end

    shared_examples_for 'swapping columns correctly' do
      specify do
        expect { execute_service }
          .to change { find_column_by(column1).sql_type }.from('integer').to('bigint')
          .and change { find_column_by(column2).sql_type }.from('bigint').to('integer')
      end
    end

    it_behaves_like 'swapping columns correctly'

    context 'when column names are 63 bytes' do
      let(:column1) { :int012345678901234567890123456789012345678901234567890123456789 }
      let(:column2) { :big012345678901234567890123456789012345678901234567890123456789 }

      it_behaves_like 'swapping columns correctly'
    end

    context 'with a column-specific trigger on a swapped column' do
      let(:trigger_name) { :_test_swap_columns_trigger }
      let(:function_name) { :_test_swap_columns_trigger_fn }

      before do
        connection.execute(<<~SQL)
          CREATE FUNCTION #{function_name}() RETURNS trigger AS $$
          BEGIN
            RETURN NULL;
          END $$ LANGUAGE plpgsql;

          CREATE TRIGGER #{trigger_name}
            AFTER INSERT OR UPDATE OF #{column1}, id ON #{table}
            FOR EACH ROW EXECUTE FUNCTION #{function_name}();
        SQL
      end

      it_behaves_like 'swapping columns correctly'

      it 'keeps the trigger bound to the original column names' do
        expect { execute_service }.not_to change { trigger_definition }

        expect(trigger_definition).to include("UPDATE OF #{column1}, id")
      end
    end

    context 'with a trigger whose WHEN clause references a swapped column' do
      let(:trigger_name) { :_test_swap_columns_when_trigger }
      let(:function_name) { :_test_swap_columns_when_fn }

      before do
        connection.execute(<<~SQL)
          CREATE FUNCTION #{function_name}() RETURNS trigger AS $$
          BEGIN
            RETURN NULL;
          END $$ LANGUAGE plpgsql;

          CREATE TRIGGER #{trigger_name}
            AFTER UPDATE ON #{table}
            FOR EACH ROW
            WHEN (NEW.#{column1} IS DISTINCT FROM OLD.#{column1})
            EXECUTE FUNCTION #{function_name}();
        SQL
      end

      it_behaves_like 'swapping columns correctly'

      # The trigger has no `UPDATE OF` list, so it is only found through its `WHEN` clause.
      it 'keeps the WHEN clause bound to the original column names' do
        expect { execute_service }.not_to change { trigger_definition }

        expect(trigger_definition).to include("new.#{column1} IS DISTINCT FROM old.#{column1}")
      end
    end

    context 'with a column-specific trigger on an unrelated column' do
      let(:trigger_name) { :_test_swap_columns_unrelated_trigger }
      let(:function_name) { :_test_swap_columns_unrelated_fn }

      before do
        connection.execute(<<~SQL)
          CREATE FUNCTION #{function_name}() RETURNS trigger AS $$
          BEGIN
            RETURN NULL;
          END $$ LANGUAGE plpgsql;

          CREATE TRIGGER #{trigger_name}
            AFTER UPDATE OF id ON #{table}
            FOR EACH ROW EXECUTE FUNCTION #{function_name}();
        SQL
      end

      it 'is left untouched' do
        expect { execute_service }.not_to change { trigger_definition }
      end
    end

    context 'with a trigger that is not column-specific' do
      let(:trigger_name) { :_test_swap_columns_all_columns_trigger }
      let(:function_name) { :_test_swap_columns_all_columns_fn }

      before do
        connection.execute(<<~SQL)
          CREATE FUNCTION #{function_name}() RETURNS trigger AS $$
          BEGIN
            RETURN NEW;
          END $$ LANGUAGE plpgsql;

          CREATE TRIGGER #{trigger_name}
            BEFORE INSERT OR UPDATE ON #{table}
            FOR EACH ROW EXECUTE FUNCTION #{function_name}();
        SQL
      end

      it 'is left untouched' do
        expect { execute_service }.not_to change { trigger_definition }
      end
    end

    context 'with a column-specific trigger on a partitioned table' do
      let(:table) { :_test_swap_columns_partitioned }
      let(:partition) { :_test_swap_columns_partition_1 }
      let(:trigger_name) { :_test_swap_columns_partitioned_trigger }
      let(:function_name) { :_test_swap_columns_partitioned_fn }
      let(:sql) do
        <<~SQL
          CREATE TABLE #{table} (
            id integer NOT NULL,
            #{column1} integer DEFAULT 8 NOT NULL,
            #{column2} bigint DEFAULT 100 NOT NULL
          ) PARTITION BY RANGE (id);

          CREATE TABLE #{partition} PARTITION OF #{table} FOR VALUES FROM (0) TO (100);
        SQL
      end

      before do
        connection.execute(<<~SQL)
          CREATE FUNCTION #{function_name}() RETURNS trigger AS $$
          BEGIN
            RETURN NULL;
          END $$ LANGUAGE plpgsql;

          CREATE TRIGGER #{trigger_name}
            AFTER UPDATE OF #{column1} ON #{table}
            FOR EACH ROW EXECUTE FUNCTION #{function_name}();
        SQL
      end

      it_behaves_like 'swapping columns correctly'

      # The clone is not among the definitions that get replayed: `CREATE OR REPLACE TRIGGER`
      # on the parent recurses into it.
      it 'keeps the trigger on the partition bound to the original column names' do
        expect { execute_service }.not_to change { trigger_definition(partition) }

        expect(trigger_definition(partition)).to include("UPDATE OF #{column1}")
      end
    end

    context 'with a trigger that uses a non-default firing mode' do
      let(:trigger_name) { :_test_swap_columns_mode_trigger }
      let(:function_name) { :_test_swap_columns_mode_fn }

      before do
        connection.execute(<<~SQL)
          CREATE FUNCTION #{function_name}() RETURNS trigger AS $$
          BEGIN
            RETURN NULL;
          END $$ LANGUAGE plpgsql;

          CREATE TRIGGER #{trigger_name}
            AFTER UPDATE OF #{column1} ON #{table}
            FOR EACH ROW EXECUTE FUNCTION #{function_name}();

          ALTER TABLE #{table} #{mode_statement} TRIGGER #{trigger_name};
        SQL
      end

      context 'when the trigger is set to ENABLE ALWAYS' do
        let(:mode_statement) { 'ENABLE ALWAYS' }

        it_behaves_like 'swapping columns correctly'

        it 'keeps the firing mode' do
          expect { execute_service }.not_to change { firing_mode(table) }.from('A')
        end
      end

      context 'when the trigger is set to ENABLE REPLICA' do
        let(:mode_statement) { 'ENABLE REPLICA' }

        it 'keeps the firing mode' do
          expect { execute_service }.not_to change { firing_mode(table) }.from('R')
        end
      end

      context 'when the trigger is disabled' do
        let(:mode_statement) { 'DISABLE' }

        it 'keeps the firing mode' do
          expect { execute_service }.not_to change { firing_mode(table) }.from('D')
        end
      end
    end

    context 'when only a sub-partition clone uses a non-default firing mode' do
      let(:table) { :_test_swap_columns_partitioned_mode }
      let(:sub_partition) { :_test_swap_columns_partition_mode_sub }
      let(:leaf_partition) { :_test_swap_columns_partition_mode_leaf }
      let(:trigger_name) { :_test_swap_columns_partitioned_mode_trigger }
      let(:function_name) { :_test_swap_columns_partitioned_mode_fn }
      let(:sql) do
        <<~SQL
          CREATE TABLE #{table} (
            id integer NOT NULL,
            #{column1} integer DEFAULT 8 NOT NULL,
            #{column2} bigint DEFAULT 100 NOT NULL
          ) PARTITION BY RANGE (id);

          CREATE TABLE #{sub_partition} PARTITION OF #{table}
            FOR VALUES FROM (0) TO (100) PARTITION BY RANGE (id);

          CREATE TABLE #{leaf_partition} PARTITION OF #{sub_partition} FOR VALUES FROM (0) TO (50);
        SQL
      end

      before do
        connection.execute(<<~SQL)
          CREATE FUNCTION #{function_name}() RETURNS trigger AS $$
          BEGIN
            RETURN NULL;
          END $$ LANGUAGE plpgsql;

          CREATE TRIGGER #{trigger_name}
            AFTER UPDATE OF #{column1} ON #{table}
            FOR EACH ROW EXECUTE FUNCTION #{function_name}();

          ALTER TABLE #{leaf_partition} ENABLE REPLICA TRIGGER #{trigger_name};
        SQL
      end

      it_behaves_like 'swapping columns correctly'

      # The leaf clone's parent is the clone on the sub-partition, not the trigger being
      # swapped, so only a recursive walk reaches it.
      it 'keeps the firing mode of the leaf clone' do
        expect { execute_service }.not_to change { firing_mode(leaf_partition) }.from('R')
      end

      it 'leaves the other relations in the default firing mode' do
        execute_service

        expect(firing_mode(table)).to eq('O')
        expect(firing_mode(sub_partition)).to eq('O')
      end
    end

    context 'when a partitioned table and one of its clones use different firing modes' do
      # Named so the clone sorts before the parent, which is the restore order that would let
      # the parent's recursion overwrite the clone.
      let(:table) { :_test_swap_columns_modes_parent }
      let(:partition) { :_test_swap_columns_modes_child }
      let(:trigger_name) { :_test_swap_columns_mixed_modes_trigger }
      let(:function_name) { :_test_swap_columns_mixed_modes_fn }
      let(:sql) do
        <<~SQL
          CREATE TABLE #{table} (
            id integer NOT NULL,
            #{column1} integer DEFAULT 8 NOT NULL,
            #{column2} bigint DEFAULT 100 NOT NULL
          ) PARTITION BY RANGE (id);

          CREATE TABLE #{partition} PARTITION OF #{table} FOR VALUES FROM (0) TO (100);
        SQL
      end

      before do
        connection.execute(<<~SQL)
          CREATE FUNCTION #{function_name}() RETURNS trigger AS $$
          BEGIN
            RETURN NULL;
          END $$ LANGUAGE plpgsql;

          CREATE TRIGGER #{trigger_name}
            AFTER UPDATE OF #{column1} ON #{table}
            FOR EACH ROW EXECUTE FUNCTION #{function_name}();

          ALTER TABLE ONLY #{table} ENABLE ALWAYS TRIGGER #{trigger_name};
          ALTER TABLE ONLY #{partition} ENABLE REPLICA TRIGGER #{trigger_name};
        SQL
      end

      it 'keeps both firing modes' do
        execute_service

        expect(firing_mode(table)).to eq('A')
        expect(firing_mode(partition)).to eq('R')
      end
    end

    context 'when called outside a transaction' do
      before do
        allow(migration_context).to receive(:transaction_open?).and_return(false)
      end

      it 'raises without renaming any columns' do
        expect { execute_service }
          .to raise_error(/outside a transaction/)
          .and not_change { find_column_by(column1).sql_type }
      end
    end

    context 'with a constraint trigger on a swapped column' do
      let(:trigger_name) { :_test_swap_columns_constraint_trigger }
      let(:function_name) { :_test_swap_columns_constraint_fn }

      before do
        connection.execute(<<~SQL)
          CREATE FUNCTION #{function_name}() RETURNS trigger AS $$
          BEGIN
            RETURN NULL;
          END $$ LANGUAGE plpgsql;

          CREATE CONSTRAINT TRIGGER #{trigger_name}
            AFTER UPDATE OF #{column1} ON #{table}
            FOR EACH ROW EXECUTE FUNCTION #{function_name}();
        SQL
      end

      it 'raises without renaming any columns' do
        expect { execute_service }
          .to raise_error(/constraint trigger\(s\) #{trigger_name}/)
          .and not_change { find_column_by(column1).sql_type }

        expect(find_column_by(column2).sql_type).to eq('bigint')
      end
    end

    private

    def find_column_by(name)
      connection.columns(table).find { |c| c.name == name.to_s }
    end

    def trigger_definition(on_table = table)
      connection.select_value(<<~SQL)
        SELECT pg_get_triggerdef(oid)
        FROM pg_trigger
        WHERE tgrelid = '#{on_table}'::regclass AND tgname = '#{trigger_name}'
      SQL
    end

    def firing_mode(on_table)
      connection.select_value(<<~SQL)
        SELECT tgenabled
        FROM pg_trigger
        WHERE tgrelid = '#{on_table}'::regclass AND tgname = '#{trigger_name}'
      SQL
    end
  end
end
