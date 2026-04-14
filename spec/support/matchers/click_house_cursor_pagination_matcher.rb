# frozen_string_literal: true

# Validates that a ClickHouse QueryBuilder object complies with the requirements
# of Gitlab::Graphql::Pagination::ClickHouseConnection for cursor-based pagination.
#
# Requirements (from ClickHouseConnection):
#   1. Every ORDER BY expression must have a resolvable column name.
#      - Arel::Nodes::SqlLiteral  uses the literal string as the name
#      - Arel::Attribute          uses the attribute name
#      - Arel::Nodes::NamedFunction (raw, no alias) VIOLATION: `.name` returns
#        the function name (e.g. "sumIf"), not a real column
#   2. Every resolved ORDER BY column name must be present in the SELECT clause,
#      so that cursor_for can read the value from each result row.
#
# Usage:
#   expect(query).to comply_to_cursor_pagination
#
RSpec::Matchers.define :comply_to_cursor_pagination do
  match do |query|
    @violations = violations_for(query)
    @violations.empty?
  end

  failure_message do |_query|
    lines = @violations.map { |v| "  - #{v}" }.join("\n")
    "Query does not comply with ClickHouse cursor pagination requirements:\n#{lines}"
  end

  private

  def violations_for(query)
    orders = query.manager.ast.orders

    return ["no ORDER BY clause - cursor pagination requires at least one sort column"] if orders.empty?

    projected = projected_column_names(query)

    orders.filter_map do |order|
      expr = order.expr

      if expr.is_a?(Arel::Nodes::NamedFunction)
        "#{expr.name}(...) is a raw function expression in ORDER BY - " \
          "select it with an alias (.as('name')) and order by that alias instead"
      else
        name = order_expression_name(order)
        unless projected.include?(name)
          "'#{name}' is in ORDER BY but not found in SELECT - cursor_for cannot read its value"
        end
      end
    end
  end

  # Mirrors Gitlab::Graphql::Pagination::ClickHouseConnection#order_expression_name
  def order_expression_name(order)
    expr = order.expr
    expr.is_a?(Arel::Nodes::SqlLiteral) ? expr.to_s : expr.name
  end

  def projected_column_names(query)
    query.manager.projections.filter_map do |projection|
      case projection
      when Arel::Nodes::As
        projection.right.to_s
      when Arel::Nodes::SqlLiteral
        projection.to_s
      else
        projection.respond_to?(:alias) ? projection.alias : projection.name
      end
    end
  end
end
