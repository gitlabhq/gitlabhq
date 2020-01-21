# frozen_string_literal: true

require 'spec_helper'

# Shared example for legal queries that are expected to return nil.
# Requires the following let bindings to be defined:
#  - post_query: action to send the query
#  - path: array of keys from query root to the result
shared_examples 'a failure to find anything' do
  it 'finds nothing' do
    post_query

    data = graphql_data.dig(*path)

    expect(data).to be_nil
  end
end
