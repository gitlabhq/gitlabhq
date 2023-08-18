# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Redactor, feature_category: :database do
  let(:builder) { ClickHouse::QueryBuilder.new(:test_table) }

  describe '.redact' do
    context 'when given simple conditions' do
      let(:new_builder) { builder.where(column1: 'value1', column2: 'value2') }
      let(:redacted_query) { described_class.redact(new_builder) }

      it 'redacts equality conditions correctly' do
        expected_redacted_sql = <<~SQL.chomp.lines(chomp: true).join(' ')
            SELECT * FROM "test_table"
            WHERE "test_table"."column1" = $1
            AND "test_table"."column2" = $2
        SQL

        expect(redacted_query).to eq(expected_redacted_sql)
      end
    end

    context 'when given IN conditions' do
      let(:new_builder) { builder.where(column1: %w[value1 value2 value3]) }
      let(:redacted_query) { described_class.redact(new_builder) }

      it 'redacts IN conditions correctly' do
        expected_redacted_sql = <<~SQL.lines(chomp: true).join(' ')
            SELECT * FROM "test_table"
            WHERE "test_table"."column1" IN ($1, $2, $3)
        SQL

        expect(redacted_query).to eq(expected_redacted_sql)
      end
    end

    context 'with supported arel nodes' do
      it 'redacts a query using the In node' do
        new_builder = builder.where(builder.table[:column1].in(%w[value1 value2]))
        redacted_query = described_class.redact(new_builder)

        expected_redacted_sql = <<~SQL.lines(chomp: true).join(' ')
            SELECT * FROM "test_table"
            WHERE "test_table"."column1" IN ($1, $2)
        SQL

        expect(redacted_query).to eq(expected_redacted_sql)
      end

      it 'redacts a query using the Equality node' do
        new_builder = builder.where(builder.table[:column1].eq('value1'))
        redacted_query = described_class.redact(new_builder)

        expected_redacted_sql = <<~SQL.lines(chomp: true).join(' ')
            SELECT * FROM "test_table"
            WHERE "test_table"."column1" = $1
        SQL

        expect(redacted_query).to eq(expected_redacted_sql)
      end

      it 'redacts a query using the LessThan node' do
        new_builder = builder.where(builder.table[:column1].lt(5))
        redacted_query = described_class.redact(new_builder)

        expected_redacted_sql = <<~SQL.lines(chomp: true).join(' ')
            SELECT * FROM "test_table"
            WHERE "test_table"."column1" < $1
        SQL

        expect(redacted_query).to eq(expected_redacted_sql)
      end

      it 'redacts a query using the LessThanOrEqual node' do
        new_builder = builder.where(builder.table[:column1].lteq(5))
        redacted_query = described_class.redact(new_builder)

        expected_redacted_sql = <<~SQL.lines(chomp: true).join(' ')
            SELECT * FROM "test_table"
            WHERE "test_table"."column1" <= $1
        SQL

        expect(redacted_query).to eq(expected_redacted_sql)
      end

      it 'redacts a query using the GreaterThan node' do
        new_builder = builder.where(builder.table[:column1].gt(5))
        redacted_query = described_class.redact(new_builder)

        expected_redacted_sql = <<~SQL.lines(chomp: true).join(' ')
            SELECT * FROM "test_table"
            WHERE "test_table"."column1" > $1
        SQL

        expect(redacted_query).to eq(expected_redacted_sql)
      end

      it 'redacts a query using the GreaterThanOrEqual node' do
        new_builder = builder.where(builder.table[:column1].gteq(5))
        redacted_query = described_class.redact(new_builder)

        expected_redacted_sql = <<~SQL.lines(chomp: true).join(' ')
            SELECT * FROM "test_table"
            WHERE "test_table"."column1" >= $1
        SQL

        expect(redacted_query).to eq(expected_redacted_sql)
      end
    end

    context 'with unsupported arel nodes' do
      let(:unsupported_node) { Arel::Nodes::NotEqual.new(Arel::Table.new(:test_table)[:column1], 'value1') }
      let(:manager) do
        instance_double(
          'Arel::SelectManager',
          constraints: [],
          where: true,
          to_sql: "SELECT * FROM \"test_table\""
        )
      end

      let(:mocked_builder) do
        instance_double(
          'ClickHouse::QueryBuilder',
          conditions: [unsupported_node],
          manager: manager
        )
      end

      it 'raises an error for the unsupported node' do
        expect do
          described_class.redact(mocked_builder)
        end.to raise_error(ArgumentError, /Unsupported Arel node type for Redactor:/)
      end
    end

    context 'when method chaining is used' do
      let(:new_builder) do
        builder.where(column1: 'value1').where(column2: 'value2').where(builder.table[:column3].gteq(5))
      end

      let(:redacted_query) { described_class.redact(new_builder) }

      it 'redacts chained conditions correctly' do
        expected_redacted_sql = <<~SQL.lines(chomp: true).join(' ')
            SELECT * FROM "test_table"
            WHERE "test_table"."column1" = $1
            AND "test_table"."column2" = $2
            AND "test_table"."column3" >= $3
        SQL
        expect(redacted_query).to eq(expected_redacted_sql)
      end
    end

    context 'when calling .redact multiple times' do
      let(:new_builder) { builder.where(column1: 'value1', column2: 'value2') }
      let(:first_redacted_query) { described_class.redact(new_builder) }
      let(:second_redacted_query) { described_class.redact(new_builder) }

      it 'produces consistent redacted SQL' do
        expect(first_redacted_query).to eq(second_redacted_query)
      end
    end
  end
end
