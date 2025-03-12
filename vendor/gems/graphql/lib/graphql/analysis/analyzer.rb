# frozen_string_literal: true
module GraphQL
  module Analysis
    # Query analyzer for query ASTs. Query analyzers respond to visitor style methods
    # but are prefixed by `enter` and `leave`.
    #
    # When an analyzer is initialized with a Multiplex, you can always get the current query from
    # `visitor.query` in the visit methods.
    #
    # @param [GraphQL::Query, GraphQL::Execution::Multiplex] The query or multiplex to analyze
    class Analyzer
      def initialize(subject)
        @subject = subject

        if subject.is_a?(GraphQL::Query)
          @query = subject
          @multiplex = nil
        else
          @multiplex = subject
          @query = nil
        end
      end

      # Analyzer hook to decide at analysis time whether a query should
      # be analyzed or not.
      # @return [Boolean] If the query should be analyzed or not
      def analyze?
        true
      end

      # Analyzer hook to decide at analysis time whether analysis
      # requires a visitor pass; can be disabled for precomputed results.
      # @return [Boolean] If analysis requires visitation or not
      def visit?
        true
      end

      # The result for this analyzer. Returning {GraphQL::AnalysisError} results
      # in a query error.
      # @return [Any] The analyzer result
      def result
        raise GraphQL::RequiredImplementationMissingError
      end

      # rubocop:disable Development/NoEvalCop This eval takes static inputs at load-time
      class << self
        private

        def build_visitor_hooks(member_name)
          class_eval(<<-EOS, __FILE__, __LINE__ + 1)
            def on_enter_#{member_name}(node, parent, visitor)
            end

            def on_leave_#{member_name}(node, parent, visitor)
            end
          EOS
        end
      end

      build_visitor_hooks :argument
      build_visitor_hooks :directive
      build_visitor_hooks :document
      build_visitor_hooks :enum
      build_visitor_hooks :field
      build_visitor_hooks :fragment_spread
      build_visitor_hooks :inline_fragment
      build_visitor_hooks :input_object
      build_visitor_hooks :list_type
      build_visitor_hooks :non_null_type
      build_visitor_hooks :null_value
      build_visitor_hooks :operation_definition
      build_visitor_hooks :type_name
      build_visitor_hooks :variable_definition
      build_visitor_hooks :variable_identifier
      build_visitor_hooks :abstract_node
      # rubocop:enable Development/NoEvalCop
      protected

      # @return [GraphQL::Query, GraphQL::Execution::Multiplex] Whatever this analyzer is analyzing
      attr_reader :subject

      # @return [GraphQL::Query, nil] `nil` if this analyzer is visiting a multiplex
      #  (When this is `nil`, use `visitor.query` inside visit methods to get the current query)
      attr_reader :query

      # @return [GraphQL::Execution::Multiplex, nil] `nil` if this analyzer is visiting a query
      attr_reader :multiplex
    end
  end
end
