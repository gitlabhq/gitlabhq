# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Rotate a personal access token', feature_category: :system_access do
  include GraphqlHelpers

  let_it_be(:token_owner) { create(:user) }
  let_it_be(:current_user) { token_owner }

  let_it_be(:token) { create(:personal_access_token, user: token_owner, expires_at: 1.week.from_now) }
  let_it_be(:request_token) { create(:personal_access_token, user: current_user) }

  let(:input) { { 'id' => token.to_global_id.to_s } }
  let(:mutation) { graphql_mutation(:personalAccessTokenRotate, input) }
  let(:mutation_request) do
    post_graphql_mutation(mutation, current_user: current_user, token: { personal_access_token: request_token })
  end

  it 'rotates the specified personal access token', :aggregate_failures do
    expect { mutation_request }.to change { token_owner.reload.personal_access_tokens.count }.by(1)
    expect(token.reload).to be_revoked
    expect(token.expires_at).to eq token_owner.personal_access_tokens.last.expires_at
    expect(graphql_data_at(:personalAccessTokenRotate, :token)).to be_present
    expect(graphql_data_at(:personalAccessTokenRotate, :errors)).to be_empty
  end

  context 'when rotation fails' do
    before do
      allow_next_instance_of(::PersonalAccessTokens::RotateService) do |instance|
        allow(instance).to receive(:execute).and_return(ServiceResponse.error(message: 'Token rotation failed'))
      end
    end

    it 'does not rotate the specified personal access token', :aggregate_failures do
      expect { mutation_request }.not_to change { token_owner.reload.personal_access_tokens.count }
      expect(token.reload).not_to be_revoked
      expect(graphql_data_at(:personalAccessTokenRotate, :errors)).to include('Token rotation failed')
    end
  end

  context 'when current user does not have manage_user_personal_access_token permission on the token' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:request_token) { create(:personal_access_token, user: current_user) }

    it 'does not rotate the specified personal access token', :aggregate_failures do
      expect { mutation_request }.not_to change { token_owner.reload.personal_access_tokens.count }
      expect(token.reload).not_to be_revoked
      expect_graphql_errors_to_include(
        "The resource that you are attempting to access does not exist " \
          "or you don't have permission to perform this action"
      )
    end
  end

  context 'when token does not exist' do
    let(:non_existent_token_id) { "gid://gitlab/PersonalAccessToken/#{non_existing_record_id}" }
    let(:input) { { 'id' => non_existent_token_id } }

    it 'returns an error' do
      mutation_request

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

    it 'does not rotate the specified personal access token', :aggregate_failures do
      expect { mutation_request }.not_to change { token_owner.reload.personal_access_tokens.count }
      expect(token.reload).not_to be_revoked
      expect_graphql_errors_to_include("`granular_personal_access_tokens` feature flag is disabled.")
    end
  end

  context 'when expires_at is provided', :freeze_time do
    let(:new_expires_at) { 2.weeks.from_now.to_date }
    let(:input) { super().merge('expiresAt' => new_expires_at) }

    it 'creates the new token with the provided expiration date' do
      mutation_request

      new_token = token_owner.reload.personal_access_tokens.last
      expect(new_token.expires_at).to eq new_expires_at
    end
  end
end
