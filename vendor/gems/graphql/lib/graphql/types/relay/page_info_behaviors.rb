# frozen_string_literal: true
module GraphQL
  module Types
    module Relay
      module PageInfoBehaviors
        def self.included(child_class)
          child_class.extend ClassMethods
          child_class.description "Information about pagination in a connection."
          child_class.field :has_next_page, Boolean, null: false,
            description: "When paginating forwards, are there more items?"

          child_class.field :has_previous_page, Boolean, null: false,
            description: "When paginating backwards, are there more items?"

          child_class.field :start_cursor, String, null: true,
            description: "When paginating backwards, the cursor to continue."

          child_class.field :end_cursor, String, null: true,
            description: "When paginating forwards, the cursor to continue."
        end
      end

      module ClassMethods
        def default_relay?
          true
        end

        def default_broadcastable?
          true
        end
      end
    end
  end
end
