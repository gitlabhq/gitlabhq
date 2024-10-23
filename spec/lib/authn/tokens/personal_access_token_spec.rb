# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::PersonalAccessToken, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

  subject(:token) { described_class.new(plaintext, :group_token_revocation_service) }

  context 'with valid personal access token' do
    let(:plaintext) { personal_access_token.token }
    let(:valid_revocable) { personal_access_token }

    it_behaves_like 'finding the valid revocable'

    describe '#revoke!' do
      it 'successfully revokes the token' do
        expect(token.revoke!(user).status).to eq(:success)
      end
    end
  end

  it_behaves_like 'token handling with unsupported token type'
end
