# frozen_string_literal: true
require "graphql/pagination/connection"

module GraphQL
  module Pagination
    # A generic class for working with database query objects.
    class RelationConnection < Pagination::Connection
      def nodes
        load_nodes
        @nodes
      end

      def has_previous_page
        if @has_previous_page.nil?
          @has_previous_page = if after_offset && after_offset > 0
            true
          elsif last
            # See whether there are any nodes _before_ the current offset.
            # If there _is no_ current offset, then there can't be any nodes before it.
            # Assume that if the offset is positive, there are nodes before the offset.
            limited_nodes
            !(@paged_nodes_offset.nil? || @paged_nodes_offset == 0)
          else
            false
          end
        end
        @has_previous_page
      end

      def has_next_page
        if @has_next_page.nil?
          @has_next_page = if before_offset && before_offset > 0
            true
          elsif first
            if @nodes && @nodes.count < first
              false
            else
              relation_larger_than(sliced_nodes, @sliced_nodes_offset, first)
            end
          else
            false
          end
        end
        @has_next_page
      end

      def cursor_for(item)
        load_nodes
        # index in nodes + existing offset + 1 (because it's offset, not index)
        offset = nodes.index(item) + 1 + (@paged_nodes_offset || 0) - (relation_offset(items) || 0)
        encode(offset.to_s)
      end

      private

      # @param relation [Object] A database query object
      # @param _initial_offset [Integer] The number of items already excluded from the relation
      # @param size [Integer] The value against which we check the relation size
      # @return [Boolean] True if the number of items in this relation is larger than `size`
      def relation_larger_than(relation, _initial_offset, size)
        relation_count(set_limit(relation, size + 1)) == size + 1
      end

      # @param relation [Object] A database query object
      # @return [Integer, nil] The offset value, or nil if there isn't one
      def relation_offset(relation)
        raise "#{self.class}#relation_offset(relation) must return the offset value for a #{relation.class} (#{relation.inspect})"
      end

      # @param relation [Object] A database query object
      # @return [Integer, nil] The limit value, or nil if there isn't one
      def relation_limit(relation)
        raise "#{self.class}#relation_limit(relation) must return the limit value for a #{relation.class} (#{relation.inspect})"
      end

      # @param relation [Object] A database query object
      # @return [Integer, nil] The number of items in this relation (hopefully determined without loading all records into memory!)
      def relation_count(relation)
        raise "#{self.class}#relation_count(relation) must return the count of records for a #{relation.class} (#{relation.inspect})"
      end

      # @param relation [Object] A database query object
      # @return [Object] A modified query object which will return no records
      def null_relation(relation)
        raise "#{self.class}#null_relation(relation) must return an empty relation for a #{relation.class} (#{relation.inspect})"
      end

      # @return [Integer]
      def offset_from_cursor(cursor)
        decode(cursor).to_i
      end

      # Abstract this operation so we can always ignore inputs less than zero.
      # (Sequel doesn't like it, understandably.)
      def set_offset(relation, offset_value)
        if offset_value >= 0
          relation.offset(offset_value)
        else
          relation.offset(0)
        end
      end

      # Abstract this operation so we can always ignore inputs less than zero.
      # (Sequel doesn't like it, understandably.)
      def set_limit(relation, limit_value)
        if limit_value > 0
          relation.limit(limit_value)
        elsif limit_value == 0
          null_relation(relation)
        else
          relation
        end
      end

      def calculate_sliced_nodes_parameters
        if defined?(@sliced_nodes_limit)
          return
        else
          next_offset = relation_offset(items) || 0
          relation_limit = relation_limit(items)

          if after_offset
            next_offset += after_offset
          end

          if before_offset && after_offset
            if after_offset < before_offset
              # Get the number of items between the two cursors
              space_between = before_offset - after_offset - 1
              relation_limit = space_between
            else
              # The cursors overextend one another to an empty set
              @sliced_nodes_null_relation = true
            end
          elsif before_offset
            # Use limit to cut off the tail of the relation
            relation_limit = before_offset - 1
          end

          @sliced_nodes_limit = relation_limit
          @sliced_nodes_offset = next_offset
        end
      end

      # Apply `before` and `after` to the underlying `items`,
      # returning a new relation.
      def sliced_nodes
        @sliced_nodes ||= begin
          calculate_sliced_nodes_parameters
          paginated_nodes = items

          if @sliced_nodes_null_relation
            paginated_nodes = null_relation(paginated_nodes)
          else
            if @sliced_nodes_limit
              paginated_nodes = set_limit(paginated_nodes, @sliced_nodes_limit)
            end

            if @sliced_nodes_offset
              paginated_nodes = set_offset(paginated_nodes, @sliced_nodes_offset)
            end
          end

          paginated_nodes
        end
      end

      # @return [Integer, nil]
      def before_offset
        @before_offset ||= before && offset_from_cursor(before)
      end

      # @return [Integer, nil]
      def after_offset
        @after_offset ||= after && offset_from_cursor(after)
      end

      # Apply `first` and `last` to `sliced_nodes`,
      # returning a new relation
      def limited_nodes
        @limited_nodes ||= begin
          calculate_sliced_nodes_parameters
          if @sliced_nodes_null_relation
            # it's an empty set
            return sliced_nodes
          end
          relation_limit = @sliced_nodes_limit
          relation_offset = @sliced_nodes_offset

          if first && (relation_limit.nil? || relation_limit > first)
            # `first` would create a stricter limit that the one already applied, so add it
            relation_limit = first
          end

          if last
            if relation_limit
              if last <= relation_limit
                # `last` is a smaller slice than the current limit, so apply it
                relation_offset += (relation_limit - last)
                relation_limit = last
              end
            else
              # No limit, so get the last items
              sliced_nodes_count = relation_count(sliced_nodes)
              relation_offset += (sliced_nodes_count - [last, sliced_nodes_count].min)
              relation_limit = last
            end
          end

          @paged_nodes_offset = relation_offset
          paginated_nodes = items
          paginated_nodes = set_offset(paginated_nodes, relation_offset)
          if relation_limit
            paginated_nodes = set_limit(paginated_nodes, relation_limit)
          end
          paginated_nodes
        end
      end

      # Load nodes after applying first/last/before/after,
      # returns an array of nodes
      def load_nodes
        # Return an array so we can consistently use `.index(node)` on it
        @nodes ||= limited_nodes.to_a
      end
    end
  end
end
