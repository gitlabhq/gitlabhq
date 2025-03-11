# frozen_string_literal: true
require "graphql/analysis/visitor"
require "graphql/analysis/analyzer"
require "graphql/analysis/field_usage"
require "graphql/analysis/query_complexity"
require "graphql/analysis/max_query_complexity"
require "graphql/analysis/query_depth"
require "graphql/analysis/max_query_depth"
require "timeout"

module GraphQL
  module Analysis
    AST = self
    module_function
    # Analyze a multiplex, and all queries within.
    # Multiplex analyzers are ran for all queries, keeping state.
    # Query analyzers are ran per query, without carrying state between queries.
    #
    # @param multiplex [GraphQL::Execution::Multiplex]
    # @param analyzers [Array<GraphQL::Analysis::Analyzer>]
    # @return [Array<Any>] Results from multiplex analyzers
    def analyze_multiplex(multiplex, analyzers)
      multiplex_analyzers = analyzers.map { |analyzer| analyzer.new(multiplex) }

      multiplex.current_trace.analyze_multiplex(multiplex: multiplex) do
        query_results = multiplex.queries.map do |query|
          if query.valid?
            analyze_query(
              query,
              query.analyzers,
              multiplex_analyzers: multiplex_analyzers
            )
          else
            []
          end
        end

        multiplex_results = multiplex_analyzers.map(&:result)
        multiplex_errors = analysis_errors(multiplex_results)

        multiplex.queries.each_with_index do |query, idx|
          query.analysis_errors = multiplex_errors + analysis_errors(query_results[idx])
        end
        multiplex_results
      end
    end

    # @param query [GraphQL::Query]
    # @param analyzers [Array<GraphQL::Analysis::Analyzer>]
    # @return [Array<Any>] Results from those analyzers
    def analyze_query(query, analyzers, multiplex_analyzers: [])
      query.current_trace.analyze_query(query: query) do
        query_analyzers = analyzers
          .map { |analyzer| analyzer.new(query) }
          .tap { _1.select!(&:analyze?) }

        analyzers_to_run = query_analyzers + multiplex_analyzers
        if !analyzers_to_run.empty?

          analyzers_to_run.select!(&:visit?)
          if !analyzers_to_run.empty?
            visitor = GraphQL::Analysis::Visitor.new(
              query: query,
              analyzers: analyzers_to_run
            )

            # `nil` or `0` causes no timeout
            Timeout::timeout(query.validate_timeout_remaining) do
              visitor.visit
            end

            if !visitor.rescued_errors.empty?
              return visitor.rescued_errors
            end
          end

          query_analyzers.map(&:result)
        else
          []
        end
      end
    rescue Timeout::Error
      [GraphQL::AnalysisError.new("Timeout on validation of query")]
    rescue GraphQL::UnauthorizedError, GraphQL::ExecutionError
      # This error was raised during analysis and will be returned the client before execution
      []
    end

    def analysis_errors(results)
      results.flatten.tap { _1.select! { |r| r.is_a?(GraphQL::AnalysisError) } }
    end
  end
end
