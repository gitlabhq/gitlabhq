# frozen_string_literal: true

module GraphQL
  module Pagination
    # A Connection wraps a list of items and provides cursor-based pagination over it.
    #
    # Connections were introduced by Facebook's `Relay` front-end framework, but
    # proved to be generally useful for GraphQL APIs. When in doubt, use connections
    # to serve lists (like Arrays, ActiveRecord::Relations) via GraphQL.
    #
    # Unlike the previous connection implementation, these default to bidirectional pagination.
    #
    # Pagination arguments and context may be provided at initialization or assigned later (see {Schema::Field::ConnectionExtension}).
    class Connection
      class PaginationImplementationMissingError < GraphQL::Error
      end

      # @return [Object] A list object, from the application. This is the unpaginated value passed into the connection.
      attr_reader :items

      # @return [GraphQL::Query::Context]
      attr_reader :context

      def context=(new_ctx)
        @context = new_ctx
        if @was_authorized_by_scope_items.nil?
          @was_authorized_by_scope_items = detect_was_authorized_by_scope_items
        end
        @context
      end

      # @return [Object] the object this collection belongs to
      attr_accessor :parent

      # Raw access to client-provided values. (`max_page_size` not applied to first or last.)
      attr_accessor :before_value, :after_value, :first_value, :last_value

      # @return [String, nil] the client-provided cursor. `""` is treated as `nil`.
      def before
        if defined?(@before)
          @before
        else
          @before = @before_value == "" ? nil : @before_value
        end
      end

      # @return [String, nil] the client-provided cursor. `""` is treated as `nil`.
      def after
        if defined?(@after)
          @after
        else
          @after = @after_value == "" ? nil : @after_value
        end
      end

      # @return [Hash<Symbol => Object>] The field arguments from the field that returned this connection
      attr_accessor :arguments

      # @param items [Object] some unpaginated collection item, like an `Array` or `ActiveRecord::Relation`
      # @param context [Query::Context]
      # @param parent [Object] The object this collection belongs to
      # @param first [Integer, nil] The limit parameter from the client, if it provided one
      # @param after [String, nil] A cursor for pagination, if the client provided one
      # @param last [Integer, nil] Limit parameter from the client, if provided
      # @param before [String, nil] A cursor for pagination, if the client provided one.
      # @param arguments [Hash] The arguments to the field that returned the collection wrapped by this connection
      # @param max_page_size [Integer, nil] A configured value to cap the result size. Applied as `first` if neither first or last are given and no `default_page_size` is set.
      # @param default_page_size [Integer, nil] A configured value to determine the result size when neither first or last are given.
      def initialize(items, parent: nil, field: nil, context: nil, first: nil, after: nil, max_page_size: NOT_CONFIGURED, default_page_size: NOT_CONFIGURED, last: nil, before: nil, edge_class: nil, arguments: nil)
        @items = items
        @parent = parent
        @context = context
        @field = field
        @first_value = first
        @after_value = after
        @last_value = last
        @before_value = before
        @arguments = arguments
        @edge_class = edge_class || self.class::Edge
        # This is only true if the object was _initialized_ with an override
        # or if one is assigned later.
        @has_max_page_size_override = max_page_size != NOT_CONFIGURED
        @max_page_size = if max_page_size == NOT_CONFIGURED
          nil
        else
          max_page_size
        end
        @has_default_page_size_override = default_page_size != NOT_CONFIGURED
        @default_page_size = if default_page_size == NOT_CONFIGURED
          nil
        else
          default_page_size
        end
        @was_authorized_by_scope_items = detect_was_authorized_by_scope_items
      end

      def was_authorized_by_scope_items?
        @was_authorized_by_scope_items
      end

      def max_page_size=(new_value)
        @has_max_page_size_override = true
        @max_page_size = new_value
      end

      def max_page_size
        if @has_max_page_size_override
          @max_page_size
        else
          context.schema.default_max_page_size
        end
      end

      def has_max_page_size_override?
        @has_max_page_size_override
      end

      def default_page_size=(new_value)
        @has_default_page_size_override = true
        @default_page_size = new_value
      end

      def default_page_size
        if @has_default_page_size_override
          @default_page_size
        else
          context.schema.default_page_size
        end
      end

      def has_default_page_size_override?
        @has_default_page_size_override
      end

      attr_writer :first
      # @return [Integer, nil]
      #   A clamped `first` value.
      #   (The underlying instance variable doesn't have limits on it.)
      #   If neither `first` nor `last` is given, but `default_page_size` is
      #   present, default_page_size is used for first. If `default_page_size`
      #   is greater than `max_page_size``, it'll be clamped down to
      #   `max_page_size`. If `default_page_size` is nil, use `max_page_size`.
      def first
        @first ||= begin
          capped = limit_pagination_argument(@first_value, max_page_size)
          if capped.nil? && last.nil?
            capped = limit_pagination_argument(default_page_size, max_page_size) || max_page_size
          end
          capped
        end
      end

      # This is called by `Relay::RangeAdd` -- it can be overridden
      # when `item` needs some modifications based on this connection's state.
      #
      # @param item [Object] An item newly added to `items`
      # @return [Edge]
      def range_add_edge(item)
        edge_class.new(item, self)
      end

      attr_writer :last
      # @return [Integer, nil] A clamped `last` value. (The underlying instance variable doesn't have limits on it)
      def last
        @last ||= limit_pagination_argument(@last_value, max_page_size)
      end

      # @return [Array<Edge>] {nodes}, but wrapped with Edge instances
      def edges
        @edges ||= nodes.map { |n| @edge_class.new(n, self) }
      end

      # @return [Class] A wrapper class for edges of this connection
      attr_accessor :edge_class

      # @return [GraphQL::Schema::Field] The field this connection was returned by
      attr_accessor :field

      # @return [Array<Object>] A slice of {items}, constrained by {@first_value}/{@after_value}/{@last_value}/{@before_value}
      def nodes
        raise PaginationImplementationMissingError, "Implement #{self.class}#nodes to paginate `@items`"
      end

      # A dynamic alias for compatibility with {Relay::BaseConnection}.
      # @deprecated use {#nodes} instead
      def edge_nodes
        nodes
      end

      # The connection object itself implements `PageInfo` fields
      def page_info
        self
      end

      # @return [Boolean] True if there are more items after this page
      def has_next_page
        raise PaginationImplementationMissingError, "Implement #{self.class}#has_next_page to return the next-page check"
      end

      # @return [Boolean] True if there were items before these items
      def has_previous_page
        raise PaginationImplementationMissingError, "Implement #{self.class}#has_previous_page to return the previous-page check"
      end

      # @return [String] The cursor of the first item in {nodes}
      def start_cursor
        nodes.first && cursor_for(nodes.first)
      end

      # @return [String] The cursor of the last item in {nodes}
      def end_cursor
        nodes.last && cursor_for(nodes.last)
      end

      # Return a cursor for this item.
      # @param item [Object] one of the passed in {items}, taken from {nodes}
      # @return [String]
      def cursor_for(item)
        raise PaginationImplementationMissingError, "Implement #{self.class}#cursor_for(item) to return the cursor for #{item.inspect}"
      end

      private

      def detect_was_authorized_by_scope_items
        if @context &&
            (current_runtime_state = Fiber[:__graphql_runtime_info]) &&
            (query_runtime_state = current_runtime_state[@context.query])
          query_runtime_state.was_authorized_by_scope_items
        else
          nil
        end
      end

      # @param argument [nil, Integer] `first` or `last`, as provided by the client
      # @param max_page_size [nil, Integer]
      # @return [nil, Integer] `nil` if the input was `nil`, otherwise a value between `0` and `max_page_size`
      def limit_pagination_argument(argument, max_page_size)
        if argument
          if argument < 0
            argument = 0
          elsif max_page_size && argument > max_page_size
            argument = max_page_size
          end
        end
        argument
      end

      def decode(cursor)
        context.schema.cursor_encoder.decode(cursor, nonce: true)
      end

      def encode(cursor)
        context.schema.cursor_encoder.encode(cursor, nonce: true)
      end

      # A wrapper around paginated items. It includes a {cursor} for pagination
      # and could be extended with custom relationship-level data.
      class Edge
        attr_reader :node

        def initialize(node, connection)
          @connection = connection
          @node = node
        end

        def parent
          @connection.parent
        end

        def cursor
          @cursor ||= @connection.cursor_for(@node)
        end

        def was_authorized_by_scope_items?
          @connection.was_authorized_by_scope_items?
        end
      end
    end
  end
end
