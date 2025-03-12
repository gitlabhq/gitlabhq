# frozen_string_literal: true

require "graphql/tracing/platform_trace"

module GraphQL
  module Tracing
    # Instrumentation for reporting GraphQL-Ruby times to Appsignal.
    #
    # @example Installing the tracer
    #   class MySchema < GraphQL::Schema
    #     trace_with GraphQL::Tracing::AppsignalTrace
    #   end
    module AppsignalTrace
      include PlatformTrace

      # @param set_action_name [Boolean] If true, the GraphQL operation name will be used as the transaction name.
      #   This is not advised if you run more than one query per HTTP request, for example, with `graphql-client` or multiplexing.
      #   It can also be specified per-query with `context[:set_appsignal_action_name]`.
      def initialize(set_action_name: false, **rest)
        @set_action_name = set_action_name
        super
      end

      # rubocop:disable Development/NoEvalCop This eval takes static inputs at load-time

      {
        "lex" => "lex.graphql",
        "parse" => "parse.graphql",
        "validate" => "validate.graphql",
        "analyze_query" => "analyze.graphql",
        "analyze_multiplex" => "analyze.graphql",
        "execute_multiplex" => "execute.graphql",
        "execute_query" => "execute.graphql",
        "execute_query_lazy" => "execute.graphql",
      }.each do |trace_method, platform_key|
        module_eval <<-RUBY, __FILE__, __LINE__
          def #{trace_method}(**data)
            #{
              if trace_method == "execute_query"
                <<-RUBY
                set_this_txn_name =  data[:query].context[:set_appsignal_action_name]
                if set_this_txn_name == true || (set_this_txn_name.nil? && @set_action_name)
                  Appsignal::Transaction.current.set_action(transaction_name(data[:query]))
                end
                RUBY
              end
            }

            Appsignal.instrument("#{platform_key}") do
              super
            end
          end
        RUBY
      end

      # rubocop:enable Development/NoEvalCop

      def platform_execute_field(platform_key)
        Appsignal.instrument(platform_key) do
          yield
        end
      end

      def platform_authorized(platform_key)
        Appsignal.instrument(platform_key) do
          yield
        end
      end

      def platform_resolve_type(platform_key)
        Appsignal.instrument(platform_key) do
          yield
        end
      end

      def platform_field_key(field)
        "#{field.owner.graphql_name}.#{field.graphql_name}.graphql"
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
