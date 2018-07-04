require 'spec_helper'

shared_examples 'a working graphql query' do
  include GraphqlHelpers

  it 'returns a successful response', :aggregate_failures do
    expect(response).to have_gitlab_http_status(:success)
    expect(graphql_errors['errors']).to be_nil
    expect(json_response.keys).to include('data')
  end
end
