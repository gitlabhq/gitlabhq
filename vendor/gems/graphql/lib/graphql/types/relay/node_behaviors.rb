# frozen_string_literal: true

module GraphQL
  module Types
    module Relay
      module NodeBehaviors
        def self.included(child_module)
          child_module.extend(ClassMethods)
          child_module.description("An object with an ID.")
          child_module.field(:id, ID, null: false, description: "ID of the object.", resolver_method: :default_global_id)
        end

        def default_global_id
          context.schema.id_from_object(object, self.class, context)
        end

        module ClassMethods
          def default_relay?
            true
          end
        end
      end
    end
  end
end
