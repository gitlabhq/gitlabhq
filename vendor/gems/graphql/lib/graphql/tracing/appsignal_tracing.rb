# frozen_string_literal: true

require "graphql/tracing/platform_tracing"

module GraphQL
  module Tracing
    class AppsignalTracing < PlatformTracing
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

      # @param set_action_name [Boolean] If true, the GraphQL operation name will be used as the transaction name.
      #   This is not advised if you run more than one query per HTTP request, for example, with `graphql-client` or multiplexing.
      #   It can also be specified per-query with `context[:set_appsignal_action_name]`.
      def initialize(options = {})
        @set_action_name = options.fetch(:set_action_name, false)
        super
      end

      def platform_trace(platform_key, key, data)
        if key == "execute_query"
          set_this_txn_name =  data[:query].context[:set_appsignal_action_name]
          if set_this_txn_name == true || (set_this_txn_name.nil? && @set_action_name)
            Appsignal::Transaction.current.set_action(transaction_name(data[:query]))
          end
        end

        Appsignal.instrument(platform_key) do
          yield
        end
      end

      def platform_field_key(type, field)
        "#{type.graphql_name}.#{field.graphql_name}.graphql"
      end

      def platform_authorized_key(type)
        "#{type.graphql_name}.authorized.graphql"
      end

      def platform_resolve_type_key(type)
        "#{type.graphql_name}.resolve_type.graphql"
      end
    end
  end
end
