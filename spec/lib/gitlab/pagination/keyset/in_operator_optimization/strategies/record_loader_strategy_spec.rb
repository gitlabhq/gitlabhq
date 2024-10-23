# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::InOperatorOptimization::Strategies::RecordLoaderStrategy do
  let(:finder_query) { ->(created_at_value, id_value) { model.where(model.arel_table[:id].eq(id_value)) } }
  let(:model) { Project }

  let(:keyset_scope) do
    scope, _ = Gitlab::Pagination::Keyset::SimpleOrderBuilder.build(
      model.order(:created_at, :id)
    )

    scope
  end

  let(:keyset_order) do
    Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(keyset_scope)
  end

  let(:order_by_columns) do
    Gitlab::Pagination::Keyset::InOperatorOptimization::OrderByColumns.new(keyset_order.column_definitions, model.arel_table)
  end

  let_it_be(:ignored_column_model) do
    Class.new(ApplicationRecord) do
      self.table_name = 'projects'

      ignore_column :name, remove_with: '16.4', remove_after: '2023-08-22'
    end
  end

  let_it_be(:model_without_ignored_columns) do
    Class.new(ApplicationRecord) do
      self.table_name = 'projects'
    end
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

  describe '#final_projections' do
    context 'when model does not have ignored columns' do
      let(:model) { model_without_ignored_columns }

      it 'does not specify the selected column names' do
        expect(strategy.final_projections).to contain_exactly("(#{described_class::RECORDS_COLUMN}).*")
      end
    end

    context 'when model has ignored columns' do
      let(:model) { ignored_column_model }

      it 'specifies the selected column names' do
        expect(strategy.final_projections).to match_array(
          model.default_select_columns.map { |column| "(#{described_class::RECORDS_COLUMN}).#{column.name}" }
        )
      end
    end
  end
end
