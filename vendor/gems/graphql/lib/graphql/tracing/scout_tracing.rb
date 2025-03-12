# frozen_string_literal: true

require "graphql/tracing/platform_tracing"

module GraphQL
  module Tracing
    class ScoutTracing < PlatformTracing
      INSTRUMENT_OPTS = { scope: true }

      self.platform_keys = {
        "lex" => "lex.graphql",
        "parse" => "parse.graphql",
        "validate" => "validate.graphql",
        "analyze_query" => "analyze.graphql",
        "analyze_multiplex" => "analyze.graphql",
        "execute_multiplex" => "execute.graphql",
        "execute_query" => "execute.graphql",
        "execute_query_lazy" => "execute.graphql",
      }

      # @param set_transaction_name [Boolean] If true, the GraphQL operation name will be used as the transaction name.
      #   This is not advised if you run more than one query per HTTP request, for example, with `graphql-client` or multiplexing.
      #   It can also be specified per-query with `context[:set_scout_transaction_name]`.
      def initialize(options = {})
        self.class.include ScoutApm::Tracer
        @set_transaction_name = options.fetch(:set_transaction_name, false)
        super(options)
      end

      def platform_trace(platform_key, key, data)
        if key == "execute_query"
          set_this_txn_name = data[:query].context[:set_scout_transaction_name]
          if set_this_txn_name == true || (set_this_txn_name.nil? && @set_transaction_name)
            ScoutApm::Transaction.rename(transaction_name(data[:query]))
          end
        end

        self.class.instrument("GraphQL", platform_key, INSTRUMENT_OPTS) do
          yield
        end
      end

      def platform_field_key(type, field)
        "#{type.graphql_name}.#{field.graphql_name}"
      end

      def platform_authorized_key(type)
        "#{type.graphql_name}.authorized"
      end

      def platform_resolve_type_key(type)
        "#{type.graphql_name}.resolve_type"
      end
    end
  end
end
