# frozen_string_literal: true

require "graphql/tracing"

module GraphQL
  module Tracing
    # This is the base class for a `trace` instance whose methods are called during query execution.
    # "Trace modes" are subclasses of this with custom tracing modules mixed in.
    #
    # A trace module may implement any of the methods on `Trace`, being sure to call `super`
    # to continue any tracing hooks and call the actual runtime behavior.
    #
    class Trace
      # @param multiplex [GraphQL::Execution::Multiplex, nil]
      # @param query [GraphQL::Query, nil]
      def initialize(multiplex: nil, query: nil, **_options)
        @multiplex = multiplex
        @query = query
      end

      # The Ruby parser doesn't call this method (`graphql/c_parser` does.)
      def lex(query_string:)
        yield
      end

      # @param query_str [String]
      # @return [void]
      def begin_parse(query_str); end;
      # @param query_str [String]
      # @return [void]
      def end_parse(query_str); end;
      # @param query_string [String]
      # @return [void]
      def parse(query_string:)
        yield
      end

      def validate(query:, validate:)
        yield
      end

      def begin_validate(query, validate)
      end

      def end_validate(query, validate, errors)
      end

      # @param multiplex [GraphQL::Execution::Multiplex]
      # @param analyzers [Array<Class>]
      # @return [void]
      def begin_analyze_multiplex(multiplex, analyzers); end
      # @param multiplex [GraphQL::Execution::Multiplex]
      # @param analyzers [Array<Class>]
      # @return [void]
      def end_analyze_multiplex(multiplex, analyzers); end
      # @param multiplex [GraphQL::Execution::Multiplex]
      # @return [void]
      def analyze_multiplex(multiplex:)
        yield
      end

      def analyze_query(query:)
        yield
      end

      # This is the first event in the tracing lifecycle.
      # Every Query is technically run _inside_ a {GraphQL::Multiplex}.
      # @param multiplex [GraphQL::Execution::Multiplex]
      # @return [void]
      def begin_execute_multiplex(multiplex); end;

      # This is the last event of the tracing lifecycle.
      # @param multiplex [GraphQL::Execution::Multiplex]
      # @return [void]
      def end_execute_multiplex(multiplex); end;

      # This wraps an entire `.execute` call.
      # @param multiplex [GraphQL::Execution::Multiplex]
      # @return [void]
      def execute_multiplex(multiplex:)
        yield
      end

      def execute_query(query:)
        yield
      end

      def execute_query_lazy(query:, multiplex:)
        yield
      end

      # GraphQL is about to resolve this field
      # @param field [GraphQL::Schema::Field]
      # @param object [GraphQL::Schema::Object]
      # @param arguments [Hash]
      # @param query [GraphQL::Query]
      def begin_execute_field(field, object, arguments, query); end
      # GraphQL just finished resolving this field
      # @param field [GraphQL::Schema::Field]
      # @param object [GraphQL::Schema::Object]
      # @param arguments [Hash]
      # @param query [GraphQL::Query]
      # @param result [Object]
      def end_execute_field(field, object, arguments, query, result); end

      def execute_field(field:, query:, ast_node:, arguments:, object:)
        yield
      end

      def execute_field_lazy(field:, query:, ast_node:, arguments:, object:)
        yield
      end

      def authorized(query:, type:, object:)
        yield
      end

      # A call to `.authorized?` is starting
      # @param type [Class<GraphQL::Schema::Object>]
      # @param object [Object]
      # @param context [GraphQL::Query::Context]
      # @return [void]
      def begin_authorized(type, object, context)
      end
      # A call to `.authorized?` just finished
      # @param type [Class<GraphQL::Schema::Object>]
      # @param object [Object]
      # @param context [GraphQL::Query::Context]
      # @param authorized_result [Boolean]
      # @return [void]
      def end_authorized(type, object, context, authorized_result)
      end

      def authorized_lazy(query:, type:, object:)
        yield
      end

      def resolve_type(query:, type:, object:)
        yield
      end

      def resolve_type_lazy(query:, type:, object:)
        yield
      end

      # A call to `.resolve_type` is starting
      # @param type [Class<GraphQL::Schema::Union>, Module<GraphQL::Schema::Interface>]
      # @param value [Object]
      # @param context [GraphQL::Query::Context]
      # @return [void]
      def begin_resolve_type(type, value, context)
      end

      # A call to `.resolve_type` just ended
      # @param type [Class<GraphQL::Schema::Union>, Module<GraphQL::Schema::Interface>]
      # @param value [Object]
      # @param context [GraphQL::Query::Context]
      # @param resolved_type [Class<GraphQL::Schema::Object>]
      # @return [void]
      def end_resolve_type(type, value, context, resolved_type)
      end

      # A dataloader run is starting
      # @param dataloader [GraphQL::Dataloader]
      # @return [void]
      def begin_dataloader(dataloader); end
      # A dataloader run has ended
      # @param dataloder [GraphQL::Dataloader]
      # @return [void]
      def end_dataloader(dataloader); end

      # A source with pending keys is about to fetch
      # @param source [GraphQL::Dataloader::Source]
      # @return [void]
      def begin_dataloader_source(source); end
      # A fetch call has just ended
      # @param source [GraphQL::Dataloader::Source]
      # @return [void]
      def end_dataloader_source(source); end

      # Called when Dataloader spins up a new fiber for GraphQL execution
      # @param jobs [Array<#call>] Execution steps to run
      # @return [void]
      def dataloader_spawn_execution_fiber(jobs); end
      # Called when Dataloader spins up a new fiber for fetching data
      # @param pending_sources [GraphQL::Dataloader::Source] Instances with pending keys
      # @return [void]
      def dataloader_spawn_source_fiber(pending_sources); end
      # Called when an execution or source fiber terminates
      # @return [void]
      def dataloader_fiber_exit; end

      # Called when a Dataloader fiber is paused to wait for data
      # @param source [GraphQL::Dataloader::Source] The Source whose `load` call initiated this `yield`
      # @return [void]
      def dataloader_fiber_yield(source); end
      # Called when a Dataloader fiber is resumed because data has been loaded
      # @param source [GraphQL::Dataloader::Source] The Source whose `load` call previously caused this Fiber to wait
      # @return [void]
      def dataloader_fiber_resume(source); end
    end
  end
end
