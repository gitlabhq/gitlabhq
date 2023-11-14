# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::ConvertToBigint, feature_category: :database do
  let(:migration) do
    Class
      .new(Gitlab::Database::Migration[2.1])
      .include(described_class)
      .include(Gitlab::Database::MigrationHelpers)
      .new
  end

  describe '#com_or_dev_or_test_but_not_jh?' do
    using RSpec::Parameterized::TableSyntax

    where(:dot_com, :dev_or_test, :jh, :expectation) do
      true  | true  | true  | true
      true  | false | true  | false
      false | true  | true  | true
      false | false | true  | false
      true  | true  | false | true
      true  | false | false | true
      false | true  | false | true
      false | false | false | false
    end

    with_them do
      it 'returns true for GitLab.com (but not JH), dev, or test' do
        allow(Gitlab).to receive(:com?).and_return(dot_com)
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(dev_or_test)
        allow(Gitlab).to receive(:jh?).and_return(jh)

        expect(migration.com_or_dev_or_test_but_not_jh?).to eq(expectation)
      end
    end
  end

  describe '#temp_column_removed?' do
    it 'return true when column is not present' do
      expect(migration).to receive(:column_exists?).with('test_table', 'id_convert_to_bigint').and_return(false)

      expect(migration.temp_column_removed?(:test_table, :id)).to eq(true)
    end

    it 'return false when column present' do
      expect(migration).to receive(:column_exists?).with('test_table', 'id_convert_to_bigint').and_return(true)

      expect(migration.temp_column_removed?(:test_table, :id)).to eq(false)
    end
  end

  describe '#columns_swapped?' do
    it 'returns true if columns are already swapped' do
      columns = [
        Struct.new(:name, :sql_type).new('id', 'bigint'),
        Struct.new(:name, :sql_type).new('id_convert_to_bigint', 'integer')
      ]

      expect(migration).to receive(:columns).with('test_table').and_return(columns)

      expect(migration.columns_swapped?(:test_table, :id)).to eq(true)
    end

    it 'returns false if columns are not yet swapped' do
      columns = [
        Struct.new(:name, :sql_type).new('id', 'integer'),
        Struct.new(:name, :sql_type).new('id_convert_to_bigint', 'bigint')
      ]

      expect(migration).to receive(:columns).with('test_table').and_return(columns)

      expect(migration.columns_swapped?(:test_table, :id)).to eq(false)
    end
  end

  describe '#add_bigint_column_indexes' do
    let(:connection) { migration.connection }

    let(:table_name) { '_test_table_bigint_indexes' }
    let(:int_column) { 'token' }
    let(:bigint_column) { 'token_convert_to_bigint' }

    subject(:add_bigint_column_indexes) { migration.add_bigint_column_indexes(table_name, int_column) }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS public.#{table_name} (
          name varchar(40),
          #{int_column} integer
        );
      SQL

      allow(migration).to receive(:transaction_open?).and_return(false)
      allow(migration).to receive(:disable_statement_timeout).and_call_original
    end

    after do
      connection.execute("DROP TABLE IF EXISTS #{table_name}")
    end

    context 'without corresponding bigint column' do
      let(:error_msg) { "Bigint column '#{bigint_column}' does not exist on #{table_name}" }

      it { expect { subject }.to raise_error(RuntimeError, error_msg) }
    end

    context 'with corresponding bigint column' do
      let(:indexes) { connection.indexes(table_name) }
      let(:int_column_indexes) { indexes.select { |i| i.columns.include?(int_column) } }
      let(:bigint_column_indexes) { indexes.select { |i| i.columns.include?(bigint_column) } }

      before do
        connection.execute("ALTER TABLE #{table_name} ADD COLUMN #{bigint_column} bigint")
      end

      context 'without the integer column index' do
        it 'does not create new bigint index' do
          expect(int_column_indexes).to be_empty

          add_bigint_column_indexes

          expect(bigint_column_indexes).to be_empty
        end
      end

      context 'with integer column indexes' do
        let(:bigint_index_name) { ->(int_index_name) { migration.bigint_index_name(int_index_name) } }
        let(:expected_bigint_indexes) do
          [
            {
              name: bigint_index_name.call("hash_idx_#{table_name}"),
              column: [bigint_column],
              using: 'hash'
            },
            {
              name: bigint_index_name.call("idx_#{table_name}"),
              column: [bigint_column],
              using: 'btree'
            },
            {
              name: bigint_index_name.call("idx_#{table_name}_combined"),
              column: "#{bigint_column}, lower((name)::text)",
              where: "(#{bigint_column} IS NOT NULL)",
              using: 'btree'
            },
            {
              name: bigint_index_name.call("idx_#{table_name}_functional"),
              column: "#{bigint_column}, lower((name)::text)",
              using: 'btree'
            },
            {
              name: bigint_index_name.call("idx_#{table_name}_ordered"),
              column: [bigint_column],
              order: 'DESC NULLS LAST',
              using: 'btree'
            },
            {
              name: bigint_index_name.call("idx_#{table_name}_ordered_multiple"),
              column: [bigint_column, 'name'],
              order: { bigint_column => 'DESC NULLS LAST', 'name' => 'desc' },
              using: 'btree'
            },
            {
              name: bigint_index_name.call("idx_#{table_name}_partial"),
              column: [bigint_column],
              where: "(#{bigint_column} IS NOT NULL)",
              using: 'btree'
            },
            {
              name: bigint_index_name.call("uniq_idx_#{table_name}"),
              column: [bigint_column],
              unique: true,
              using: 'btree'
            }
          ]
        end

        before do
          connection.execute(<<~SQL)
            CREATE INDEX "hash_idx_#{table_name}" ON #{table_name} USING hash (#{int_column});
            CREATE INDEX "idx_#{table_name}" ON #{table_name} USING btree (#{int_column});
            CREATE INDEX "idx_#{table_name}_combined" ON #{table_name} USING btree (#{int_column}, lower((name)::text)) WHERE (#{int_column} IS NOT NULL);
            CREATE INDEX "idx_#{table_name}_functional" ON #{table_name} USING btree (#{int_column}, lower((name)::text));
            CREATE INDEX "idx_#{table_name}_ordered" ON #{table_name} USING btree (#{int_column} DESC NULLS LAST);
            CREATE INDEX "idx_#{table_name}_ordered_multiple" ON #{table_name} USING btree (#{int_column} DESC NULLS LAST, name DESC);
            CREATE INDEX "idx_#{table_name}_partial" ON #{table_name} USING btree (#{int_column}) WHERE (#{int_column} IS NOT NULL);
            CREATE UNIQUE INDEX "uniq_idx_#{table_name}" ON #{table_name} USING btree (#{int_column});
          SQL
        end

        it 'creates appropriate bigint indexes' do
          expected_bigint_indexes.each do |bigint_index|
            expect(migration).to receive(:add_concurrent_index).with(
              table_name,
              bigint_index[:column],
              name: bigint_index[:name],
              ** bigint_index.except(:name, :column)
            )
          end

          add_bigint_column_indexes
        end
      end
    end
  end
end
