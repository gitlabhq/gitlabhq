# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::InOperatorOptimization::OrderByColumnData do
  let(:arel_table) { Issue.arel_table }

  let(:column) do
    Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
      attribute_name: :id,
      column_expression: arel_table[:id],
      order_expression: arel_table[:id].desc
    )
  end

  subject(:column_data) { described_class.new(column, 'column_alias', arel_table) }

  describe '#arel_column' do
    it 'delegates to column_expression' do
      expect(column_data.arel_column).to eq(column.column_expression)
    end
  end

  describe '#column_for_projection' do
    it 'returns the expression with AS using the original column name' do
      expect(column_data.column_for_projection.to_sql).to eq('"issues"."id" AS id')
    end
  end

  describe '#projection' do
    it 'returns the expression with AS using the specified column lias' do
      expect(column_data.projection.to_sql).to eq('"issues"."id" AS column_alias')
    end
  end
end
