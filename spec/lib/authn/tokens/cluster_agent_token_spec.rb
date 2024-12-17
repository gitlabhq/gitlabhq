# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::ClusterAgentToken, feature_category: :system_access do
  let_it_be(:user) { create(:user) }

  let(:cluster_agent_token) { create(:cluster_agent_token, token_encrypted: nil) }

  subject(:token) { described_class.new(plaintext, :api_admin_token) }

  context 'with valid cluster agent token' do
    let(:plaintext) { cluster_agent_token.token }
    let(:valid_revocable) { cluster_agent_token }

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
