# frozen_string_literal: true

module GraphQL
  class Query
    # A result from {Schema#execute}.
    # It provides the requested data and
    # access to the {Query} and {Query::Context}.
    class Result
      extend Forwardable

      def initialize(query:, values:)
        @query = query
        @to_h = values
      end

      # @return [GraphQL::Query] The query that was executed
      attr_reader :query

      # @return [Hash] The resulting hash of "data" and/or "errors"
      attr_reader :to_h

      def_delegators :@query, :context, :mutation?, :query?, :subscription?

      def_delegators :@to_h, :[], :keys, :values, :to_json, :as_json

      # Delegate any hash-like method to the underlying hash.
      def method_missing(method_name, *args, &block)
        if @to_h.respond_to?(method_name)
          @to_h.public_send(method_name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        @to_h.respond_to?(method_name) || super
      end

      def inspect
        "#<GraphQL::Query::Result @query=... @to_h=#{@to_h}>"
      end

      # A result is equal to another object when:
      #
      # - The other object is a Hash whose value matches `result.to_h`
      # - The other object is a Result whose value matches `result.to_h`
      #
      # (The query is ignored for comparing result equality.)
      #
      # @return [Boolean]
      def ==(other)
        case other
        when Hash
          @to_h == other
        when Query::Result
          @to_h == other.to_h
        else
          super
        end
      end
    end
  end
end
