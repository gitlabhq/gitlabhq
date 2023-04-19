# frozen_string_literal: true

# A stub implementation of ActionCable.
# Any methods to support the mock backend have `mock` in the name.
module Graphql
  module Subscriptions
    module ActionCable
      class MockGitlabSchema < GraphQL::Schema
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
