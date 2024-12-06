# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::CiTriggerToken, feature_category: :system_access do
  let_it_be(:user) { create(:user) }

  let(:ci_trigger) { create(:ci_trigger) }

  subject(:token) { described_class.new(plaintext, :api_admin_token) }

  context 'with valid ci trigger token' do
    let(:plaintext) { ci_trigger.token }
    let(:valid_revocable) { ci_trigger }

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
