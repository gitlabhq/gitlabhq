# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::ConnectionNodesCount, feature_category: :api do
  let(:context) do
    GraphQL::Query::Context.new(
      query: GraphQL::Query.new(GitlabSchema, document: nil, context: {}, variables: {}),
      values: {}
    )
  end

  let(:connection_class) do
    Class.new do
      attr_reader :context
      attr_accessor :page

      def initialize(page, context:)
        @page = page
        @context = context
      end

      def nodes
        page.dup
      end

      prepend Gitlab::Graphql::ConnectionNodesCount
    end
  end

  def connection_nodes
    context.namespace(:gl_logging)[:connection_nodes]
  end

  it 'adds the page size once when nodes is read many times' do
    connection = connection_class.new([1, 2, 3], context: context)

    3.times { connection.nodes }

    expect(connection_nodes).to eq(3)
  end

  it 'adds up the pages of all connections in the query' do
    connection_class.new([1, 2, 3], context: context).nodes
    connection_class.new([4, 5], context: context).nodes

    expect(connection_nodes).to eq(5)
  end

  it 'counts the latest page when the page changes' do
    connection = connection_class.new([1, 2, 3], context: context)
    connection.nodes

    connection.page = [1]
    connection.nodes

    expect(connection_nodes).to eq(1)
  end

  it 'counts an empty page as 0' do
    connection_class.new([], context: context).nodes

    expect(connection_nodes).to eq(0)
  end
end
