# frozen_string_literal: true

require "graphql/query/null_context"

module GraphQL
  class Schema
    class Object < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::HasFields
      extend GraphQL::Schema::Member::HasInterfaces
      include Member::HasDataloader

      # Raised when an Object doesn't have any field defined and hasn't explicitly opted out of this requirement
      class FieldsAreRequiredError < GraphQL::Error
        def initialize(object_type)
          message = "Object types must have fields, but #{object_type.graphql_name} doesn't have any. Define a field for this type, remove it from your schema, or add `has_no_fields(true)` to its definition."
          super(message)
        end
      end

      # @return [Object] the application object this type is wrapping
      attr_reader :object

      # @return [GraphQL::Query::Context] the context instance for this query
      attr_reader :context

      # @return [GraphQL::Dataloader]
      def dataloader
        context.dataloader
      end

      # Call this in a field method to return a value that should be returned to the client
      # without any further handling by GraphQL.
      def raw_value(obj)
        GraphQL::Execution::Interpreter::RawValue.new(obj)
      end

      class << self
        # This is protected so that we can be sure callers use the public method, {.authorized_new}
        # @see authorized_new to make instances
        protected :new

        def wrap_scoped(object, context)
          scoped_new(object, context)
        end

        # This is called by the runtime to return an object to call methods on.
        def wrap(object, context)
          authorized_new(object, context)
        end

        # Make a new instance of this type _if_ the auth check passes,
        # otherwise, raise an error.
        #
        # Probably only the framework should call this method.
        #
        # This might return a {GraphQL::Execution::Lazy} if the user-provided `.authorized?`
        # hook returns some lazy value (like a Promise).
        #
        # The reason that the auth check is in this wrapper method instead of {.new} is because
        # of how it might return a Promise. It would be weird if `.new` returned a promise;
        # It would be a headache to try to maintain Promise-y state inside a {Schema::Object}
        # instance. So, hopefully this wrapper method will do the job.
        #
        # @param object [Object] The thing wrapped by this object
        # @param context [GraphQL::Query::Context]
        # @return [GraphQL::Schema::Object, GraphQL::Execution::Lazy]
        # @raise [GraphQL::UnauthorizedError] if the user-provided hook returns `false`
        def authorized_new(object, context)
          context.query.current_trace.begin_authorized(self, object, context)
          begin
            maybe_lazy_auth_val = context.query.current_trace.authorized(query: context.query, type: self, object: object) do
              begin
                authorized?(object, context)
              rescue GraphQL::UnauthorizedError => err
                context.schema.unauthorized_object(err)
              rescue StandardError => err
                context.query.handle_or_reraise(err)
              end
            end
          ensure
            context.query.current_trace.end_authorized(self, object, context, maybe_lazy_auth_val)
          end

          auth_val = if context.schema.lazy?(maybe_lazy_auth_val)
            GraphQL::Execution::Lazy.new do
              context.query.current_trace.begin_authorized(self, object, context)
              context.query.current_trace.authorized_lazy(query: context.query, type: self, object: object) do
                res = context.schema.sync_lazy(maybe_lazy_auth_val)
                context.query.current_trace.end_authorized(self, object, context, res)
                res
              end
            end
          else
            maybe_lazy_auth_val
          end

          context.query.after_lazy(auth_val) do |is_authorized|
            if is_authorized
              self.new(object, context)
            else
              # It failed the authorization check, so go to the schema's authorized object hook
              err = GraphQL::UnauthorizedError.new(object: object, type: self, context: context)
              # If a new value was returned, wrap that instead of the original value
              begin
                new_obj = context.schema.unauthorized_object(err)
                if new_obj
                  self.new(new_obj, context)
                else
                  nil
                end
              end
            end
          end
        end

        def scoped_new(object, context)
          self.new(object, context)
        end
      end

      def initialize(object, context)
        @object = object
        @context = context
      end

      class << self
        # Set up a type-specific invalid null error to use when this object's non-null fields wrongly return `nil`.
        # It should help with debugging and bug tracker integrations.
        def const_missing(name)
          if name == :InvalidNullError
            custom_err_class = GraphQL::InvalidNullError.subclass_for(self)
            const_set(:InvalidNullError, custom_err_class)
            custom_err_class
          else
            super
          end
        end

        def kind
          GraphQL::TypeKinds::OBJECT
        end
      end
    end
  end
end
