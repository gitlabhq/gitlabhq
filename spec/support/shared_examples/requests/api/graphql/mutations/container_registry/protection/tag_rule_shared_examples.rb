# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'returning a mutation error' do |message|
  it 'returns an error from endpoint implementation (not from GraphQL framework)' do
    post_graphql_mutation_request.tap do
      expect_graphql_errors_to_be_empty
      expect(mutation_response['errors']).to match_array [message]
    end
  end

  it_behaves_like 'not persisting changes'
end

RSpec.shared_examples 'returning a GraphQL error' do |message|
  it 'returns a GraphQL error' do
    post_graphql_mutation_request.tap do
      expect_graphql_errors_to_include(message)
    end
  end

  it_behaves_like 'not persisting changes'
end

RSpec.shared_examples 'when user does not have permission' do
  context 'when user does not have permission' do
    let_it_be(:developer) { create(:user, developer_of: project) }
    let_it_be(:reporter) { create(:user, reporter_of: project) }
    let_it_be(:guest) { create(:user, guest_of: project) }
    let_it_be(:anonymous) { create(:user) }

    where(:current_user) do
      [ref(:developer), ref(:reporter), ref(:guest), ref(:anonymous)]
    end

    with_them do
      it_behaves_like 'returning a GraphQL error', /you don't have permission to perform this action/
    end
  end
end

RSpec.shared_examples 'when feature flag container_registry_protected_tags is disabled' do
  context "when feature flag ':container_registry_protected_tags' disabled" do
    before do
      stub_feature_flags(container_registry_protected_tags: false)
    end

    it_behaves_like 'returning a GraphQL error', /'container_registry_protected_tags' feature flag is disabled/
  end
end

RSpec.shared_examples 'when the GitLab API is not supported' do
  context 'when the GitLab API is not supported' do
    before do
      stub_gitlab_api_client_to_support_gitlab_api(supported: false)
    end

    it_behaves_like 'returning a mutation error', 'GitLab container registry API not supported'
  end
end
