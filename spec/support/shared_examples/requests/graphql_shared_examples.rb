# frozen_string_literal: true

RSpec.shared_examples 'a working graphql query' do
  include GraphqlHelpers

  it 'returns a successful response', :aggregate_failures do
    expect(response).to have_gitlab_http_status(:success)
    expect(graphql_errors).to be_nil
    expect(json_response.keys).to include('data')
  end
end

RSpec.shared_examples 'a mutation on an unauthorized resource' do
  it_behaves_like 'a mutation that returns top-level errors',
                      errors: [::Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
end
