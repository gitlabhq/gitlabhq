# frozen_string_literal: true
require "graphql/pagination/relation_connection"

module GraphQL
  module Pagination
    class MongoidRelationConnection < Pagination::RelationConnection
      def relation_offset(relation)
        relation.options.skip
      end

      def relation_limit(relation)
        relation.options.limit
      end

      def relation_count(relation)
        relation.all.count(relation.options.slice(:limit, :skip))
      end

      def null_relation(relation)
        relation.without_options.none
      end
    end
  end
end
