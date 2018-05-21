require 'spec_helper'

shared_examples 'a working graphql query' do
  include GraphqlHelpers

  let(:parsed_response) { JSON.parse(response.body) }
  let(:response_data) { parsed_response['data'] }

  before do
    post_graphql(query)
  end

  it 'is returns a successfull response', :aggregate_failures do
    expect(response).to be_success
    expect(parsed_response['errors']).to be_nil
    expect(response_data).not_to be_empty
  end
end
