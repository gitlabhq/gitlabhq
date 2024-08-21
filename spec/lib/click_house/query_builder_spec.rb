# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::QueryBuilder, feature_category: :database do
  let(:table_name) { :test_table }
  let(:builder) { described_class.new(table_name) }

  shared_examples "generates correct sql on multiple calls to `to_sql`" do |method_name, argument1, argument2|
    it 'returns the same SQL when called multiple times on the same builder' do
      query_builder = builder.public_send(method_name, argument1)
      first_sql = query_builder.to_sql
      second_sql = query_builder.to_sql

      expect(first_sql).to eq(second_sql)
    end

    it 'returns different SQL when called multiple times on different builders' do
      query_builder = builder.public_send(method_name, argument1)
      query_builder_2 = query_builder.public_send(method_name, argument2)

      first_sql = query_builder.to_sql
      second_sql = query_builder_2.to_sql

      expect(first_sql).not_to eq(second_sql)
    end
  end

  describe "#initialize" do
    it 'initializes with correct table' do
      expect(builder.table.name).to eq(table_name.to_s)
    end
  end

  describe '#where' do
    context 'with simple conditions' do
      it 'builds correct where query' do
        expected_sql = <<~SQL.lines(chomp: true).join(' ')
          SELECT * FROM "test_table"
          WHERE "test_table"."column1" = 'value1'
          AND "test_table"."column2" = 'value2'
        SQL

        sql = builder.where(column1: 'value1', column2: 'value2').to_sql

        expect(sql).to eq(expected_sql)
      end
    end

    context 'with array conditions' do
      it 'builds correct where query' do
        expected_sql = <<~SQL.lines(chomp: true).join(' ')
          SELECT * FROM "test_table"
          WHERE "test_table"."column1" IN (1, 2, 3)
        SQL

        sql = builder.where(column1: [1, 2, 3]).to_sql

        expect(sql).to eq(expected_sql)
      end
    end

    it_behaves_like "generates correct sql on multiple calls to `to_sql`", :where, { column1: 'value1' },
      { column2: 'value2' }

    context 'with supported arel nodes' do
      it 'builds a query using the In node' do
        expected_sql = <<~SQL.lines(chomp: true).join(' ')
          SELECT * FROM "test_table"
          WHERE "test_table"."column1" IN ('value1', 'value2')
        SQL

        sql = builder.where(builder.table[:column1].in(%w[value1 value2])).to_sql

        expect(sql).to eq(expected_sql)
      end

      it 'builds a query using the Equality node' do
        expected_sql = <<~SQL.lines(chomp: true).join(' ')
          SELECT * FROM "test_table"
          WHERE "test_table"."column1" = 'value1'
        SQL

        sql = builder.where(builder.table[:column1].eq('value1')).to_sql

        expect(sql).to eq(expected_sql)
      end

      it 'builds a query using the LessThan node' do
        expected_sql = <<~SQL.lines(chomp: true).join(' ')
          SELECT * FROM "test_table"
          WHERE "test_table"."column1" < 5
        SQL

        sql = builder.where(builder.table[:column1].lt(5)).to_sql

        expect(sql).to eq(expected_sql)
      end

      it 'builds a query using the LessThanOrEqual node' do
        expected_sql = <<~SQL.lines(chomp: true).join(' ')
          SELECT * FROM "test_table"
          WHERE "test_table"."column1" <= 5
        SQL

        sql = builder.where(builder.table[:column1].lteq(5)).to_sql

        expect(sql).to eq(expected_sql)
      end

      it 'builds a query using the GreaterThan node' do
        expected_sql = <<~SQL.lines(chomp: true).join(' ')
          SELECT * FROM "test_table"
          WHERE "test_table"."column1" > 5
        SQL

        sql = builder.where(builder.table[:column1].gt(5)).to_sql

        expect(sql).to eq(expected_sql)
      end

      it 'builds a query using the GreaterThanOrEqual node' do
        expected_sql = <<~SQL.lines(chomp: true).join(' ')
          SELECT * FROM "test_table"
          WHERE "test_table"."column1" >= 5
        SQL

        sql = builder.where(builder.table[:column1].gteq(5)).to_sql

        expect(sql).to eq(expected_sql)
      end
    end

    context 'with unsupported arel nodes' do
      it 'raises an error for the unsupported node' do
        expect do
          builder.where(builder.table[:column1].not_eq('value1')).to_sql
        end.to raise_error(ArgumentError, /Unsupported Arel node type for QueryBuilder:/)
      end
    end
  end

  describe '#select' do
    it 'builds correct select query with single field' do
      expected_sql = <<~SQL.chomp
        SELECT "test_table"."column1" FROM "test_table"
      SQL

      sql = builder.select(:column1).to_sql

      expect(sql).to eq(expected_sql)
    end

    it 'builds correct select query with multiple fields' do
      expected_sql = <<~SQL.chomp
         SELECT "test_table"."column1", "test_table"."column2" FROM "test_table"
      SQL

      sql = builder.select(:column1, :column2).to_sql

      expect(sql).to eq(expected_sql)
    end

    it 'adds new fields on multiple calls without duplicating' do
      expected_sql = <<~SQL.chomp
          SELECT "test_table"."column1", "test_table"."column2" FROM "test_table"
      SQL

      sql = builder.select(:column1).select(:column2).select(:column1).to_sql

      expect(sql).to eq(expected_sql)
    end

    it_behaves_like "generates correct sql on multiple calls to `to_sql`", :select, :column1, :column2
  end

  describe '#order' do
    it 'builds correct order query with direction :desc' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
          SELECT * FROM "test_table"
          ORDER BY "test_table"."column1" DESC
      SQL

      sql = builder.order(:column1, :desc).to_sql

      expect(sql).to eq(expected_sql)
    end

    it 'builds correct order query with default direction asc' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT * FROM "test_table"
        ORDER BY "test_table"."column1" ASC
      SQL

      sql = builder.order(:column1).to_sql

      expect(sql).to eq(expected_sql)
    end

    it 'appends orderings on multiple calls' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT * FROM "test_table"
        ORDER BY "test_table"."column1" DESC,
        "test_table"."column2" ASC
      SQL

      sql = builder.order(:column1, :desc).order(:column2, :asc).to_sql

      expect(sql).to eq(expected_sql)
    end

    it 'appends orderings for the same column when ordered multiple times' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT * FROM "test_table"
        ORDER BY "test_table"."column1" DESC,
        "test_table"."column1" ASC
      SQL

      sql = builder.order(:column1, :desc).order(:column1, :asc).to_sql

      expect(sql).to eq(expected_sql)
    end

    it 'raises error for invalid direction' do
      expect do
        builder.order(:column1, :invalid)
      end.to raise_error(ArgumentError, "Invalid order direction 'invalid'. Must be :asc or :desc")
    end

    it_behaves_like "generates correct sql on multiple calls to `to_sql`", :order, :column1, :column2
  end

  describe '#limit' do
    it 'builds correct limit query' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
          SELECT * FROM "test_table"
          LIMIT 10
      SQL

      sql = builder.limit(10).to_sql

      expect(sql).to eq(expected_sql)
    end

    it 'overrides previous limit value when called multiple times' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT * FROM "test_table"
        LIMIT 20
      SQL

      sql = builder.limit(10).limit(20).to_sql

      expect(sql).to eq(expected_sql)
    end
  end

  describe '#offset' do
    it 'builds correct offset query' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
          SELECT * FROM "test_table"
          OFFSET 5
      SQL

      sql = builder.offset(5).to_sql

      expect(sql).to eq(expected_sql)
    end

    it 'overrides previous offset value when called multiple times' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT * FROM "test_table"
        OFFSET 10
      SQL

      sql = builder.offset(5).offset(10).to_sql

      expect(sql).to eq(expected_sql)
    end
  end

  describe '#group' do
    it 'builds correct group query' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT * FROM "test_table"
        GROUP BY column1
      SQL

      sql = builder.group(:column1).to_sql

      expect(sql).to eq(expected_sql)
    end

    it 'chains multiple groups when called multiple times' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT * FROM "test_table"
        GROUP BY column1, column2
      SQL

      sql = builder.group(:column1).group(:column2).to_sql

      expect(sql).to eq(expected_sql)
    end
  end

  describe '#to_sql' do
    it 'delegates to the Arel::SelectManager' do
      expect(builder.send(:manager)).to receive(:to_sql)

      builder.to_sql
    end
  end

  describe '#to_redacted_sql' do
    it 'calls ::ClickHouse::Redactor correctly' do
      expect(::ClickHouse::Redactor).to receive(:redact).with(builder,
        an_instance_of(ClickHouse::Client::BindIndexManager))

      builder.to_redacted_sql
    end
  end

  describe '#apply_conditions!' do
    it 'applies conditions to the manager' do
      manager = builder.send(:manager)
      condition = Arel::Nodes::Equality.new(builder.table[:column1], 'value1')
      builder.conditions << condition

      expect(manager).to receive(:where).with(condition)

      builder.send(:apply_conditions!)
    end
  end

  describe 'method chaining', :freeze_time do
    it 'builds correct SQL query when methods are chained' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
          SELECT "test_table"."column1", "test_table"."column2"
          FROM "test_table"
          WHERE "test_table"."column1" = 'value1'
          AND "test_table"."column2" = 'value2'
          AND "test_table"."created_at" <= '#{Date.today}'
          ORDER BY "test_table"."column1" DESC
          LIMIT 10
          OFFSET 5
      SQL

      sql = builder
              .select(:column1, :column2)
              .where(column1: 'value1', column2: 'value2')
              .where(builder.table[:created_at].lteq(Date.today))
              .order(:column1, 'desc')
              .limit(10)
              .offset(5)
              .to_sql

      expect(sql).to eq(expected_sql)
    end
  end

  context 'when combining with a raw query' do
    it 'correctly generates the SQL query' do
      raw_query = 'SELECT * FROM isues WHERE title = {title:String} AND id IN ({query:Subquery})'
      placeholders = {
        title: "'test'",
        query: builder.select(:id).where(column1: 'value1', column2: 'value2')
      }

      query = ClickHouse::Client::Query.new(raw_query: raw_query, placeholders: placeholders)
      expected_sql = "SELECT * FROM isues WHERE title = {title:String} AND id IN (SELECT \"test_table\".\"id\" " \
                     "FROM \"test_table\" WHERE \"test_table\".\"column1\" = 'value1' AND " \
                     "\"test_table\".\"column2\" = 'value2')"

      expect(query.to_sql).to eq(expected_sql)

      expected_redacted_sql = "SELECT * FROM isues WHERE title = $1 AND id IN (SELECT \"test_table\".\"id\" " \
                              "FROM \"test_table\" WHERE \"test_table\".\"column1\" = $2 AND " \
                              "\"test_table\".\"column2\" = $3)"

      expect(query.to_redacted_sql).to eq(expected_redacted_sql)
    end
  end
end
