# frozen_string_literal: true
require "securerandom"
require "graphql/subscriptions/broadcast_analyzer"
require "graphql/subscriptions/event"
require "graphql/subscriptions/serialize"
require "graphql/subscriptions/action_cable_subscriptions"
require "graphql/subscriptions/default_subscription_resolve_extension"

module GraphQL
  class Subscriptions
    # Raised when either:
    # - the triggered `event_name` doesn't match a field in the schema; or
    # - one or more arguments don't match the field arguments
    class InvalidTriggerError < GraphQL::Error
    end

    # Raised when either:
    # - An initial subscription didn't have a value for `context[subscription_scope]`
    # - Or, an update didn't pass `.trigger(..., scope:)`
    # When raised, the initial subscription or update fails completely.
    class SubscriptionScopeMissingError < GraphQL::Error
    end

    # @see {Subscriptions#initialize} for options, concrete implementations may add options.
    def self.use(defn, options = {})
      schema = defn.is_a?(Class) ? defn : defn.target

      if schema.subscriptions(inherited: false)
        raise ArgumentError, "Can't reinstall subscriptions. #{schema} is using #{schema.subscriptions}, can't also add #{self}"
      end

      options[:schema] = schema
      schema.subscriptions = self.new(**options)
      schema.add_subscription_extension_if_necessary
      nil
    end

    # @param schema [Class] the GraphQL schema this manager belongs to
    # @param validate_update [Boolean] If false, then validation is skipped when executing updates
    def initialize(schema:, validate_update: true, broadcast: false, default_broadcastable: false, **rest)
      if broadcast
        schema.query_analyzer(Subscriptions::BroadcastAnalyzer)
      end
      @default_broadcastable = default_broadcastable
      @schema = schema
      @validate_update = validate_update
    end

    # @return [Boolean] Used when fields don't have `broadcastable:` explicitly set
    attr_reader :default_broadcastable

    # Fetch subscriptions matching this field + arguments pair
    # And pass them off to the queue.
    # @param event_name [String]
    # @param args [Hash<String, Symbol => Object]
    # @param object [Object]
    # @param scope [Symbol, String]
    # @param context [Hash]
    # @return [void]
    def trigger(event_name, args, object, scope: nil, context: {})
      # Make something as context-like as possible, even though there isn't a current query:
      dummy_query = @schema.query_class.new(@schema, "{ __typename }", validate: false, context: context)
      context = dummy_query.context
      event_name = event_name.to_s

      # Try with the verbatim input first:
      field = dummy_query.types.field(@schema.subscription, event_name) # rubocop:disable Development/ContextIsPassedCop

      if field.nil?
        # And if it wasn't found, normalize it:
        normalized_event_name = normalize_name(event_name)
        field = dummy_query.types.field(@schema.subscription, normalized_event_name) # rubocop:disable Development/ContextIsPassedCop
        if field.nil?
          raise InvalidTriggerError, "No subscription matching trigger: #{event_name} (looked for #{@schema.subscription.graphql_name}.#{normalized_event_name})"
        end
      else
        # Since we found a field, the original input was already normalized
        normalized_event_name = event_name
      end

      # Normalize symbol-keyed args to strings, try camelizing them
      # Should this accept a real context somehow?
      normalized_args = normalize_arguments(normalized_event_name, field, args, GraphQL::Query::NullContext.instance)

      event = Subscriptions::Event.new(
        name: normalized_event_name,
        arguments: normalized_args,
        field: field,
        scope: scope,
        context: context,
      )
      execute_all(event, object)
    end

    # `event` was triggered on `object`, and `subscription_id` was subscribed,
    # so it should be updated.
    #
    # Load `subscription_id`'s GraphQL data, re-evaluate the query and return the result.
    #
    # @param subscription_id [String]
    # @param event [GraphQL::Subscriptions::Event] The event which was triggered
    # @param object [Object] The value for the subscription field
    # @return [GraphQL::Query::Result]
    def execute_update(subscription_id, event, object)
      # Lookup the saved data for this subscription
      query_data = read_subscription(subscription_id)
      if query_data.nil?
        delete_subscription(subscription_id)
        return nil
      end

      # Fetch the required keys from the saved data
      query_string = query_data.fetch(:query_string)
      variables = query_data.fetch(:variables)
      context = query_data.fetch(:context)
      operation_name = query_data.fetch(:operation_name)
      execute_options = {
        query: query_string,
        context: context,
        subscription_topic: event.topic,
        operation_name: operation_name,
        variables: variables,
        root_value: object,
      }

       # merge event's and query's context together
      context.merge!(event.context) unless event.context.nil? || context.nil?

      execute_options[:validate] = validate_update?(**execute_options)
      result = @schema.execute(**execute_options)
      subscriptions_context = result.context.namespace(:subscriptions)
      if subscriptions_context[:no_update]
        result = nil
      end

      if subscriptions_context[:unsubscribed] && !subscriptions_context[:final_update]
        # `unsubscribe` was called, clean up on our side
        # The transport should also send `{more: false}` to client
        delete_subscription(subscription_id)
        result = nil
      end

      result
    end

    # Define this method to customize whether to validate
    # this subscription when executing an update.
    #
    # @return [Boolean] defaults to `true`, or false if `validate: false` is provided.
    def validate_update?(query:, context:, root_value:, subscription_topic:, operation_name:, variables:)
      @validate_update
    end

    # Run the update query for this subscription and deliver it
    # @see {#execute_update}
    # @see {#deliver}
    # @return [void]
    def execute(subscription_id, event, object)
      res = execute_update(subscription_id, event, object)
      if !res.nil?
        deliver(subscription_id, res)

        if res.context.namespace(:subscriptions)[:unsubscribed]
          # `unsubscribe` was called, clean up on our side
          # The transport should also send `{more: false}` to client
          delete_subscription(subscription_id)
        end
      end

    end

    # Event `event` occurred on `object`,
    # Update all subscribers.
    # @param event [Subscriptions::Event]
    # @param object [Object]
    # @return [void]
    def execute_all(event, object)
      raise GraphQL::RequiredImplementationMissingError
    end

    # The system wants to send an update to this subscription.
    # Read its data and return it.
    # @param subscription_id [String]
    # @return [Hash] Containing required keys
    def read_subscription(subscription_id)
      raise GraphQL::RequiredImplementationMissingError
    end

    # A subscription query was re-evaluated, returning `result`.
    # The result should be send to `subscription_id`.
    # @param subscription_id [String]
    # @param result [Hash]
    # @return [void]
    def deliver(subscription_id, result)
      raise GraphQL::RequiredImplementationMissingError
    end

    # `query` was executed and found subscriptions to `events`.
    # Update the database to reflect this new state.
    # @param query [GraphQL::Query]
    # @param events [Array<GraphQL::Subscriptions::Event>]
    # @return [void]
    def write_subscription(query, events)
      raise GraphQL::RequiredImplementationMissingError
    end

    # A subscription was terminated server-side.
    # Clean up the database.
    # @param subscription_id [String]
    # @return void.
    def delete_subscription(subscription_id)
      raise GraphQL::RequiredImplementationMissingError
    end

    # @return [String] A new unique identifier for a subscription
    def build_id
      SecureRandom.uuid
    end

    # Convert a user-provided event name or argument
    # to the equivalent in GraphQL.
    #
    # By default, it converts the identifier to camelcase.
    # Override this in a subclass to change the transformation.
    #
    # @param event_or_arg_name [String, Symbol]
    # @return [String]
    def normalize_name(event_or_arg_name)
      Schema::Member::BuildType.camelize(event_or_arg_name.to_s)
    end

    # @return [Boolean] if true, then a query like this one would be broadcasted
    def broadcastable?(query_str, **query_options)
      query = @schema.query_class.new(@schema, query_str, **query_options)
      if !query.valid?
        raise "Invalid query: #{query.validation_errors.map(&:to_h).inspect}"
      end
      GraphQL::Analysis.analyze_query(query, @schema.query_analyzers)
      query.context.namespace(:subscriptions)[:subscription_broadcastable]
    end

    private

    # Recursively normalize `args` as belonging to `arg_owner`:
    # - convert symbols to strings,
    # - if needed, camelize the string (using {#normalize_name})
    # @param arg_owner [GraphQL::Field, GraphQL::BaseType]
    # @param args [Hash, Array, Any] some GraphQL input value to coerce as `arg_owner`
    # @return [Any] normalized arguments value
    def normalize_arguments(event_name, arg_owner, args, context)
      case arg_owner
      when GraphQL::Schema::Field, Class
        return args if args.nil?

        if arg_owner.is_a?(Class) && !arg_owner.kind.input_object?
          # it's a type, but not an input object
          return args
        end
        normalized_args = {}
        missing_arg_names = []
        args.each do |k, v|
          arg_name = k.to_s
          arg_defn = arg_owner.get_argument(arg_name, context)
          if arg_defn
            normalized_arg_name = arg_name
          else
            normalized_arg_name = normalize_name(arg_name)
            arg_defn = arg_owner.get_argument(normalized_arg_name, context)
          end

          if arg_defn
            if arg_defn.loads
              normalized_arg_name = arg_defn.keyword.to_s
            end
            normalized = normalize_arguments(event_name, arg_defn.type, v, context)
            normalized_args[normalized_arg_name] = normalized
          else
            # Couldn't find a matching argument definition
            missing_arg_names << arg_name
          end
        end

        # Backfill default values so that trigger arguments
        # match query arguments.
        arg_owner.arguments(context).each do |_name, arg_defn|
          if arg_defn.default_value? && !normalized_args.key?(arg_defn.name)
            default_value = arg_defn.default_value
            # We don't have an underlying "object" here, so it can't call methods.
            # This is broken.
            normalized_args[arg_defn.name] = arg_defn.prepare_value(nil, default_value, context: context)
          end
        end

        if !missing_arg_names.empty?
          arg_owner_name = if arg_owner.is_a?(GraphQL::Schema::Field)
            arg_owner.path
          elsif arg_owner.is_a?(Class)
            arg_owner.graphql_name
          else
            arg_owner.to_s
          end
          raise InvalidTriggerError, "Can't trigger Subscription.#{event_name}, received undefined arguments: #{missing_arg_names.join(", ")}. (Should match arguments of #{arg_owner_name}.)"
        end

        normalized_args
      when GraphQL::Schema::List
        args&.map { |a| normalize_arguments(event_name, arg_owner.of_type, a, context) }
      when GraphQL::Schema::NonNull
        normalize_arguments(event_name, arg_owner.of_type, args, context)
      else
        args
      end
    end
  end
end
