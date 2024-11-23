# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::AgnosticTokenIdentifier, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:deploy_token) { create(:deploy_token).token }
  let_it_be(:feed_token) { user.feed_token }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user).token }
  let_it_be(:oauth_application_secret) { create(:oauth_application).plaintext_secret }

  subject(:token) { described_class.token_for(plaintext, :group_token_revocation_service) }

  context 'with supported token types' do
    where(:plaintext, :token_type) do
      ref(:personal_access_token) | ::Authn::Tokens::PersonalAccessToken
      ref(:feed_token) | ::Authn::Tokens::FeedToken
      ref(:deploy_token) | ::Authn::Tokens::DeployToken
      ref(:oauth_application_secret) | ::Authn::Tokens::OauthApplicationSecret
      'unsupported' | NilClass
    end

    with_them do
      describe '#initialize' do
        it 'finds the correct revocable token type' do
          expect(token).to be_instance_of(token_type)
        end
      end
    end
  end
end
