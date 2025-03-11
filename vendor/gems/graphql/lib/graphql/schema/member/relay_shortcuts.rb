# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      module RelayShortcuts
        def edge_type_class(new_edge_type_class = nil)
          if new_edge_type_class
            initialize_relay_metadata
            @edge_type_class = new_edge_type_class
          else
            # Don't call `ancestor.edge_type_class`
            # because we don't want a fallback from any ancestors --
            # only apply the fallback if _no_ ancestor has a configured value!
            for ancestor in self.ancestors
              if ancestor.respond_to?(:configured_edge_type_class, true) && (etc = ancestor.configured_edge_type_class)
                return etc
              end
            end
            Types::Relay::BaseEdge
          end
        end

        def connection_type_class(new_connection_type_class = nil)
          if new_connection_type_class
            initialize_relay_metadata
            @connection_type_class = new_connection_type_class
          else
            # Don't call `ancestor.connection_type_class`
            # because we don't want a fallback from any ancestors --
            # only apply the fallback if _no_ ancestor has a configured value!
            for ancestor in self.ancestors
              if ancestor.respond_to?(:configured_connection_type_class, true) && (ctc = ancestor.configured_connection_type_class)
                return ctc
              end
            end
            Types::Relay::BaseConnection
          end
        end

        def edge_type
          initialize_relay_metadata
          @edge_type ||= begin
            edge_name = self.graphql_name + "Edge"
            node_type_class = self
            Class.new(edge_type_class) do
              graphql_name(edge_name)
              node_type(node_type_class)
            end
          end
        end

        def connection_type
          initialize_relay_metadata
          @connection_type ||= begin
            conn_name = self.graphql_name + "Connection"
            edge_type_class = self.edge_type
            Class.new(connection_type_class) do
              graphql_name(conn_name)
              edge_type(edge_type_class)
            end
          end
        end

        protected

        def configured_connection_type_class
          @connection_type_class
        end

        def configured_edge_type_class
          @edge_type_class
        end

        attr_writer :edge_type, :connection_type, :connection_type_class, :edge_type_class

        private

        # If one of these values is accessed, initialize all the instance variables to retain
        # a consistent object shape.
        def initialize_relay_metadata
          if !defined?(@connection_type)
            @connection_type = nil
            @edge_type = nil
            @connection_type_class = nil
            @edge_type_class = nil
          end
        end
      end
    end
  end
end
