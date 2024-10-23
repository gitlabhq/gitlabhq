# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::DeployToken, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:deploy_token) { create(:group_deploy_token, group: group).deploy_token }

  subject(:token) { described_class.new(plaintext, :group_token_revocation_service) }

  context 'with valid deploy token' do
    let(:plaintext) { deploy_token.token }
    let(:valid_revocable) { deploy_token }

    it_behaves_like 'finding the valid revocable'

    describe '#revoke!' do
      it 'successfully revokes the token' do
        expect(token.revoke!(user)).to be_truthy
      end
    end
  end

  it_behaves_like 'token handling with unsupported token type'
end
