# frozen_string_literal: true

module GraphQL
  module Types
    module Relay
      module EdgeBehaviors
        def self.included(child_class)
          child_class.description("An edge in a connection.")
          child_class.field(:cursor, String, null: false, description: "A cursor for use in pagination.")
          child_class.extend(ClassMethods)
          child_class.class_exec { self.node_type = nil }
          child_class.node_nullable(true)
          child_class.default_broadcastable(nil)
        end

        def node
          current_runtime_state = Fiber[:__graphql_runtime_info]
          query_runtime_state = current_runtime_state[context.query]
          query_runtime_state.was_authorized_by_scope_items = @object.was_authorized_by_scope_items?
          @object.node
        end

        module ClassMethods
          def inherited(child_class)
            super
            child_class.node_type = nil
            child_class.node_nullable = nil
            child_class.default_broadcastable(default_broadcastable?)
          end

          def default_relay?
            true
          end

          def default_broadcastable?
            @default_broadcastable
          end

          def default_broadcastable(new_value)
            @default_broadcastable = new_value
          end

          # Get or set the Object type that this edge wraps.
          #
          # @param node_type [Class] A `Schema::Object` subclass
          # @param null [Boolean]
          # @param field_options [Hash] Any extra arguments to pass to the `field :node` configuration
          def node_type(node_type = nil, null: self.node_nullable, field_options: nil)
            if node_type
              @node_type = node_type
              # Add a default `node` field
              base_field_options = {
                name: :node,
                type: node_type,
                null: null,
                description: "The item at the end of the edge.",
                connection: false,
              }
              if field_options
                base_field_options.merge!(field_options)
              end
              field(**base_field_options)
            end
            @node_type
          end

          def authorized?(obj, ctx)
            true
          end

          def visible?(ctx)
            node_type.visible?(ctx)
          end

          # Set the default `node_nullable` for this class and its child classes. (Defaults to `true`.)
          # Use `node_nullable(false)` in your base class to make non-null `node` field.
          def node_nullable(new_value = nil)
            if new_value.nil?
              @node_nullable != nil ? @node_nullable : superclass.node_nullable
            else
              @node_nullable = new_value
            end
          end

          protected

          attr_writer :node_type, :node_nullable
        end
      end
    end
  end
end
