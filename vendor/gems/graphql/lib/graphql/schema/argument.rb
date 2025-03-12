# frozen_string_literal: true
module GraphQL
  class Schema
    class Argument
      include GraphQL::Schema::Member::HasPath
      include GraphQL::Schema::Member::HasAstNode
      include GraphQL::Schema::Member::HasDirectives
      include GraphQL::Schema::Member::HasDeprecationReason
      include GraphQL::Schema::Member::HasValidators
      include GraphQL::EmptyObjects

      # @return [String] the GraphQL name for this argument, camelized unless `camelize: false` is provided
      attr_reader :name
      alias :graphql_name :name

      # @return [GraphQL::Schema::Field, Class] The field or input object this argument belongs to
      attr_reader :owner

      # @param new_prepare [Method, Proc]
      # @return [Symbol] A method or proc to call to transform this value before sending it to field resolution method
      def prepare(new_prepare = NOT_CONFIGURED)
        if new_prepare != NOT_CONFIGURED
          @prepare = new_prepare
        end
        @prepare
      end

      # @return [Symbol] This argument's name in Ruby keyword arguments
      attr_reader :keyword

      # @return [Class, Module, nil] If this argument should load an application object, this is the type of object to load
      attr_reader :loads

      # @return [Boolean] true if a resolver defined this argument
      def from_resolver?
        @from_resolver
      end

      # @param arg_name [Symbol]
      # @param type_expr
      # @param desc [String]
      # @param required [Boolean, :nullable] if true, this argument is non-null; if false, this argument is nullable. If `:nullable`, then the argument must be provided, though it may be `null`.
      # @param description [String]
      # @param default_value [Object]
      # @param as [Symbol] Override the keyword name when passed to a method
      # @param prepare [Symbol] A method to call to transform this argument's valuebefore sending it to field resolution
      # @param camelize [Boolean] if true, the name will be camelized when building the schema
      # @param from_resolver [Boolean] if true, a Resolver class defined this argument
      # @param directives [Hash{Class => Hash}]
      # @param deprecation_reason [String]
      # @param validates [Hash, nil] Options for building validators, if any should be applied
      # @param replace_null_with_default [Boolean] if `true`, incoming values of `null` will be replaced with the configured `default_value`
      def initialize(arg_name = nil, type_expr = nil, desc = nil, required: true, type: nil, name: nil, loads: nil, description: nil, comment: nil, ast_node: nil, default_value: NOT_CONFIGURED, as: nil, from_resolver: false, camelize: true, prepare: nil, owner:, validates: nil, directives: nil, deprecation_reason: nil, replace_null_with_default: false, &definition_block)
        arg_name ||= name
        @name = -(camelize ? Member::BuildType.camelize(arg_name.to_s) : arg_name.to_s)
        NameValidator.validate!(@name)
        @type_expr = type_expr || type
        @description = desc || description
        @comment = comment
        @null = required != true
        @default_value = default_value
        if replace_null_with_default
          if !default_value?
            raise ArgumentError, "`replace_null_with_default: true` requires a default value, please provide one with `default_value: ...`"
          end
          @replace_null_with_default = true
        end

        @owner = owner
        @as = as
        @loads = loads
        @keyword = as || (arg_name.is_a?(Symbol) ? arg_name : Schema::Member::BuildType.underscore(@name).to_sym)
        @prepare = prepare
        @ast_node = ast_node
        @from_resolver = from_resolver
        self.deprecation_reason = deprecation_reason

        if directives
          directives.each do |dir_class, dir_options|
            directive(dir_class, **dir_options)
          end
        end

        if validates && !validates.empty?
          self.validates(validates)
        end

        if required == :nullable
          self.owner.validates(required: { argument: arg_name })
        end

        if definition_block
          # `self` will still be self, it will also be the first argument to the block:
          instance_exec(self, &definition_block)
        end
      end

      def inspect
        "#<#{self.class} #{path}: #{type.to_type_signature}#{description ? " @description=#{description.inspect}" : ""}>"
      end

      # @param default_value [Object] The value to use when the client doesn't provide one
      # @return [Object] the value used when the client doesn't provide a value for this argument
      def default_value(new_default_value = NOT_CONFIGURED)
        if new_default_value != NOT_CONFIGURED
          @default_value = new_default_value
        end
        @default_value
      end

      # @return [Boolean] True if this argument has a default value
      def default_value?
        @default_value != NOT_CONFIGURED
      end

      def replace_null_with_default?
        @replace_null_with_default
      end

      attr_writer :description

      # @return [String] Documentation for this argument
      def description(text = nil)
        if text
          @description = text
        else
          @description
        end
      end

      attr_writer :comment

      # @return [String] Comment for this argument
      def comment(text = nil)
        if text
          @comment = text
        else
          @comment
        end
      end

      # @return [String] Deprecation reason for this argument
      def deprecation_reason(text = nil)
        if text
          self.deprecation_reason = text
        else
          super()
        end
      end

      def deprecation_reason=(new_reason)
        validate_deprecated_or_optional(null: @null, deprecation_reason: new_reason)
        super
      end

      def visible?(context)
        true
      end

      def authorized?(obj, value, ctx)
        authorized_as_type?(obj, value, ctx, as_type: type)
      end

      def authorized_as_type?(obj, value, ctx, as_type:)
        if value.nil?
          return true
        end

        if as_type.kind.non_null?
          as_type = as_type.of_type
        end

        if as_type.kind.list?
          value.each do |v|
            if !authorized_as_type?(obj, v, ctx, as_type: as_type.of_type)
              return false
            end
          end
        elsif as_type.kind.input_object?
          return as_type.authorized?(obj, value, ctx)
        end
        # None of the early-return conditions were activated,
        # so this is authorized.
        true
      end

      def type=(new_type)
        validate_input_type(new_type)
        # This isn't true for LateBoundTypes, but we can assume those will
        # be updated via this codepath later in schema setup.
        if new_type.respond_to?(:non_null?)
          validate_deprecated_or_optional(null: !new_type.non_null?, deprecation_reason: deprecation_reason)
        end
        @type = new_type
      end

      def type
        @type ||= begin
          parsed_type = begin
            Member::BuildType.parse_type(@type_expr, null: @null)
          rescue StandardError => err
            raise ArgumentError, "Couldn't build type for Argument #{@owner.name}.#{name}: #{err.class.name}: #{err.message}", err.backtrace
          end
          # Use the setter method to get validations
          self.type = parsed_type
        end
      end

      def statically_coercible?
        return @statically_coercible if defined?(@statically_coercible)
        requires_parent_object = @prepare.is_a?(String) || @prepare.is_a?(Symbol) || @own_validators
        @statically_coercible = !requires_parent_object
      end

      # Apply the {prepare} configuration to `value`, using methods from `obj`.
      # Used by the runtime.
      # @api private
      def prepare_value(obj, value, context: nil)
        if type.unwrap.kind.input_object?
          value = recursively_prepare_input_object(value, type)
        end

        Schema::Validator.validate!(validators, obj, context, value)

        if @prepare.nil?
          value
        elsif @prepare.is_a?(String) || @prepare.is_a?(Symbol)
          if obj.nil?
            # The problem here is, we _used to_ prepare while building variables.
            # But now we don't have the runtime object there.
            #
            # This will have to be called later, when the runtime object _is_ available.
            value
          elsif obj.respond_to?(@prepare)
            obj.public_send(@prepare, value)
          elsif owner.respond_to?(@prepare)
            owner.public_send(@prepare, value, context || obj.context)
          else
            raise "Invalid prepare for #{@owner.name}.name: #{@prepare.inspect}. "\
              "Could not find prepare method #{@prepare} on #{obj.class} or #{owner}."
          end
        elsif @prepare.respond_to?(:call)
          @prepare.call(value, context || obj.context)
        else
          raise "Invalid prepare for #{@owner.name}.name: #{@prepare.inspect}"
        end
      end

      # @api private
      def coerce_into_values(parent_object, values, context, argument_values)
        arg_name = graphql_name
        arg_key = keyword
        default_used = false

        if values.key?(arg_name)
          value = values[arg_name]
        elsif values.key?(arg_key)
          value = values[arg_key]
        elsif default_value?
          value = default_value
          default_used = true
        else
          # no value at all
          owner.validate_directive_argument(self, nil)
          return
        end

        if value.nil? && replace_null_with_default?
          value = default_value
          default_used = true
        end

        loaded_value = nil
        coerced_value = begin
          type.coerce_input(value, context)
        rescue StandardError => err
          context.schema.handle_or_reraise(context, err)
        end

        # If this isn't lazy, then the block returns eagerly and assigns the result here
        # If it _is_ lazy, then we write the lazy to the hash, then update it later
        argument_values[arg_key] = context.query.after_lazy(coerced_value) do |resolved_coerced_value|
          owner.validate_directive_argument(self, resolved_coerced_value)
          prepared_value = begin
            prepare_value(parent_object, resolved_coerced_value, context: context)
          rescue StandardError => err
            context.schema.handle_or_reraise(context, err)
          end

          if loads && !from_resolver?
            loaded_value = begin
              load_and_authorize_value(owner, prepared_value, context)
            rescue StandardError => err
              context.schema.handle_or_reraise(context, err)
            end
          end

          maybe_loaded_value = loaded_value || prepared_value
          context.query.after_lazy(maybe_loaded_value) do |resolved_loaded_value|
            # TODO code smell to access such a deeply-nested constant in a distant module
            argument_values[arg_key] = GraphQL::Execution::Interpreter::ArgumentValue.new(
              value: resolved_loaded_value,
              original_value: resolved_coerced_value,
              definition: self,
              default_used: default_used,
            )
          end
        end
      end

      def load_and_authorize_value(load_method_owner, coerced_value, context)
        if coerced_value.nil?
          return nil
        end
        arg_load_method = "load_#{keyword}"
        if load_method_owner.respond_to?(arg_load_method)
          custom_loaded_value = if load_method_owner.is_a?(Class)
            load_method_owner.public_send(arg_load_method, coerced_value, context)
          else
            load_method_owner.public_send(arg_load_method, coerced_value)
          end
          context.query.after_lazy(custom_loaded_value) do |custom_value|
            if loads
              if type.list?
                loaded_values = []
                context.dataloader.run_isolated do
                  custom_value.each_with_index.map { |custom_val, idx|
                    id = coerced_value[idx]
                    context.dataloader.append_job do
                      loaded_values[idx] = load_method_owner.authorize_application_object(self, id, context, custom_val)
                    end
                  }
                end
                context.schema.after_any_lazies(loaded_values, &:itself)
              else
                load_method_owner.authorize_application_object(self, coerced_value, context, custom_loaded_value)
              end
            else
              custom_value
            end
          end
        elsif loads
          if type.list?
            loaded_values = []
            # We want to run these list items all together,
            # but we also need to wait for the result so we can return it :S
            context.dataloader.run_isolated do
              coerced_value.each_with_index { |val, idx|
                context.dataloader.append_job do
                  loaded_values[idx] = load_method_owner.load_and_authorize_application_object(self, val, context)
                end
              }
            end
            context.schema.after_any_lazies(loaded_values, &:itself)
          else
            load_method_owner.load_and_authorize_application_object(self, coerced_value, context)
          end
        else
          coerced_value
        end
      end

      # @api private
      def validate_default_value
        return unless default_value?
        coerced_default_value = begin
          # This is weird, but we should accept single-item default values for list-type arguments.
          # If we used `coerce_isolated_input` below, it would do this for us, but it's not really
          # the right thing here because we expect default values in application format (Ruby values)
          # not GraphQL format (scalar values).
          #
          # But I don't think Schema::List#coerce_result should apply wrapping to single-item lists.
          prepped_default_value = if default_value.nil?
            nil
          elsif (type.kind.list? || (type.kind.non_null? && type.of_type.list?)) && !default_value.respond_to?(:map)
            [default_value]
          else
            default_value
          end

          type.coerce_isolated_result(prepped_default_value) unless prepped_default_value.nil?
        rescue GraphQL::Schema::Enum::UnresolvedValueError
          # It raises this, which is helpful at runtime, but not here...
          default_value
        end
        res = type.valid_isolated_input?(coerced_default_value)
        if !res
          raise InvalidDefaultValueError.new(self)
        end
      end

      class InvalidDefaultValueError < GraphQL::Error
        def initialize(argument)
          message = "`#{argument.path}` has an invalid default value: `#{argument.default_value.inspect}` isn't accepted by `#{argument.type.to_type_signature}`; update the default value or the argument type."
          super(message)
        end
      end

      private

      def recursively_prepare_input_object(value, type)
        if type.non_null?
          type = type.of_type
        end

        if type.list? && !value.nil?
          inner_type = type.of_type
          value.map { |v| recursively_prepare_input_object(v, inner_type) }
        elsif value.is_a?(GraphQL::Schema::InputObject)
          value.prepare
        else
          value
        end
      end

      def validate_input_type(input_type)
        if input_type.is_a?(String) || input_type.is_a?(GraphQL::Schema::LateBoundType)
          # Do nothing; assume this will be validated later
        elsif input_type.kind.non_null? || input_type.kind.list?
          validate_input_type(input_type.unwrap)
        elsif !input_type.kind.input?
          raise ArgumentError, "Invalid input type for #{path}: #{input_type.graphql_name}. Must be scalar, enum, or input object, not #{input_type.kind.name}."
        else
          # It's an input type, we're OK
        end
      end

      def validate_deprecated_or_optional(null:, deprecation_reason:)
        if deprecation_reason && !null
          raise ArgumentError, "Required arguments cannot be deprecated: #{path}."
        end
      end
    end
  end
end
