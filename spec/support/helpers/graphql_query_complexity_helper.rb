# frozen_string_literal: true

# Helpers to measure a GraphQL query's complexity the way the server computes it in
# production.
#
# Apollo Client injects `__typename` into every selection set at runtime, and the server
# counts those fields towards query complexity. Measuring the raw `.graphql` document text
# under-counts and can hide real complexity breaches, so these helpers inject `__typename`
# before measuring.
module GraphqlQueryComplexityHelper
  # Recursively injects `__typename` into every selection set (except the operation root),
  # mirroring what Apollo Client does at runtime.
  def add_typename(node)
    return node unless node.respond_to?(:selections) && node.selections.any?

    selections = node.selections.map { |selection| add_typename(selection) }

    unless node.is_a?(GraphQL::Language::Nodes::OperationDefinition)
      has_typename = selections.any? do |selection|
        selection.is_a?(GraphQL::Language::Nodes::Field) && selection.name == '__typename'
      end
      selections += [GraphQL::Language::Nodes::Field.new(name: '__typename')] unless has_typename
    end

    node.merge(selections: selections)
  end

  # Parses a query, injects `__typename`, and returns its complexity as the server sees it.
  def query_complexity_with_typename(query_text, variables)
    document = GraphQL.parse(query_text)
    document = document.merge(definitions: document.definitions.map { |node| add_typename(node) })
    query = GraphQL::Query.new(GitlabSchema, document: document, variables: variables)
    GraphQL::Analysis.analyze_query(query, [GraphQL::Analysis::QueryComplexity]).first
  end
end
