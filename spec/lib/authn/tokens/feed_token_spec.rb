# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::FeedToken, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:feed_token) { user.feed_token }

  subject(:token) { described_class.new(plaintext, :group_token_revocation_service) }

  context 'with valid feed token' do
    let(:plaintext) { feed_token }
    let(:valid_revocable) { user }

    it_behaves_like 'finding the valid revocable'

    describe '#revoke!' do
      it 'successfully revokes the token' do
        expect(token.revoke!(user).status).to eq(:success)
      end
    end
  end

  it_behaves_like 'token handling with unsupported token type'
end
