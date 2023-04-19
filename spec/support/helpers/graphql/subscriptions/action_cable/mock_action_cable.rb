# frozen_string_literal: true

# A stub implementation of ActionCable.
# Any methods to support the mock backend have `mock` in the name.
module Graphql
  module Subscriptions
    module ActionCable
      class MockActionCable
        class MockChannel
          def initialize
            @mock_broadcasted_messages = []
          end

          attr_reader :mock_broadcasted_messages

          def stream_from(stream_name, coder: nil, &block) # rubocop:disable Lint/UnusedMethodArgument
            # Rails uses `coder`, we don't
            block ||= ->(msg) { @mock_broadcasted_messages << msg }
            MockActionCable.mock_stream_for(stream_name).add_mock_channel(self, block)
          end
        end

        class MockStream
          def initialize
            @mock_channels = {}
          end

          def add_mock_channel(channel, handler)
            @mock_channels[channel] = handler
          end

          def mock_broadcast(message)
            @mock_channels.each_value do |handler|
              handler && handler.call(message)
            end
          end
        end

        class << self
          def clear_mocks
            @mock_streams = {}
          end

          def server
            self
          end

          def broadcast(stream_name, message)
            stream = @mock_streams[stream_name]
            stream && stream.mock_broadcast(message)
          end

          def mock_stream_for(stream_name)
            @mock_streams[stream_name] ||= MockStream.new
          end

          def get_mock_channel
            MockChannel.new
          end

          def mock_stream_names
            @mock_streams.keys
          end
        end
      end

      class MockSchema < GraphQL::Schema
        class << self
          def find_by_gid(gid)
            return unless gid

            if gid.model_class < ApplicationRecord
              Gitlab::Graphql::Loaders::BatchModelLoader.new(gid.model_class, gid.model_id).find
            elsif gid.model_class.respond_to?(:lazy_find)
              gid.model_class.lazy_find(gid.model_id)
            else
              gid.find
            end
          end

          def id_from_object(object, _type = nil, _ctx = nil)
            unless object.respond_to?(:to_global_id)
              # This is an error in our schema and needs to be solved. So raise a
              # more meaningful error message
              raise "#{object} does not implement `to_global_id`. " \
                    "Include `GlobalID::Identification` into `#{object.class}"
            end

            object.to_global_id
          end
        end

        query(::Types::QueryType)
        subscription(::Types::SubscriptionType)

        use GraphQL::Subscriptions::ActionCableSubscriptions, action_cable: MockActionCable, action_cable_coder: JSON
      end
    end
  end
end
