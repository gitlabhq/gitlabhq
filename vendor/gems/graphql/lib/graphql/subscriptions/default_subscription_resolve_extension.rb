# frozen_string_literal: true
module GraphQL
  class Subscriptions
    class DefaultSubscriptionResolveExtension < GraphQL::Schema::FieldExtension
      def resolve(context:, object:, arguments:)
        has_override_implementation = @field.resolver ||
          object.respond_to?(@field.resolver_method)

        if !has_override_implementation
          if context.query.subscription_update?
            object.object
          else
            context.skip
          end
        else
          yield(object, arguments)
        end
      end

      def after_resolve(value:, context:, object:, arguments:, **rest)
        if value.is_a?(GraphQL::ExecutionError)
          value
        elsif @field.resolver&.method_defined?(:subscription_written?) &&
          (subscription_namespace = context.namespace(:subscriptions)) &&
          (subscriptions_by_path = subscription_namespace[:subscriptions])
          (subscription_instance = subscriptions_by_path[context.current_path])
          # If it was already written, don't append this event to be written later
          if !subscription_instance.subscription_written?
            events = context.namespace(:subscriptions)[:events]
            events << subscription_instance.event
          end
          value
        elsif (events = context.namespace(:subscriptions)[:events])
          # This is the first execution, so gather an Event
          # for the backend to register:
          event = Subscriptions::Event.new(
            name: field.name,
            arguments: arguments,
            context: context,
            field: field,
          )
          events << event
          value
        elsif context.query.subscription_topic == Subscriptions::Event.serialize(
            field.name,
            arguments,
            field,
            scope: (field.subscription_scope ? context[field.subscription_scope] : nil),
          )
          # This is a subscription update. The resolver returned `skip` if it should be skipped,
          # or else it returned an object to resolve the update.
          value
        else
          # This is a subscription update, but this event wasn't triggered.
          context.skip
        end
      end
    end
  end
end
