# frozen_string_literal: true
require "graphql/pagination/relation_connection"

module GraphQL
  module Pagination
    # Customizes `RelationConnection` to work with `ActiveRecord::Relation`s.
    class ActiveRecordRelationConnection < Pagination::RelationConnection
      private

      def relation_count(relation)
        int_or_hash = if already_loaded?(relation)
          relation.size
        elsif relation.respond_to?(:unscope)
          relation.unscope(:order).count(:all)
        else
          # Rails 3
          relation.count
        end
        if int_or_hash.is_a?(Integer)
          int_or_hash
        else
          # Grouped relations return count-by-group hashes
          int_or_hash.length
        end
      end

      def relation_limit(relation)
        if relation.is_a?(Array)
          nil
        else
          relation.limit_value
        end
      end

      def relation_offset(relation)
        if relation.is_a?(Array)
          nil
        else
          relation.offset_value
        end
      end

      def null_relation(relation)
        if relation.respond_to?(:none)
          relation.none
        else
          # Rails 3
          relation.where("1=2")
        end
      end

      def set_limit(nodes, limit)
        if already_loaded?(nodes)
          nodes.take(limit)
        else
          super
        end
      end

      def set_offset(nodes, offset)
        if already_loaded?(nodes)
          # If the client sent a bogus cursor beyond the size of the relation,
          # it might get `nil` from `#[...]`, so return an empty array in that case
          nodes[offset..-1] || []
        else
          super
        end
      end

      private

      def already_loaded?(relation)
        relation.is_a?(Array) || relation.loaded?
      end
    end
  end
end
