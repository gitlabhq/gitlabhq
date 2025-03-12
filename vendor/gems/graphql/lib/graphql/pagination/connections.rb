# frozen_string_literal: true

module GraphQL
  module Pagination
    # A schema-level connection wrapper manager.
    #
    # Attach as a plugin.
    #
    # @example Adding a custom wrapper
    #   class MySchema < GraphQL::Schema
    #     connections.add(MyApp::SearchResults, MyApp::SearchResultsConnection)
    #   end
    #
    # @example Removing default connection support for arrays (they can still be manually wrapped)
    #   class MySchema < GraphQL::Schema
    #     connections.delete(Array)
    #   end
    #
    # @see {Schema.connections}
    class Connections
      class ImplementationMissingError < GraphQL::Error
      end

      def initialize(schema:)
        @schema = schema
        @wrappers = {}
        add_default
      end

      def add(nodes_class, implementation)
        @wrappers[nodes_class] = implementation
      end

      def delete(nodes_class)
        @wrappers.delete(nodes_class)
      end

      def all_wrappers
        all_wrappers = {}
        @schema.ancestors.reverse_each do |schema_class|
          if schema_class.respond_to?(:connections) && (c = schema_class.connections)
            all_wrappers.merge!(c.wrappers)
          end
        end
        all_wrappers
      end

      def wrapper_for(items, wrappers: all_wrappers)
        impl = nil

        items.class.ancestors.each { |cls|
          impl = wrappers[cls]
          break if impl
        }

        impl
      end

      # Used by the runtime to wrap values in connection wrappers.
      # @api Private
      def wrap(field, parent, items, arguments, context)
        return items if GraphQL::Execution::Interpreter::RawValue === items
        wrappers = context ? context.namespace(:connections)[:all_wrappers] : all_wrappers
        impl = wrapper_for(items, wrappers: wrappers)

        if impl
          impl.new(
            items,
            context: context,
            parent: parent,
            field: field,
            max_page_size: field.has_max_page_size? ? field.max_page_size : context.schema.default_max_page_size,
            default_page_size: field.has_default_page_size? ? field.default_page_size : context.schema.default_page_size,
            first: arguments[:first],
            after: arguments[:after],
            last: arguments[:last],
            before: arguments[:before],
            arguments: arguments,
            edge_class: edge_class_for_field(field),
          )
        else
          raise ImplementationMissingError, "Couldn't find a connection wrapper for #{items.class} during #{field.path} (#{items.inspect})"
        end
      end

      # use an override if there is one
      # @api private
      def edge_class_for_field(field)
        conn_type = field.type.unwrap
        conn_type_edge_type = conn_type.respond_to?(:edge_class) && conn_type.edge_class
        if conn_type_edge_type && conn_type_edge_type != Pagination::Connection::Edge
          conn_type_edge_type
        else
          nil
        end
      end
      protected

      attr_reader :wrappers

      private

      def add_default
        add(Array, Pagination::ArrayConnection)

        if defined?(ActiveRecord::Relation)
          add(ActiveRecord::Relation, Pagination::ActiveRecordRelationConnection)
        end

        if defined?(Sequel::Dataset)
          add(Sequel::Dataset, Pagination::SequelDatasetConnection)
        end

        if defined?(Mongoid::Criteria)
          add(Mongoid::Criteria, Pagination::MongoidRelationConnection)
        end

        # Mongoid 5 and 6
        if defined?(Mongoid::Relations::Targets::Enumerable)
          add(Mongoid::Relations::Targets::Enumerable, Pagination::MongoidRelationConnection)
        end

        # Mongoid 7
        if defined?(Mongoid::Association::Referenced::HasMany::Targets::Enumerable)
          add(Mongoid::Association::Referenced::HasMany::Targets::Enumerable, Pagination::MongoidRelationConnection)
        end

        # Mongoid 7.3+
        if defined?(Mongoid::Association::Referenced::HasMany::Enumerable)
          add(Mongoid::Association::Referenced::HasMany::Enumerable, Pagination::MongoidRelationConnection)
        end
      end
    end
  end
end
