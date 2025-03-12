# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # The thing being validated
      # @return [GraphQL::Schema::Argument, GraphQL::Schema::Field, GraphQL::Schema::Resolver, Class<GraphQL::Schema::InputObject>]
      attr_reader :validated

      # @param validated [GraphQL::Schema::Argument, GraphQL::Schema::Field, GraphQL::Schema::Resolver, Class<GraphQL::Schema::InputObject>] The argument or argument owner this validator is attached to
      # @param allow_blank [Boolean] if `true`, then objects that respond to `.blank?` and return true for `.blank?` will skip this validation
      # @param allow_null [Boolean] if `true`, then incoming `null`s will skip this validation
      def initialize(validated:, allow_blank: false, allow_null: false)
        @validated = validated
        @allow_blank = allow_blank
        @allow_null = allow_null
      end

      # @param object [Object] The application object that this argument's field is being resolved for
      # @param context [GraphQL::Query::Context]
      # @param value [Object] The client-provided value for this argument (after parsing and coercing by the input type)
      # @return [nil, Array<String>, String] Error message or messages to add
      def validate(object, context, value)
        raise GraphQL::RequiredImplementationMissingError, "Validator classes should implement #validate"
      end

      # This is like `String#%`, but it supports the case that only some of `string`'s
      # values are present in `substitutions`
      def partial_format(string, substitutions)
        substitutions.each do |key, value|
          sub_v = value.is_a?(String) ? value : value.to_s
          string = string.gsub("%{#{key}}", sub_v)
        end
        string
      end

      # @return [Boolean] `true` if `value` is `nil` and this validator has `allow_null: true` or if value is `.blank?` and this validator has `allow_blank: true`
      def permitted_empty_value?(value)
        (value.nil? && @allow_null) ||
          (@allow_blank && value.respond_to?(:blank?) && value.blank?)
      end

      # @param schema_member [GraphQL::Schema::Field, GraphQL::Schema::Argument, Class<GraphQL::Schema::InputObject>]
      # @param validates_hash [Hash{Symbol => Hash}, Hash{Class => Hash} nil] A configuration passed as `validates:`
      # @return [Array<Validator>]
      def self.from_config(schema_member, validates_hash)
        if validates_hash.nil? || validates_hash.empty?
          EMPTY_ARRAY
        else
          validates_hash = validates_hash.dup

          default_options = {}
          if validates_hash[:allow_null]
            default_options[:allow_null] = validates_hash.delete(:allow_null)
          end
          if validates_hash[:allow_blank]
            default_options[:allow_blank] = validates_hash.delete(:allow_blank)
          end

          # allow_nil or allow_blank are the _only_ validations:
          if validates_hash.empty?
            validates_hash = default_options
          end

          validates_hash.map do |validator_name, options|
            validator_class = case validator_name
            when Class
              validator_name
            else
              all_validators[validator_name] || raise(ArgumentError, "unknown validation: #{validator_name.inspect}")
            end
            if options.is_a?(Hash)
              validator_class.new(validated: schema_member, **(default_options.merge(options)))
            else
              validator_class.new(options, validated: schema_member, **default_options)
            end
          end
        end
      end

      # Add `validator_class` to be initialized when `validates:` is given `name`.
      # (It's initialized with whatever options are given by the key `name`).
      # @param name [Symbol]
      # @param validator_class [Class]
      # @return [void]
      def self.install(name, validator_class)
        all_validators[name] = validator_class
        nil
      end

      # Remove whatever validator class is {.install}ed at `name`, if there is one
      # @param name [Symbol]
      # @return [void]
      def self.uninstall(name)
        all_validators.delete(name)
        nil
      end

      class << self
        attr_accessor :all_validators
      end

      self.all_validators = {}

      include GraphQL::EmptyObjects

      class ValidationFailedError < GraphQL::ExecutionError
        attr_reader :errors

        def initialize(errors:)
          @errors = errors
          super(errors.join(", "))
        end
      end

      # @param validators [Array<Validator>]
      # @param object [Object]
      # @param context [Query::Context]
      # @param value [Object]
      # @return [void]
      # @raises [ValidationFailedError]
      def self.validate!(validators, object, context, value, as: nil)
        # Assuming the default case is no errors, reduce allocations in that case.
        # This will be replaced with a mutable array if we actually get any errors.
        all_errors = EMPTY_ARRAY

        validators.each do |validator|
          validated = as || validator.validated
          errors = validator.validate(object, context, value)
          if errors &&
              (errors.is_a?(Array) && errors != EMPTY_ARRAY) ||
              (errors.is_a?(String))
            if all_errors.frozen? # It's empty
              all_errors = []
            end
            interpolation_vars = { validated: validated.graphql_name, value: value.inspect }
            if errors.is_a?(String)
              all_errors << (errors % interpolation_vars)
            else
              errors = errors.map { |e| e % interpolation_vars }
              all_errors.concat(errors)
            end
          end
        end

        if !all_errors.empty?
          raise ValidationFailedError.new(errors: all_errors)
        end
        nil
      end
    end
  end
end


require "graphql/schema/validator/length_validator"
GraphQL::Schema::Validator.install(:length, GraphQL::Schema::Validator::LengthValidator)
require "graphql/schema/validator/numericality_validator"
GraphQL::Schema::Validator.install(:numericality, GraphQL::Schema::Validator::NumericalityValidator)
require "graphql/schema/validator/format_validator"
GraphQL::Schema::Validator.install(:format, GraphQL::Schema::Validator::FormatValidator)
require "graphql/schema/validator/inclusion_validator"
GraphQL::Schema::Validator.install(:inclusion, GraphQL::Schema::Validator::InclusionValidator)
require "graphql/schema/validator/exclusion_validator"
GraphQL::Schema::Validator.install(:exclusion, GraphQL::Schema::Validator::ExclusionValidator)
require "graphql/schema/validator/required_validator"
GraphQL::Schema::Validator.install(:required, GraphQL::Schema::Validator::RequiredValidator)
require "graphql/schema/validator/allow_null_validator"
GraphQL::Schema::Validator.install(:allow_null, GraphQL::Schema::Validator::AllowNullValidator)
require "graphql/schema/validator/allow_blank_validator"
GraphQL::Schema::Validator.install(:allow_blank, GraphQL::Schema::Validator::AllowBlankValidator)
require "graphql/schema/validator/all_validator"
GraphQL::Schema::Validator.install(:all, GraphQL::Schema::Validator::AllValidator)
