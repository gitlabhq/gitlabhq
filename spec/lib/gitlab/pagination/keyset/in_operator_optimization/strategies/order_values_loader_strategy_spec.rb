# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::InOperatorOptimization::Strategies::OrderValuesLoaderStrategy do
  let(:model) { Project }

  let(:keyset_scope) do
    scope, _ = Gitlab::Pagination::Keyset::SimpleOrderBuilder.build(
      Project.order(:created_at, :id)
    )

    scope
  end

  let(:keyset_order) do
    Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(keyset_scope)
  end

  let(:order_by_columns) do
    Gitlab::Pagination::Keyset::InOperatorOptimization::OrderByColumns.new(keyset_order.column_definitions, model.arel_table)
  end

  let(:id_type) { model.columns_hash['id'].sql_type }

  subject(:strategy) { described_class.new(model, order_by_columns) }

  describe '#initializer_columns' do
    it 'returns NULLs for each ORDER BY columns' do
      expect(strategy.initializer_columns).to eq(
        [
          'NULL::timestamp without time zone AS created_at',
          "NULL::#{id_type} AS id"
        ])
    end
  end

  context 'when an SQL expression is given' do
    context 'when the sql_type attribute is missing' do
      let(:order) do
        Gitlab::Pagination::Keyset::Order.build(
          [
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'id_times_ten',
              order_expression: Arel.sql('id * 10').asc
            )
          ])
      end

      let(:keyset_scope) { Project.order(order) }

      it 'raises error' do
        expect { strategy.initializer_columns }.to raise_error(Gitlab::Pagination::Keyset::SqlTypeMissingError)
      end
    end

    context 'when the sql_type_attribute is present' do
      let(:order) do
        Gitlab::Pagination::Keyset::Order.build(
          [
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'id_times_ten',
              order_expression: Arel.sql('id * 10').asc,
              sql_type: id_type
            )
          ])
      end

      let(:keyset_scope) { Project.order(order) }

      it 'returns the initializer columns' do
        expect(strategy.initializer_columns).to eq(["NULL::#{id_type} AS id_times_ten"])
      end
    end
  end
end
