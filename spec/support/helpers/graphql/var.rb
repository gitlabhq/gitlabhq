# frozen_string_literal: true

module Graphql
  # Helper to pass variables around generated queries.
  #
  # e.g.:
  #   first = var('Int')
  #   after = var('String')
  #
  #   query = with_signature(
  #     [first, after],
  #     query_graphql_path([
  #       [:project, { full_path: project.full_path }],
  #       [:issues, { after: after, first: first }]
  #       :nodes
  #     ], all_graphql_fields_for('Issue'))
  #   )
  #
  #   post_graphql(query, variables: [first.with(2), after.with(some_cursor)])
  #
  class Var
    attr_reader :name, :type
    attr_accessor :value

    def initialize(name, type)
      @name = name
      @type = type
    end

    def sig
      "#{to_graphql_value}: #{type}"
    end

    def to_graphql_value
      "$#{name}"
    end

    # We return a new object so that running the same query twice with
    # different values does not risk re-using the value
    #
    # e.g.
    #
    #   x = var('Int')
    #   expect { post_graphql(query, variables: x) }
    #     .to issue_same_number_of_queries_as { post_graphql(query, variables: x.with(1)) }
    #
    # Here we post the `x` variable once with the value set to 1, and once with
    # the value set to `nil`.
    def with(value)
      copy = Var.new(name, type)
      copy.value = value
      copy
    end

    def to_h
      { name => value }
    end
  end
end
