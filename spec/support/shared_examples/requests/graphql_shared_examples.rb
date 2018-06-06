require 'spec_helper'

shared_examples 'a working graphql query' do
  include GraphqlHelpers

  it 'is returns a successfull response', :aggregate_failures do
    expect(response).to be_success
    expect(graphql_errors['errors']).to be_nil
    expect(json_response.keys).to include('data')
  end
end
