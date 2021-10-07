# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::InOperatorOptimization::Strategies::RecordLoaderStrategy do
  let(:finder_query) { -> (created_at_value, id_value) { Project.where(Project.arel_table[:id].eq(id_value)) } }
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

  subject(:strategy) { described_class.new(finder_query, model, order_by_columns) }

  describe '#initializer_columns' do
    # Explanation:
    # > SELECT NULL::projects AS records
    #
    # The query returns one row and one column. The column may contain a full project row.
    # In this particular case the row is NULL.
    it 'returns a NULL table row as the result column' do
      expect(strategy.initializer_columns).to eq(["NULL::projects AS records"])
    end
  end

  describe '#columns' do
    # Explanation:
    # > SELECT (SELECT projects FROM projects limit 1)
    #
    # Selects one row from the database and collapses it into one column.
    #
    # Side note: Due to the type casts, columns and initializer_columns can be also UNION-ed:
    # SELECT * FROM (
    #   (
    #     SELECT NULL::projects AS records
    #     UNION
    #     SELECT (SELECT projects FROM projects limit 1)
    #   )
    # ) as records
    it 'uses the finder query to load the row in the result column' do
      expected_loader_query = <<~SQL
        (SELECT projects FROM "projects" WHERE "projects"."id" = recursive_keyset_cte.projects_id_array[position] LIMIT 1)
      SQL

      expect(strategy.columns).to eq([expected_loader_query.chomp])
    end
  end
end
