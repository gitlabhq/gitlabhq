# frozen_string_literal: true
require "graphql/schema/resolver/has_payload_type"

module GraphQL
  class Schema
    # A class-based container for field configuration and resolution logic. It supports:
    #
    # - Arguments, via `.argument(...)` helper, which will be applied to the field.
    # - Return type, via `.type(..., null: ...)`, which will be applied to the field.
    # - Description, via `.description(...)`, which will be applied to the field
    # - Comment, via `.comment(...)`, which will be applied to the field
    # - Resolution, via `#resolve(**args)` method, which will be called to resolve the field.
    # - `#object` and `#context` accessors for use during `#resolve`.
    #
    # Resolvers can be attached with the `resolver:` option in a `field(...)` call.
    #
    # A resolver's configuration may be overridden with other keywords in the `field(...)` call.
    #
    # @see {GraphQL::Schema::Mutation} for a concrete subclass of `Resolver`.
    # @see {GraphQL::Function} `Resolver` is a replacement for `GraphQL::Function`
    class Resolver
      include Schema::Member::GraphQLTypeNames
      # Really we only need description & comment from here, but:
      extend Schema::Member::BaseDSLMethods
      extend Member::BaseDSLMethods::ConfigurationExtension
      extend GraphQL::Schema::Member::HasArguments
      extend GraphQL::Schema::Member::HasValidators
      include Schema::Member::HasPath
      extend Schema::Member::HasPath
      extend Schema::Member::HasDirectives
      include Schema::Member::HasDataloader

      # @param object [Object] The application object that this field is being resolved on
      # @param context [GraphQL::Query::Context]
      # @param field [GraphQL::Schema::Field]
      def initialize(object:, context:, field:)
        @object = object
        @context = context
        @field = field
        # Since this hash is constantly rebuilt, cache it for this call
        @arguments_by_keyword = {}
        context.types.arguments(self.class).each do |arg|
          @arguments_by_keyword[arg.keyword] = arg
        end
        @prepared_arguments = nil
      end

      # @return [Object] The application object this field is being resolved on
      attr_reader :object

      # @return [GraphQL::Query::Context]
      attr_reader :context

      # @return [GraphQL::Schema::Field]
      attr_reader :field

      def arguments
        @prepared_arguments || raise("Arguments have not been prepared yet, still waiting for #load_arguments to resolve. (Call `.arguments` later in the code.)")
      end

      # This method is _actually_ called by the runtime,
      # it does some preparation and then eventually calls
      # the user-defined `#resolve` method.
      # @api private
      def resolve_with_support(**args)
        # First call the ready? hook which may raise
        raw_ready_val = if !args.empty?
          ready?(**args)
        else
          ready?
        end
        context.query.after_lazy(raw_ready_val) do |ready_val|
          if ready_val.is_a?(Array)
            is_ready, ready_early_return = ready_val
            if is_ready != false
              raise "Unexpected result from #ready? (expected `true`, `false` or `[false, {...}]`): [#{is_ready.inspect}, #{ready_early_return.inspect}]"
            else
              ready_early_return
            end
          elsif ready_val
            # Then call each prepare hook, which may return a different value
            # for that argument, or may return a lazy object
            load_arguments_val = load_arguments(args)
            context.query.after_lazy(load_arguments_val) do |loaded_args|
              @prepared_arguments = loaded_args
              Schema::Validator.validate!(self.class.validators, object, context, loaded_args, as: @field)
              # Then call `authorized?`, which may raise or may return a lazy object
              raw_authorized_val = if !loaded_args.empty?
                authorized?(**loaded_args)
              else
                authorized?
              end
              context.query.after_lazy(raw_authorized_val) do |authorized_val|
                # If the `authorized?` returned two values, `false, early_return`,
                # then use the early return value instead of continuing
                if authorized_val.is_a?(Array)
                  authorized_result, early_return = authorized_val
                  if authorized_result == false
                    early_return
                  else
                    raise "Unexpected result from #authorized? (expected `true`, `false` or `[false, {...}]`): [#{authorized_result.inspect}, #{early_return.inspect}]"
                  end
                elsif authorized_val
                  # Finally, all the hooks have passed, so resolve it
                  call_resolve(loaded_args)
                else
                  raise GraphQL::UnauthorizedFieldError.new(context: context, object: object, type: field.owner, field: field)
                end
              end
            end
          end
        end
      end

      # @api private {GraphQL::Schema::Mutation} uses this to clear the dataloader cache
      def call_resolve(args_hash)
        if !args_hash.empty?
          public_send(self.class.resolve_method, **args_hash)
        else
          public_send(self.class.resolve_method)
        end
      end

      # Do the work. Everything happens here.
      # @return [Object] An object corresponding to the return type
      def resolve(**args)
        raise GraphQL::RequiredImplementationMissingError, "#{self.class.name}#resolve should execute the field's logic"
      end

      # Called before arguments are prepared.
      # Implement this hook to make checks before doing any work.
      #
      # If it returns a lazy object (like a promise), it will be synced by GraphQL
      # (but the resulting value won't be used).
      #
      # @param args [Hash] The input arguments, if there are any
      # @raise [GraphQL::ExecutionError] To add an error to the response
      # @raise [GraphQL::UnauthorizedError] To signal an authorization failure
      # @return [Boolean, early_return_data] If `false`, execution will stop (and `early_return_data` will be returned instead, if present.)
      def ready?(**args)
        true
      end

      # Called after arguments are loaded, but before resolving.
      #
      # Override it to check everything before calling the mutation.
      # @param inputs [Hash] The input arguments
      # @raise [GraphQL::ExecutionError] To add an error to the response
      # @raise [GraphQL::UnauthorizedError] To signal an authorization failure
      # @return [Boolean, early_return_data] If `false`, execution will stop (and `early_return_data` will be returned instead, if present.)
      def authorized?(**inputs)
        arg_owner = @field # || self.class
        args = context.types.arguments(arg_owner)
        authorize_arguments(args, inputs)
      end

      # Called when an object loaded by `loads:` fails the `.authorized?` check for its resolved GraphQL object type.
      #
      # By default, the error is re-raised and passed along to {{Schema.unauthorized_object}}.
      #
      # Any value returned here will be used _instead of_ of the loaded object.
      # @param err [GraphQL::UnauthorizedError]
      def unauthorized_object(err)
        raise err
      end

      private

      def authorize_arguments(args, inputs)
        args.each do |argument|
          arg_keyword = argument.keyword
          if inputs.key?(arg_keyword) && !(arg_value = inputs[arg_keyword]).nil? && (arg_value != argument.default_value)
            auth_result = argument.authorized?(self, arg_value, context)
            if auth_result.is_a?(Array)
              # only return this second value if the application returned a second value
              arg_auth, err = auth_result
              if !arg_auth
                return arg_auth, err
              end
            elsif auth_result == false
              return auth_result
            end
          end
        end
        true
      end

      def load_arguments(args)
        prepared_args = {}
        prepare_lazies = []

        args.each do |key, value|
          arg_defn = @arguments_by_keyword[key]
          if arg_defn
            prepped_value = prepared_args[key] = arg_defn.load_and_authorize_value(self, value, context)
            if context.schema.lazy?(prepped_value)
              prepare_lazies << context.query.after_lazy(prepped_value) do |finished_prepped_value|
                prepared_args[key] = finished_prepped_value
              end
            end
          else
            # these are `extras:`
            prepared_args[key] = value
          end
        end

        # Avoid returning a lazy if none are needed
        if !prepare_lazies.empty?
          GraphQL::Execution::Lazy.all(prepare_lazies).then { prepared_args }
        else
          prepared_args
        end
      end

      def get_argument(name, context = GraphQL::Query::NullContext.instance)
        self.class.get_argument(name, context)
      end

      class << self
        def field_arguments(context = GraphQL::Query::NullContext.instance)
          arguments(context)
        end

        def any_field_arguments?
          any_arguments?
        end

        def get_field_argument(name, context = GraphQL::Query::NullContext.instance)
          get_argument(name, context)
        end

        def all_field_argument_definitions
          all_argument_definitions
        end

        # Default `:resolve` set below.
        # @return [Symbol] The method to call on instances of this object to resolve the field
        def resolve_method(new_method = nil)
          if new_method
            @resolve_method = new_method
          end
          @resolve_method || (superclass.respond_to?(:resolve_method) ? superclass.resolve_method : :resolve)
        end

        # Additional info injected into {#resolve}
        # @see {GraphQL::Schema::Field#extras}
        def extras(new_extras = nil)
          if new_extras
            @own_extras = new_extras
          end
          own_extras = @own_extras || []
          own_extras + (superclass.respond_to?(:extras) ? superclass.extras : [])
        end

        # If `true` (default), then the return type for this resolver will be nullable.
        # If `false`, then the return type is non-null.
        #
        # @see #type which sets the return type of this field and accepts a `null:` option
        # @param allow_null [Boolean] Whether or not the response can be null
        def null(allow_null = nil)
          if !allow_null.nil?
            @null = allow_null
          end

          @null.nil? ? (superclass.respond_to?(:null) ? superclass.null : true) : @null
        end

        def resolver_method(new_method_name = nil)
          if new_method_name
            @resolver_method = new_method_name
          else
            @resolver_method || :resolve_with_support
          end
        end

        # Call this method to get the return type of the field,
        # or use it as a configuration method to assign a return type
        # instead of generating one.
        # TODO unify with {#null}
        # @param new_type [Class, Array<Class>, nil] If a type definition class is provided, it will be used as the return type of the field
        # @param null [true, false] Whether or not the field may return `nil`
        # @return [Class] The type which this field returns.
        def type(new_type = nil, null: nil)
          if new_type
            if null.nil?
              raise ArgumentError, "required argument `null:` is missing"
            end
            @type_expr = new_type
            @null = null
          else
            if type_expr
              GraphQL::Schema::Member::BuildType.parse_type(type_expr, null: self.null)
            elsif superclass.respond_to?(:type)
              superclass.type
            else
              nil
            end
          end
        end

        # Specifies the complexity of the field. Defaults to `1`
        # @return [Integer, Proc]
        def complexity(new_complexity = nil)
          if new_complexity
            @complexity = new_complexity
          end
          @complexity || (superclass.respond_to?(:complexity) ? superclass.complexity : 1)
        end

        def broadcastable(new_broadcastable)
          @broadcastable = new_broadcastable
        end

        # @return [Boolean, nil]
        def broadcastable?
          if defined?(@broadcastable)
            @broadcastable
          else
            (superclass.respond_to?(:broadcastable?) ? superclass.broadcastable? : nil)
          end
        end

        # Get or set the `max_page_size:` which will be configured for fields using this resolver
        # (`nil` means "unlimited max page size".)
        # @param max_page_size [Integer, nil] Set a new value
        # @return [Integer, nil] The `max_page_size` assigned to fields that use this resolver
        def max_page_size(new_max_page_size = NOT_CONFIGURED)
          if new_max_page_size != NOT_CONFIGURED
            @max_page_size = new_max_page_size
          elsif defined?(@max_page_size)
            @max_page_size
          elsif superclass.respond_to?(:max_page_size)
            superclass.max_page_size
          else
            nil
          end
        end

        # @return [Boolean] `true` if this resolver or a superclass has an assigned `max_page_size`
        def has_max_page_size?
          (!!defined?(@max_page_size)) || (superclass.respond_to?(:has_max_page_size?) && superclass.has_max_page_size?)
        end

        # Get or set the `default_page_size:` which will be configured for fields using this resolver
        # (`nil` means "unlimited default page size".)
        # @param default_page_size [Integer, nil] Set a new value
        # @return [Integer, nil] The `default_page_size` assigned to fields that use this resolver
        def default_page_size(new_default_page_size = NOT_CONFIGURED)
          if new_default_page_size != NOT_CONFIGURED
            @default_page_size = new_default_page_size
          elsif defined?(@default_page_size)
            @default_page_size
          elsif superclass.respond_to?(:default_page_size)
            superclass.default_page_size
          else
            nil
          end
        end

        # @return [Boolean] `true` if this resolver or a superclass has an assigned `default_page_size`
        def has_default_page_size?
          (!!defined?(@default_page_size)) || (superclass.respond_to?(:has_default_page_size?) && superclass.has_default_page_size?)
        end

        # A non-normalized type configuration, without `null` applied
        def type_expr
          @type_expr || (superclass.respond_to?(:type_expr) ? superclass.type_expr : nil)
        end

        # Add an argument to this field's signature, but
        # also add some preparation hook methods which will be used for this argument
        # @see {GraphQL::Schema::Argument#initialize} for the signature
        def argument(*args, **kwargs, &block)
          # Use `from_resolver: true` to short-circuit the InputObject's own `loads:` implementation
          # so that we can support `#load_{x}` methods below.
          super(*args, from_resolver: true, **kwargs)
        end

        # Registers new extension
        # @param extension [Class] Extension class
        # @param options [Hash] Optional extension options
        def extension(extension, **options)
          @own_extensions ||= []
          @own_extensions << {extension => options}
        end

        # @api private
        def extensions
          own_exts = @own_extensions
          # Jump through some hoops to avoid creating arrays when we don't actually need them
          if superclass.respond_to?(:extensions)
            s_exts = superclass.extensions
            if own_exts
              if !s_exts.empty?
                own_exts + s_exts
              else
                own_exts
              end
            else
              s_exts
            end
          else
            own_exts || EMPTY_ARRAY
          end
        end

        private

        attr_reader :own_extensions
      end
    end
  end
end
