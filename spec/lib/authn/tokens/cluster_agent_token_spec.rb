# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::ClusterAgentToken, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }

  let(:cluster_agent_token) { create(:cluster_agent_token, token_encrypted: nil) }

  subject(:token) { described_class.new(plaintext, :api_admin_token) }

  context 'with valid cluster agent token' do
    let(:plaintext) { cluster_agent_token.token }
    let(:valid_revocable) { cluster_agent_token }

    it_behaves_like 'finding the valid revocable'

    describe '#revoke!', :enable_admin_mode do
      it 'revokes the token' do
        expect(token.revocable.revoked?).to be_falsey

        expect(token.revoke!(admin)).to be_success

        expect(token.revocable.revoked?).to be_truthy
      end
    end
  end

  it_behaves_like 'token handling with unsupported token type'
end
