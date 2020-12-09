# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Timeout do
  it 'inherits from' do
    expect(described_class.superclass).to eq GraphQL::Schema::Timeout
  end

  it 'sends the error to our GraphQL logger' do
    parent_type = double(graphql_name: 'parent_type')
    field = double(graphql_name: 'field')
    query = double(query_string: 'query_string', provided_variables: 'provided_variables')
    error = GraphQL::Schema::Timeout::TimeoutError.new(parent_type, field)

    expect(Gitlab::GraphqlLogger)
      .to receive(:error)
      .with(message: 'Timeout on parent_type.field', query: 'query_string', query_variables: 'provided_variables')

    timeout = described_class.new(max_seconds: 30)
    timeout.handle_timeout(error, query)
  end
end
