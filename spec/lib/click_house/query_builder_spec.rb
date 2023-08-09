# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::QueryBuilder, feature_category: :database do
  let(:table_name) { :test_table }
  let(:builder) { described_class.new(table_name) }

  describe "#initialize" do
    it 'initializes with correct table' do
      expect(builder.table.name).to eq(table_name.to_s)
    end
  end

  describe '#where' do
    it 'builds correct where query with simple conditions' do
      expected_sql = "SELECT * FROM \"test_table\" WHERE \"test_table\".\"column1\" " \
                     "= 'value1' AND \"test_table\".\"column2\" = 'value2'"

      sql = builder.where(column1: 'value1', column2: 'value2').to_sql

      expect(sql).to eq(expected_sql)
    end

    it 'builds correct where query with array conditions' do
      expected_sql = "SELECT * FROM \"test_table\" WHERE \"test_table\".\"column1\" " \
                     "IN (1, 2, 3)"

      sql = builder.where(column1: [1, 2, 3]).to_sql

      expect(sql).to eq(expected_sql)
    end

    it 'builds correct where query with arel nodes' do
      date = Date.today
      expected_sql = "SELECT * FROM \"test_table\" WHERE \"test_table\".\"created_at\" <= '#{date}'"

      sql = builder.where(builder.table[:created_at].lteq(date)).to_sql

      expect(sql).to eq(expected_sql)
    end
  end

  describe '#select' do
    it 'builds correct select query with single field' do
      expected_sql = "SELECT \"test_table\".\"column1\" FROM \"test_table\""

      sql = builder.select(:column1).to_sql

      expect(sql).to eq(expected_sql)
    end

    it 'builds correct select query with multiple fields' do
      expected_sql = "SELECT \"test_table\".\"column1\", \"test_table\".\"column2\" FROM \"test_table\""

      sql = builder.select(:column1, :column2).to_sql

      expect(sql).to eq(expected_sql)
    end
  end

  describe '#order' do
    it 'builds correct order query with direction :desc' do
      expected_sql = "SELECT * FROM \"test_table\" ORDER BY \"test_table\".\"column1\" DESC"

      sql = builder.order(:column1, :desc).to_sql

      expect(sql).to eq(expected_sql)
    end

    it 'builds correct order query with default direction asc' do
      expected_sql = "SELECT * FROM \"test_table\" ORDER BY \"test_table\".\"column1\" ASC"

      sql = builder.order(:column1).to_sql

      expect(sql).to eq(expected_sql)
    end

    it 'raises error for invalid direction' do
      expect do
        builder.order(:column1, :invalid)
      end.to raise_error(ArgumentError, "Invalid order direction 'invalid'. Must be :asc or :desc")
    end
  end

  describe '#limit' do
    it 'builds correct limit query' do
      expected_sql = "SELECT * FROM \"test_table\" LIMIT 10"

      sql = builder.limit(10).to_sql

      expect(sql).to eq(expected_sql)
    end
  end

  describe '#offset' do
    it 'builds correct offset query' do
      expected_sql = "SELECT * FROM \"test_table\" OFFSET 5"

      sql = builder.offset(5).to_sql

      expect(sql).to eq(expected_sql)
    end
  end

  describe '#to_sql' do
    it 'delegates to the Arel::SelectManager' do
      expect(builder.send(:manager)).to receive(:to_sql)

      builder.to_sql
    end
  end

  describe 'method chaining' do
    it 'builds correct SQL query when methods are chained' do
      expected_sql = "SELECT \"test_table\".\"column1\", \"test_table\".\"column2\" FROM \"test_table\" " \
                     "WHERE \"test_table\".\"column1\" = 'value1' AND \"test_table\".\"column2\" = 'value2' " \
                     "ORDER BY \"test_table\".\"column1\" DESC LIMIT 10 OFFSET 5"

      sql = builder
              .select(:column1, :column2)
              .where(column1: 'value1', column2: 'value2')
              .order(:column1, 'desc')
              .limit(10)
              .offset(5)
              .to_sql

      expect(sql).to eq(expected_sql)
    end
  end
end
