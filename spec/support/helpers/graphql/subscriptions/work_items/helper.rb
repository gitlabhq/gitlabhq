# frozen_string_literal: true

module Graphql
  module Subscriptions
    module WorkItems
      module Helper
        def subscription_response
          subscription_channel = subscribe
          yield
          subscription_channel.mock_broadcasted_messages.first
        end

        def work_item_subscription(name, work_item, current_user, access_token: nil)
          mock_channel = Graphql::Subscriptions::ActionCable::MockActionCable.get_mock_channel

          query = case name
                  when 'workItemUpdated'
                    work_item_updated_subscription_query(name, work_item)
                  else
                    raise "Subscription query unknown: #{name}"
                  end

          context = { current_user: current_user, channel: mock_channel }
          context[:access_token] = access_token if access_token

          GitlabSchema.execute(query, context: context)

          mock_channel
        end

        def note_subscription(name, work_item, current_user)
          mock_channel = Graphql::Subscriptions::ActionCable::MockActionCable.get_mock_channel

          query = <<~SUBSCRIPTION
            subscription {
              #{name}(workItemId: \"#{work_item.to_gid}\") {
                id
                iid
              }
            }
          SUBSCRIPTION

          GitlabSchema.execute(query, context: { current_user: current_user, channel: mock_channel })

          mock_channel
        end

        private

        def work_item_updated_subscription_query(name, work_item)
          <<~SUBSCRIPTION
            subscription {
              #{name}(workItemId: \"#{work_item.to_gid}\") {
                id
                iid
              }
            }
          SUBSCRIPTION
        end
      end
    end
  end
end
