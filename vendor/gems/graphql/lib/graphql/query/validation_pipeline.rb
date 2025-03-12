# frozen_string_literal: true
module GraphQL
  class Query
    # Contain the validation pipeline and expose the results.
    #
    # 0. Checks in {Query#initialize}:
    #   - Rescue a ParseError, halt if there is one
    #   - Check for selected operation, halt if not found
    # 1. Validate the AST, halt if errors
    # 2. Validate the variables, halt if errors
    # 3. Run query analyzers, halt if errors
    #
    # {#valid?} is false if any of the above checks halted the pipeline.
    #
    # @api private
    class ValidationPipeline
      attr_reader :max_depth, :max_complexity, :validate_timeout_remaining

      def initialize(query:, parse_error:, operation_name_error:, max_depth:, max_complexity:)
        @validation_errors = []
        @parse_error = parse_error
        @operation_name_error = operation_name_error
        @query = query
        @schema = query.schema
        @max_depth = max_depth
        @max_complexity = max_complexity

        @has_validated = false
      end

      # @return [Boolean] does this query have errors that should prevent it from running?
      def valid?
        ensure_has_validated
        @valid
      end

      # @return [Array<GraphQL::StaticValidation::Error, GraphQL::Query::VariableValidationError>] Static validation errors for the query string
      def validation_errors
        ensure_has_validated
        @validation_errors
      end

      def analyzers
        ensure_has_validated
        @query_analyzers
      end

      def has_validated?
        @has_validated == true
      end

      private

      # If the pipeline wasn't run yet, run it.
      # If it was already run, do nothing.
      def ensure_has_validated
        return if @has_validated
        @has_validated = true

        if @parse_error
          # This is kind of crazy: we push the parse error into `ctx`
          # in `def self.parse_error` by default so that users can _opt out_ by redefining that hook.
          # That means we can't _re-add_ the error here (otherwise we'd either
          # add it twice _or_ override the user's choice to not add it).
          # So we just have to know that it was invalid and go from there.
          @valid = false
          return
        elsif @operation_name_error
          @validation_errors << @operation_name_error
        else
          validator = @query.static_validator || @schema.static_validator
          validation_result = validator.validate(@query, validate: @query.validate, timeout: @schema.validate_timeout, max_errors: @schema.validate_max_errors)
          @validation_errors.concat(validation_result[:errors])
          @validate_timeout_remaining = validation_result[:remaining_timeout]
          if @validation_errors.empty?
            @validation_errors.concat(@query.variables.errors)
          end

          if @validation_errors.empty?
            @query_analyzers = build_analyzers(
              @schema,
              @max_depth,
              @max_complexity
            )
          end
        end

        @valid = @validation_errors.empty?
      rescue SystemStackError => err
        @valid = false
        @schema.query_stack_error(@query, err)
      end

      # If there are max_* values, add them,
      # otherwise reuse the schema's list of analyzers.
      def build_analyzers(schema, max_depth, max_complexity)
        qa = schema.query_analyzers.dup

        if max_depth || max_complexity
          # Depending on the analysis engine, we must use different analyzers
          # remove this once everything has switched over to AST analyzers
          if max_depth
            qa << GraphQL::Analysis::MaxQueryDepth
          end
          if max_complexity
            qa << GraphQL::Analysis::MaxQueryComplexity
          end
          qa
        else
          qa
        end
      end
    end
  end
end
