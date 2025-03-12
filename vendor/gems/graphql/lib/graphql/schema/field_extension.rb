# frozen_string_literal: true
module GraphQL
  class Schema
    # Extend this class to make field-level customizations to resolve behavior.
    #
    # When a extension is added to a field with `extension(MyExtension)`, a `MyExtension` instance
    # is created, and its hooks are applied whenever that field is called.
    #
    # The instance is frozen so that instance variables aren't modified during query execution,
    # which could cause all kinds of issues due to race conditions.
    class FieldExtension
      # @return [GraphQL::Schema::Field]
      attr_reader :field

      # @return [Object]
      attr_reader :options

      # @return [Array<Symbol>, nil] `default_argument`s added, if any were added (otherwise, `nil`)
      attr_reader :added_default_arguments

      # Called when the extension is mounted with `extension(name, options)`.
      # The instance will be frozen to avoid improper use of state during execution.
      # @param field [GraphQL::Schema::Field] The field where this extension was mounted
      # @param options [Object] The second argument to `extension`, or `{}` if nothing was passed.
      def initialize(field:, options:)
        @field = field
        @options = options || {}
        @added_default_arguments = nil
        apply
      end

      class << self
        # @return [Array(Array, Hash), nil] A list of default argument configs, or `nil` if there aren't any
        def default_argument_configurations
          args = superclass.respond_to?(:default_argument_configurations) ? superclass.default_argument_configurations : nil
          if @own_default_argument_configurations
            if args
              args.concat(@own_default_argument_configurations)
            else
              args = @own_default_argument_configurations.dup
            end
          end
          args
        end

        # @see Argument#initialize
        # @see HasArguments#argument
        def default_argument(*argument_args, **argument_kwargs)
          configs = @own_default_argument_configurations ||= []
          configs << [argument_args, argument_kwargs]
        end

        # If configured, these `extras` will be added to the field if they aren't already present,
        # but removed by from `arguments` before the field's `resolve` is called.
        # (The extras _will_ be present for other extensions, though.)
        #
        # @param new_extras [Array<Symbol>] If provided, assign extras used by this extension
        # @return [Array<Symbol>] any extras assigned to this extension
        def extras(new_extras = nil)
          if new_extras
            @own_extras = new_extras
          end

          inherited_extras = self.superclass.respond_to?(:extras) ? superclass.extras : nil
          if @own_extras
            if inherited_extras
              inherited_extras + @own_extras
            else
              @own_extras
            end
          elsif inherited_extras
            inherited_extras
          else
            GraphQL::EmptyObjects::EMPTY_ARRAY
          end
        end
      end

      # Called when this extension is attached to a field.
      # The field definition may be extended during this method.
      # @return [void]
      def apply
      end

      # Called after the field's definition block has been executed.
      # (Any arguments from the block are present on `field`)
      # @return [void]
      def after_define
      end

      # @api private
      def after_define_apply
        after_define
        if (configs = self.class.default_argument_configurations)
          existing_keywords = field.all_argument_definitions.map(&:keyword)
          existing_keywords.uniq!
          @added_default_arguments = []
          configs.each do |config|
            argument_args, argument_kwargs = config
            arg_name = argument_args[0]
            if !existing_keywords.include?(arg_name)
              @added_default_arguments << arg_name
              field.argument(*argument_args, **argument_kwargs)
            end
          end
        end
        if !(extras = self.class.extras).empty?
          @added_extras = extras - field.extras
          field.extras(@added_extras)
        else
          @added_extras = nil
        end
        freeze
      end

      # @api private
      attr_reader :added_extras

      # Called before resolving {#field}. It should either:
      #
      # - `yield` values to continue execution; OR
      # - return something else to shortcut field execution.
      #
      # Whatever this method returns will be used for execution.
      #
      # @param object [Object] The object the field is being resolved on
      # @param arguments [Hash] Ruby keyword arguments for resolving this field
      # @param context [Query::Context] the context for this query
      # @yieldparam object [Object] The object to continue resolving the field on
      # @yieldparam arguments [Hash] The keyword arguments to continue resolving with
      # @yieldparam memo [Object] Any extension-specific value which will be passed to {#after_resolve} later
      # @return [Object] The return value for this field.
      def resolve(object:, arguments:, context:)
        yield(object, arguments, nil)
      end

      # Called after {#field} was resolved, and after any lazy values (like `Promise`s) were synced,
      # but before the value was added to the GraphQL response.
      #
      # Whatever this hook returns will be used as the return value.
      #
      # @param object [Object] The object the field is being resolved on
      # @param arguments [Hash] Ruby keyword arguments for resolving this field
      # @param context [Query::Context] the context for this query
      # @param value [Object] Whatever the field previously returned
      # @param memo [Object] The third value yielded by {#resolve}, or `nil` if there wasn't one
      # @return [Object] The return value for this field.
      def after_resolve(object:, arguments:, context:, value:, memo:)
        value
      end
    end
  end
end
