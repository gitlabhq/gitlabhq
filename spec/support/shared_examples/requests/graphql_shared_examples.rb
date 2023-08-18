# frozen_string_literal: true

RSpec.shared_examples 'a working graphql query' do
  include GraphqlHelpers

  it 'returns a successful response', :aggregate_failures do
    expect(response).to have_gitlab_http_status(:success)
    expect_graphql_errors_to_be_empty
    expect(json_response.keys).to include('data')
  end
end

RSpec.shared_examples 'a working graphql query that returns no data' do
  include GraphqlHelpers

  it_behaves_like 'a working graphql query'

  it 'contains no data' do
    expect(graphql_data.compact).to be_empty
  end
end

RSpec.shared_examples 'a working graphql query that returns data' do
  include GraphqlHelpers

  it_behaves_like 'a working graphql query'

  it 'contains data' do
    expect(graphql_data.compact).not_to be_empty
  end
end

RSpec.shared_examples 'a working GraphQL mutation' do
  include GraphqlHelpers

  before do
    post_graphql_mutation(mutation, current_user: current_user, token: token)
  end

  shared_examples 'allows access to the mutation' do
    let(:scopes) { ['api'] }

    it_behaves_like 'a working graphql query that returns data'
  end

  shared_examples 'prevents access to the mutation' do
    let(:scopes) { ['read_api'] }

    it 'does not resolve the mutation' do
      expect(graphql_data.compact).to be_empty
      expect(graphql_errors).to be_present
    end
  end

  context 'with a personal access token' do
    let(:token) do
      pat = create(:personal_access_token, user: current_user, scopes: scopes)
      { personal_access_token: pat }
    end

    it_behaves_like 'prevents access to the mutation'
    it_behaves_like 'allows access to the mutation'
  end

  context 'with an OAuth token' do
    let(:token) do
      { oauth_access_token: create(:oauth_access_token, resource_owner: current_user, scopes: scopes.join(' ')) }
    end

    it_behaves_like 'prevents access to the mutation'
    it_behaves_like 'allows access to the mutation'
  end
end

RSpec.shared_examples 'a mutation on an unauthorized resource' do
  it_behaves_like 'a mutation that returns top-level errors',
    errors: [::Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
end
