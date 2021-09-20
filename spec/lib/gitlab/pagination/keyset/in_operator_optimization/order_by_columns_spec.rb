# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::InOperatorOptimization::OrderByColumns do
  let(:columns) do
    [
      Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
        attribute_name: :relative_position,
        order_expression: Issue.arel_table[:relative_position].desc
      ),
      Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
        attribute_name: :id,
        order_expression: Issue.arel_table[:id].desc
      )
    ]
  end

  subject(:order_by_columns) { described_class.new(columns, Issue.arel_table) }

  describe '#array_aggregated_column_names' do
    it { expect(order_by_columns.array_aggregated_column_names).to eq(%w[issues_relative_position_array issues_id_array]) }
  end

  describe '#original_column_names' do
    it { expect(order_by_columns.original_column_names).to eq(%w[relative_position id]) }
  end

  describe '#cursor_values' do
    it 'returns the keyset pagination cursor values from the column arrays as SQL expression' do
      expect(order_by_columns.cursor_values('tbl')).to eq({
        "id" => "tbl.issues_id_array[position]",
        "relative_position" => "tbl.issues_relative_position_array[position]"
      })
    end
  end
end
