# frozen_string_literal: true
require "graphql/pagination/connection"

module GraphQL
  module Pagination
    class ArrayConnection < Pagination::Connection
      def nodes
        load_nodes
        @nodes
      end

      def has_previous_page
        load_nodes
        @has_previous_page
      end

      def has_next_page
        load_nodes
        @has_next_page
      end

      def cursor_for(item)
        idx = items.find_index(item) + 1
        encode(idx.to_s)
      end

      private

      def index_from_cursor(cursor)
        decode(cursor).to_i
      end

      # Populate all the pagination info _once_,
      # It doesn't do anything on subsequent calls.
      def load_nodes
        @nodes ||= begin
          sliced_nodes = if before && after
            end_idx = index_from_cursor(before) - 2
            end_idx < 0 ? [] : items[index_from_cursor(after)..end_idx] || []
          elsif before
            end_idx = index_from_cursor(before) - 2
            end_idx < 0 ? [] : items[0..end_idx] || []
          elsif after
            items[index_from_cursor(after)..-1] || []
          else
            items
          end

          @has_previous_page = if last
            # There are items preceding the ones in this result
            sliced_nodes.count > last
          elsif after
            # We've paginated into the Array a bit, there are some behind us
            index_from_cursor(after) > 0
          else
            false
          end

          @has_next_page = if before
            # The original array is longer than the `before` index
            index_from_cursor(before) < items.length + 1
          elsif first
            # There are more items after these items
            sliced_nodes.count > first
          else
            false
          end

          limited_nodes = sliced_nodes

          limited_nodes = limited_nodes.first(first) if first
          limited_nodes = limited_nodes.last(last) if last

          limited_nodes
        end
      end
    end
  end
end
