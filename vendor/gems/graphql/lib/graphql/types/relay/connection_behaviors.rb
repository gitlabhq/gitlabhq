# frozen_string_literal: true

module GraphQL
  module Types
    module Relay
      module ConnectionBehaviors
        extend Forwardable
        def_delegators :@object, :cursor_from_node, :parent

        def self.included(child_class)
          child_class.extend(ClassMethods)
          child_class.has_nodes_field(true)
          child_class.node_nullable(true)
          child_class.edges_nullable(true)
          child_class.edge_nullable(true)
          child_class.module_exec {
            self.edge_type = nil
            self.node_type = nil
            self.edge_class = nil
          }
          child_class.default_broadcastable(nil)
          add_page_info_field(child_class)
        end

        module ClassMethods
          def inherited(child_class)
            super
            child_class.has_nodes_field(has_nodes_field)
            child_class.node_nullable(node_nullable)
            child_class.edges_nullable(edges_nullable)
            child_class.edge_nullable(edge_nullable)
            child_class.edge_type = nil
            child_class.node_type = nil
            child_class.edge_class = nil
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

          # @return [Class]
          attr_reader :node_type

          # @return [Class]
          attr_reader :edge_class

          # Configure this connection to return `edges` and `nodes` based on `edge_type_class`.
          #
          # This method will use the inputs to create:
          # - `edges` field
          # - `nodes` field
          # - description
          #
          # It's called when you subclass this base connection, trying to use the
          # class name to set defaults. You can call it again in the class definition
          # to override the default (or provide a value, if the default lookup failed).
          # @param field_options [Hash] Any extra keyword arguments to pass to the `field :edges, ...` and `field :nodes, ...` configurations
          def edge_type(edge_type_class, edge_class: GraphQL::Pagination::Connection::Edge, node_type: edge_type_class.node_type, nodes_field: self.has_nodes_field, node_nullable: self.node_nullable, edges_nullable: self.edges_nullable, edge_nullable: self.edge_nullable, field_options: nil)
            # Set this connection's graphql name
            node_type_name = node_type.graphql_name

            @node_type = node_type
            @edge_type = edge_type_class
            @edge_class = edge_class

            base_field_options = {
              name: :edges,
              type: [edge_type_class, null: edge_nullable],
              null: edges_nullable,
              description: "A list of edges.",
              scope: false, # Assume that the connection was already scoped.
              connection: false,
            }

            if field_options
              base_field_options.merge!(field_options)
            end

            field(**base_field_options)

            define_nodes_field(node_nullable, field_options: field_options) if nodes_field

            description("The connection type for #{node_type_name}.")
          end

          # Filter this list according to the way its node type would scope them
          def scope_items(items, context)
            node_type.scope_items(items, context)
          end

          # The connection will skip auth on its nodes if the node_type is configured for that
          def reauthorize_scoped_objects(new_value = nil)
            if new_value.nil?
              if @reauthorize_scoped_objects != nil
                @reauthorize_scoped_objects
              else
                node_type.reauthorize_scoped_objects
              end
            else
              @reauthorize_scoped_objects = new_value
            end
          end

          # Add the shortcut `nodes` field to this connection and its subclasses
          def nodes_field(node_nullable: self.node_nullable, field_options: nil)
            define_nodes_field(node_nullable, field_options: field_options)
          end

          def authorized?(obj, ctx)
            true # Let nodes be filtered out
          end

          def visible?(ctx)
            # if this is an abstract base class, there may be no `node_type`
            node_type ? node_type.visible?(ctx) : super
          end

          # Set the default `node_nullable` for this class and its child classes. (Defaults to `true`.)
          # Use `node_nullable(false)` in your base class to make non-null `node` and `nodes` fields.
          def node_nullable(new_value = nil)
            if new_value.nil?
              defined?(@node_nullable) ? @node_nullable : superclass.node_nullable
            else
              @node_nullable = new_value
            end
          end

          # Set the default `edges_nullable` for this class and its child classes. (Defaults to `true`.)
          # Use `edges_nullable(false)` in your base class to make non-null `edges` fields.
          def edges_nullable(new_value = nil)
            if new_value.nil?
              defined?(@edges_nullable) ? @edges_nullable : superclass.edges_nullable
            else
              @edges_nullable = new_value
            end
          end

          # Set the default `edge_nullable` for this class and its child classes. (Defaults to `true`.)
          # Use `edge_nullable(false)` in your base class to make non-null `edge` fields.
          def edge_nullable(new_value = nil)
            if new_value.nil?
              defined?(@edge_nullable) ? @edge_nullable : superclass.edge_nullable
            else
              @edge_nullable = new_value
            end
          end

          # Set the default `nodes_field` for this class and its child classes. (Defaults to `true`.)
          # Use `nodes_field(false)` in your base class to prevent adding of a nodes field.
          def has_nodes_field(new_value = nil)
            if new_value.nil?
              defined?(@nodes_field) ? @nodes_field : superclass.has_nodes_field
            else
              @nodes_field = new_value
            end
          end

          protected

          attr_writer :edge_type, :node_type,  :edge_class

          private

          def define_nodes_field(nullable, field_options: nil)
            base_field_options = {
              name: :nodes,
              type: [@node_type, null: nullable],
              null: nullable,
              description: "A list of nodes.",
              connection: false,
              # Assume that the connection was scoped before this step:
              scope: false,
            }
            if field_options
              base_field_options.merge!(field_options)
            end
            field(**base_field_options)
          end
        end

        class << self
          def add_page_info_field(obj_type)
            obj_type.field :page_info, GraphQL::Types::Relay::PageInfo, null: false, description: "Information to aid in pagination."
          end
        end

        def edges
          # Assume that whatever authorization needed to happen
          # already happened at the connection level.
          current_runtime_state = Fiber[:__graphql_runtime_info]
          query_runtime_state = current_runtime_state[context.query]
          query_runtime_state.was_authorized_by_scope_items = @object.was_authorized_by_scope_items?
          @object.edges
        end

        def nodes
          # Assume that whatever authorization needed to happen
          # already happened at the connection level.
          current_runtime_state = Fiber[:__graphql_runtime_info]
          query_runtime_state = current_runtime_state[context.query]
          query_runtime_state.was_authorized_by_scope_items = @object.was_authorized_by_scope_items?
          @object.nodes
        end
      end
    end
  end
end
