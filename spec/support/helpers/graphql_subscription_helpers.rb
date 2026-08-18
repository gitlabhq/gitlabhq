# frozen_string_literal: true

module Spec
  module Support
    module Helpers
      module GraphqlSubscriptionHelpers
        # Runs the given block (e.g. a `visit` or a click) and blocks until the page
        # has registered a *new* GraphQL subscription on the server.
        #
        # GraphQL subscriptions are delivered over ActionCable: a broadcast only
        # reaches subscribers that are already registered when it fires. In a :js
        # spec the Puma app server shares this process, so we can watch
        # GitlabSchema's in-process subscription registry to know, deterministically,
        # that the browser has finished subscribing before triggering an update.
        #
        # The registry is a process-wide singleton, so we compare against a snapshot
        # taken before the block runs; that way a subscription left over from a
        # previous example cannot satisfy the wait.
        #
        # @param subscription_name [String, nil] optional GraphQL operation name to
        #   wait for specifically, for pages that register more than one subscription
        def wait_for_new_graphql_subscription(subscription_name = nil)
          existing_ids = graphql_subscription_ids

          yield

          wait_for('a new GraphQL subscription to be registered') do
            new_ids = graphql_subscription_ids - existing_ids
            next new_ids.any? if subscription_name.nil?

            subscriptions = graphql_subscriptions
            new_ids.any? { |id| subscriptions[id]&.operation_name == subscription_name }
          end
        end

        private

        def graphql_subscriptions
          GitlabSchema.subscriptions.instance_variable_get(:@subscriptions)
        end

        def graphql_subscription_ids
          graphql_subscriptions.keys
        end
      end
    end
  end
end
