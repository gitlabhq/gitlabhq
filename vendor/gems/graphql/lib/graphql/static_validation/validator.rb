# frozen_string_literal: true
require "timeout"

module GraphQL
  module StaticValidation
    # Initialized with a {GraphQL::Schema}, then it can validate {GraphQL::Language::Nodes::Documents}s based on that schema.
    #
    # By default, it's used by {GraphQL::Query}
    #
    # @example Validate a query
    #   validator = GraphQL::StaticValidation::Validator.new(schema: MySchema)
    #   query = GraphQL::Query.new(MySchema, query_string)
    #   errors = validator.validate(query)[:errors]
    #
    class Validator
      # @param schema [GraphQL::Schema]
      # @param rules [Array<#validate(context)>] a list of rules to use when validating
      def initialize(schema:, rules: GraphQL::StaticValidation::ALL_RULES)
        @schema = schema
        @rules = rules
      end

      # Validate `query` against the schema. Returns an array of message hashes.
      # @param query [GraphQL::Query]
      # @param validate [Boolean]
      # @param timeout [Float] Number of seconds to wait before aborting validation. Any positive number may be used, including Floats to specify fractional seconds.
      # @param max_errors [Integer] Maximum number of errors before aborting validation. Any positive number will limit the number of errors. Defaults to nil for no limit.
      # @return [Array<Hash>]
      def validate(query, validate: true, timeout: nil, max_errors: nil)
        errors = nil
        query.current_trace.begin_validate(query, validate)
        query.current_trace.validate(validate: validate, query: query) do
          begin_t = Time.now
          errors = if validate == false
            []
          else
            rules_to_use = validate ? @rules : []
            visitor_class = BaseVisitor.including_rules(rules_to_use)

            context = GraphQL::StaticValidation::ValidationContext.new(query, visitor_class, max_errors)

            begin
              # CAUTION: Usage of the timeout module makes the assumption that validation rules are stateless Ruby code that requires no cleanup if process was interrupted. This means no blocking IO calls, native gems, locks, or `rescue` clauses that must be reached.
              # A timeout value of 0 or nil will execute the block without any timeout.
              Timeout::timeout(timeout) do
                catch(:too_many_validation_errors) do
                  context.visitor.visit
                end
              end
            rescue Timeout::Error
              handle_timeout(query, context)
            end

            context.errors
          end

          {
            remaining_timeout: timeout ? (timeout - (Time.now - begin_t)) : nil,
            errors: errors,
          }
        end
      rescue GraphQL::ExecutionError => e
        errors = [e]
        {
          remaining_timeout: nil,
          errors: errors,
        }
      ensure
        query.current_trace.end_validate(query, validate, errors)
      end

      # Invoked when static validation times out.
      # @param query [GraphQL::Query]
      # @param context [GraphQL::StaticValidation::ValidationContext]
      def handle_timeout(query, context)
        context.errors << GraphQL::StaticValidation::ValidationTimeoutError.new(
          "Timeout on validation of query"
        )
      end
    end
  end
end
