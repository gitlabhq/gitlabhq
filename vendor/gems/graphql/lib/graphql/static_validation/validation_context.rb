# frozen_string_literal: true
module GraphQL
  module StaticValidation
    # The validation context gets passed to each validator.
    #
    # It exposes a {GraphQL::Language::Visitor} where validators may add hooks. ({Language::Visitor#visit} is called in {Validator#validate})
    #
    # It provides access to the schema & fragments which validators may read from.
    #
    # It holds a list of errors which each validator may add to.
    class ValidationContext
      extend Forwardable

      attr_reader :query, :errors, :visitor,
        :on_dependency_resolve_handlers,
        :max_errors, :types, :schema


      def_delegators :@query, :document, :fragments, :operations

      def initialize(query, visitor_class, max_errors)
        @query = query
        @types = query.types # TODO update migrated callers to use this accessor
        @schema = query.schema
        @literal_validator = LiteralValidator.new(context: query.context)
        @errors = []
        @max_errors = max_errors || Float::INFINITY
        @on_dependency_resolve_handlers = []
        @visitor = visitor_class.new(document, self)
      end

      # TODO stop using def_delegators because of Array allocations
      def_delegators :@visitor,
        :path, :type_definition, :field_definition, :argument_definition,
        :parent_type_definition, :directive_definition, :object_types, :dependencies

      def on_dependency_resolve(&handler)
        @on_dependency_resolve_handlers << handler
      end

      def validate_literal(ast_value, type)
        @literal_validator.validate(ast_value, type)
      end

      def too_many_errors?
        @errors.length >= @max_errors
      end

      def schema_directives
        @schema_directives ||= schema.directives
      end

      def did_you_mean_suggestion(name, options)
        if did_you_mean = schema.did_you_mean
          suggestions = did_you_mean::SpellChecker.new(dictionary: options).correct(name)
          case suggestions.size
          when 0
            ""
          when 1
            " (Did you mean `#{suggestions.first}`?)"
          else
            last_sugg = suggestions.pop
            " (Did you mean #{suggestions.map {|s| "`#{s}`"}.join(", ")} or `#{last_sugg}`?)"
          end
        end
      end
    end
  end
end
