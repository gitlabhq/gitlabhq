# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::RunnerAuthenticationToken, feature_category: :system_access do
  let_it_be(:user) { create(:user) }

  let(:runner) { create(:ci_runner, registration_type: :authenticated_user) }

  subject(:token) { described_class.new(plaintext, :api_admin_token) }

  context 'with valid runner authentication token' do
    let(:plaintext) { runner.token }
    let(:valid_revocable) { runner }

    it_behaves_like 'finding the valid revocable'

    describe '#revoke!' do
      it 'does not support revocation yet' do
        expect do
          token.revoke!(user)
        end.to raise_error(::Authn::AgnosticTokenIdentifier::UnsupportedTokenError, 'Unsupported token type')
      end
    end
  end

  it_behaves_like 'token handling with unsupported token type'
end
