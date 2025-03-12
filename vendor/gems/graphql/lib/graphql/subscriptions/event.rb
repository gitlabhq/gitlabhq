# frozen_string_literal: true
module GraphQL
  class Subscriptions
    # This thing can be:
    # - Subscribed to by `subscription { ... }`
    # - Triggered by `MySchema.subscriber.trigger(name, arguments, obj)`
    #
    class Event
      # @return [String] Corresponds to the Subscription root field name
      attr_reader :name

      # @return [GraphQL::Execution::Interpreter::Arguments]
      attr_reader :arguments

      # @return [GraphQL::Query::Context]
      attr_reader :context

      # @return [String] An opaque string which identifies this event, derived from `name` and `arguments`
      attr_reader :topic

      def initialize(name:, arguments:, field: nil, context: nil, scope: nil)
        @name = name
        @arguments = self.class.arguments_without_field_extras(arguments: arguments, field: field)
        @context = context
        field ||= context.field
        scope_key = field.subscription_scope
        scope_val = scope || (context && scope_key && context[scope_key])
        if scope_key &&
            (subscription = field.resolver) &&
            (subscription.respond_to?(:subscription_scope_optional?)) &&
            !subscription.subscription_scope_optional? &&
            scope_val.nil?
          raise Subscriptions::SubscriptionScopeMissingError, "#{field.path} (#{subscription}) requires a `scope:` value to trigger updates (Set `subscription_scope ..., optional: true` to disable this requirement)"
        end

        @topic = self.class.serialize(name, arguments, field, scope: scope_val, context: context)
      end

      # @return [String] an identifier for this unit of subscription
      def self.serialize(_name, arguments, field, scope:, context: GraphQL::Query::NullContext.instance)
        subscription = field.resolver || GraphQL::Schema::Subscription
        arguments = arguments_without_field_extras(field: field, arguments: arguments)
        normalized_args = stringify_args(field, arguments.to_h, context)
        subscription.topic_for(arguments: normalized_args, field: field, scope: scope)
      end

      # @return [String] a logical identifier for this event. (Stable when the query is broadcastable.)
      def fingerprint
        @fingerprint ||= begin
          # When this query has been flagged as broadcastable,
          # use a generalized, stable fingerprint so that
          # duplicate subscriptions can be evaluated and distributed in bulk.
          # (`@topic` includes field, args, and subscription scope already.)
          if @context.namespace(:subscriptions)[:subscription_broadcastable]
            "#{@topic}/#{@context.query.fingerprint}"
          else
            # not broadcastable, build a unique ID for this event
            @context.schema.subscriptions.build_id
          end
        end
      end

      class << self
        def arguments_without_field_extras(arguments:, field:)
          if !field.extras.empty?
            arguments = arguments.dup
            field.extras.each do |extra_key|
              arguments.delete(extra_key)
            end
          end
          arguments
        end

        private

        # This method does not support cyclic references in the Hash,
        # nor does it support Hashes whose keys are not sortable
        # with respect to their peers ( cases where a <=> b might throw an error )
        def deep_sort_hash_keys(hash_to_sort)
          raise ArgumentError.new("Argument must be a Hash") unless hash_to_sort.is_a?(Hash)
          hash_to_sort.keys.sort.map do |k|
            if hash_to_sort[k].is_a?(Hash)
              [k, deep_sort_hash_keys(hash_to_sort[k])]
            elsif hash_to_sort[k].is_a?(Array)
              [k, deep_sort_array_hashes(hash_to_sort[k])]
            else
              [k, hash_to_sort[k]]
            end
          end.to_h
        end

        def deep_sort_array_hashes(array_to_inspect)
          raise ArgumentError.new("Argument must be an Array") unless array_to_inspect.is_a?(Array)
          array_to_inspect.map do |v|
            if v.is_a?(Hash)
              deep_sort_hash_keys(v)
            elsif v.is_a?(Array)
              deep_sort_array_hashes(v)
            else
              v
            end
          end
        end

        def stringify_args(arg_owner, args, context)
          arg_owner = arg_owner.respond_to?(:unwrap) ? arg_owner.unwrap : arg_owner # remove list and non-null wrappers
          case args
          when Hash
            next_args = {}
            args.each do |k, v|
              arg_name = k.to_s
              camelized_arg_name = GraphQL::Schema::Member::BuildType.camelize(arg_name)
              arg_defn = get_arg_definition(arg_owner, camelized_arg_name, context)
              arg_defn ||= get_arg_definition(arg_owner, arg_name, context)
              normalized_arg_name = arg_defn.graphql_name
              arg_base_type = arg_defn.type.unwrap
              # In the case where the value being emitted is seen as a "JSON"
              # type, treat the value as one atomic unit of serialization
              is_json_definition = arg_base_type && arg_base_type <= GraphQL::Types::JSON
              if is_json_definition
                sorted_value = if v.is_a?(Hash)
                  deep_sort_hash_keys(v)
                elsif v.is_a?(Array)
                  deep_sort_array_hashes(v)
                else
                  v
                end
                next_args[normalized_arg_name] = sorted_value.respond_to?(:to_json) ? sorted_value.to_json : sorted_value
              else
                next_args[normalized_arg_name] = stringify_args(arg_base_type, v, context)
              end
            end
            # Make sure they're deeply sorted
            next_args.sort.to_h
          when Array
            args.map { |a| stringify_args(arg_owner, a, context) }
          when GraphQL::Schema::InputObject
            stringify_args(arg_owner, args.to_h, context)
          else
            if arg_owner.is_a?(Class) && arg_owner < GraphQL::Schema::Enum
              # `prepare:` may have made the value something other than
              # a defined value of this enum -- use _that_ in this case.
              arg_owner.coerce_isolated_input(args) || args
            else
              args
            end
          end
        end

        def get_arg_definition(arg_owner, arg_name, context)
          context.types.argument(arg_owner, arg_name) || context.types.arguments(arg_owner).find { |v| v.keyword.to_s == arg_name }
        end
      end
    end
  end
end
