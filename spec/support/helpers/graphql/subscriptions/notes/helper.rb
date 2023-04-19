# frozen_string_literal: true

module Graphql
  module Subscriptions
    module Notes
      module Helper
        def subscription_response
          subscription_channel = subscribe
          yield
          subscription_channel.mock_broadcasted_messages.first
        end

        def notes_subscription(name, noteable, current_user)
          mock_channel = Graphql::Subscriptions::ActionCable::MockActionCable.get_mock_channel

          query = case name
                  when 'workItemNoteDeleted'
                    note_deleted_subscription_query(name, noteable)
                  when 'workItemNoteUpdated'
                    note_updated_subscription_query(name, noteable)
                  when 'workItemNoteCreated'
                    note_created_subscription_query(name, noteable)
                  else
                    raise "Subscription query unknown: #{name}"
                  end

          GitlabSchema.execute(query, context: { current_user: current_user, channel: mock_channel })

          mock_channel
        end

        def note_subscription(name, noteable, current_user)
          mock_channel = Graphql::Subscriptions::ActionCable::MockActionCable.get_mock_channel

          query = <<~SUBSCRIPTION
            subscription {
              #{name}(noteableId: \"#{noteable.to_gid}\") {
                id
                body
              }
            }
          SUBSCRIPTION

          GitlabSchema.execute(query, context: { current_user: current_user, channel: mock_channel })

          mock_channel
        end

        private

        def note_deleted_subscription_query(name, noteable)
          <<~SUBSCRIPTION
                      subscription {
                        #{name}(noteableId: \"#{noteable.to_gid}\") {
                          id
                          discussionId
                          lastDiscussionNote
                        }
                      }
          SUBSCRIPTION
        end

        def note_created_subscription_query(name, noteable)
          <<~SUBSCRIPTION
            subscription {
              #{name}(noteableId: \"#{noteable.to_gid}\") {
                id
                discussion {
                  id
                  notes {
                    nodes {
                      id
                    }
                  }
                }
              }
            }
          SUBSCRIPTION
        end

        def note_updated_subscription_query(name, noteable)
          <<~SUBSCRIPTION
            subscription {
              #{name}(noteableId: \"#{noteable.to_gid}\") {
                id
                body
              }
            }
          SUBSCRIPTION
        end
      end
    end
  end
end
