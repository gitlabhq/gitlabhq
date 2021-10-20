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

  subject(:strategy) { described_class.new(model, order_by_columns) }

  describe '#initializer_columns' do
    it 'returns NULLs for each ORDER BY columns' do
      expect(strategy.initializer_columns).to eq([
        'NULL::timestamp without time zone AS created_at',
        'NULL::integer AS id'
      ])
    end
  end
end
