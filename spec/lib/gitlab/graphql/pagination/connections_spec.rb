# frozen_string_literal: true

require 'spec_helper'

# Tests that our connections are correctly mapped.
RSpec.describe ::Gitlab::Graphql::Pagination::Connections do
  include GraphqlHelpers

  before_all do
    ActiveRecord::Schema.define do
      create_table :_test_testing_pagination_nodes, force: true do |t|
        t.integer :value, null: false
      end
    end
  end

  after(:all) do
    ActiveRecord::Schema.define do
      drop_table :_test_testing_pagination_nodes, force: true
    end
  end

  let_it_be(:node_model) do
    Class.new(ActiveRecord::Base) do
      self.table_name = '_test_testing_pagination_nodes'
    end
  end

  let(:query_string) { 'query { items(first: 2) { nodes { value } } }' }
  let(:user) { nil }

  let(:node) { Struct.new(:value) }
  let(:node_type) do
    Class.new(::GraphQL::Schema::Object) do
      graphql_name 'Node'
      field :value, GraphQL::Types::Int, null: false
    end
  end

  let(:query_type) do
    item_values = nodes

    query_factory do |t|
      t.field :items, node_type.connection_type, null: true

      t.define_method :items do
        item_values
      end
    end
  end

  shared_examples 'it maps to a specific connection class' do |connection_type|
    let(:raw_values) { [1, 7, 42] }

    it "maps to #{connection_type.name}" do
      expect(connection_type).to receive(:new).and_call_original

      results = execute_query(query_type).to_h

      expect(graphql_dig_at(results, :data, :items, :nodes, :value)).to eq [1, 7]
    end
  end

  describe 'OffsetPaginatedRelation' do
    before do
      # Expect to be ordered by an explicit ordering.
      raw_values.each_with_index { |value, id| node_model.create!(id: id, value: value) }
    end

    let(:nodes) { ::Gitlab::Graphql::Pagination::OffsetPaginatedRelation.new(node_model.order(value: :asc)) }

    include_examples 'it maps to a specific connection class', Gitlab::Graphql::Pagination::OffsetActiveRecordRelationConnection
  end

  describe 'ActiveRecord::Relation' do
    before do
      # Expect to be ordered by ID descending
      [3, 2, 1].zip(raw_values) { |id, value| node_model.create!(id: id, value: value) }
    end

    let(:nodes) { node_model.all }

    include_examples 'it maps to a specific connection class', Gitlab::Graphql::Pagination::Keyset::Connection
  end

  describe 'ExternallyPaginatedArray' do
    let(:nodes) { ::Gitlab::Graphql::ExternallyPaginatedArray.new(nil, nil, node.new(1), node.new(7)) }

    include_examples 'it maps to a specific connection class', Gitlab::Graphql::Pagination::ExternallyPaginatedArrayConnection
  end

  describe 'Array' do
    let(:nodes) { raw_values.map { |x| node.new(x) } }

    include_examples 'it maps to a specific connection class', Gitlab::Graphql::Pagination::ArrayConnection
  end
end
