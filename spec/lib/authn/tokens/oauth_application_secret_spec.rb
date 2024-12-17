# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::OauthApplicationSecret, feature_category: :system_access do
  let_it_be(:user) { create(:user) }

  let(:oauth_application_secret) { create(:oauth_application) }

  subject(:token) { described_class.new(plaintext, :api_admin_token) }

  context 'with valid oauth application secret' do
    let(:plaintext) { oauth_application_secret.plaintext_secret }
    let(:valid_revocable) { oauth_application_secret }

    it_behaves_like 'finding the valid revocable'

    describe '#revoke!' do
      it 'does not support revocation yet' do
        expect do
          token.revoke!(user)
        end.to raise_error(::Authn::AgnosticTokenIdentifier::UnsupportedTokenError,
          'Revocation not supported for this token type')
      end
    end
  end

  it_behaves_like 'token handling with unsupported token type'
end
