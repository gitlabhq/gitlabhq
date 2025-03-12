# frozen_string_literal: true
require "spec_helper"

if testing_mongoid?
  describe GraphQL::Pagination::MongoidRelationConnection do
    class Food
      include Mongoid::Document
      field :name, type: String
    end

    before do
      # Populate the DB
      Food.collection.drop
      ConnectionAssertions::NAMES.each { |n| Food.create(name: n) }
    end

    class MongoidRelationConnectionWithTotalCount < GraphQL::Pagination::MongoidRelationConnection
      def total_count
        items.count
      end
    end

    let(:schema) {
      ConnectionAssertions.build_schema(
        connection_class: GraphQL::Pagination::MongoidRelationConnection,
        total_count_connection_class: MongoidRelationConnectionWithTotalCount,
        get_items: -> { Food.all }
      )
    }

    include ConnectionAssertions
  end
end
