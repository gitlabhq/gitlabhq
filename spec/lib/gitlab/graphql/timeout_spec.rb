# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Timeout do
  it 'inherits from' do
    expect(described_class.superclass).to eq GraphQL::Schema::Timeout
  end

  it 'sends the error to our GraphQL logger with the variables and mutation document redacted', :aggregate_failures do
    field = double(path: 'parent_type.field')
    query = instance_double(
      GraphQL::Query,
      query_string: 'mutation { createNote(input: { body: "top-secret" }) { errors } }',
      sanitized_query_string: 'mutation { createNote(input: { body: "[REDACTED]" }) { errors } }',
      provided_variables: { 'input' => { 'body' => 'top-secret', 'url' => 'https://robot:pw@up.test' } },
      operation_name: nil
    )
    error = GraphQL::Schema::Timeout::TimeoutError.new(field)

    expect(Gitlab::GraphqlLogger).to receive(:error) do |payload|
      expect(payload[:message]).to eq('Timeout on parent_type.field')
      expect(payload[:query]).to eq('mutation { createNote(input: { body: "[REDACTED]" }) { errors } }')
      expect(payload[:query_variables]).to include('[FILTERED]')
      expect(payload[:query_variables]).not_to include('top-secret', 'robot:pw')
    end

    timeout = described_class.new(max_seconds: 30)
    timeout.handle_timeout(error, query)
  end
end
