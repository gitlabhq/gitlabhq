# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Revoke a personal access token', feature_category: :permissions do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:token) { create(:personal_access_token, user: current_user) }

  let(:input) { { 'id' => token.to_global_id.to_s } }
  let(:mutation) { graphql_mutation(:personalAccessTokenRevoke, input) }
  let(:mutation_request) { post_graphql_mutation(mutation, current_user:) }

  it 'revokes the specified personal access token', :aggregate_failures do
    expect { mutation_request }.to change { token.reload.revoked? }.to(true)
    expect(graphql_data_at(:personalAccessTokenRevoke, :errors)).to be_empty
  end

  context 'when revocation fails' do
    before do
      allow_next_instance_of(::PersonalAccessTokens::RevokeService) do |instance|
        allow(instance).to receive(:execute).and_return(ServiceResponse.error(message: 'Token revocation failed'))
      end
    end

    it 'does not revoke the specified personal access token', :aggregate_failures do
      expect { mutation_request }.not_to change { token.reload.revoked? }
      expect(graphql_data_at(:personalAccessTokenRevoke, :errors)).to include('Token revocation failed')
    end
  end

  context 'when current user does not have revoke_token permission for the personal access token' do
    let_it_be(:current_user) { create(:user) }

    it 'does not revoke the specified personal access token', :aggregate_failures do
      expect { mutation_request }.not_to change { token.reload.revoked? }
      expect_graphql_errors_to_include(
        "The resource that you are attempting to access does not exist " \
          "or you don't have permission to perform this action"
      )
    end
  end

  context 'when the granular_personal_access_tokens feature flag is disabled' do
    before do
      stub_feature_flags(granular_personal_access_tokens: false)
    end

    it 'returns a resource not available error' do
      expect { mutation_request }.not_to change { token.reload.revoked? }

      expect_graphql_errors_to_include("`granular_personal_access_tokens` feature flag is disabled.")
    end
  end
end
