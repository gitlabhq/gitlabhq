# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::PersonalAccessToken, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

  subject(:token) { described_class.new(plaintext, :group_token_revocation_service) }

  context 'with valid personal access token' do
    let(:plaintext) { personal_access_token.token }
    let(:valid_revocable) { personal_access_token }

    it_behaves_like 'finding the valid revocable'

    describe '#revoke!' do
      it 'successfully revokes the token' do
        expect(token.revoke!(admin).status).to eq(:success)
      end
    end
  end

  context 'when the token is a resource token' do
    context 'when the token is a project access token' do
      let_it_be(:bot) { create(:user, :project_bot) }
      let_it_be(:project_member) { create(:project_member, source: create(:project), user: bot) }
      let_it_be(:plaintext) { create(:personal_access_token, user: bot).token }

      it 'successfully revokes the token', :enable_admin_mode do
        expect(token.revoke!(admin).status).to eq(:success)
      end
    end

    context 'when the token is a group access token' do
      let_it_be(:bot) { create(:user, :project_bot) }
      let_it_be(:group_member) { create(:group_member, source: create(:group), user: bot) }
      let_it_be(:plaintext) { create(:personal_access_token, user: bot).token }

      it 'successfully revokes the token', :enable_admin_mode do
        expect(token.revoke!(admin).status).to eq(:success)
      end
    end
  end

  context 'when the user is neither a human nor a bot' do
    let(:plaintext) { personal_access_token.token }

    it 'raises unsupported deploy token type' do
      expect(user).to receive(:human?).and_return(false)
      expect(user).to receive(:project_bot?).and_return(false)

      expect(::PersonalAccessToken).to receive(:find_by_token).with(plaintext).and_return(personal_access_token)

      expect do
        token.revoke!(admin)
      end
        .to raise_error(::Authn::AgnosticTokenIdentifier::UnsupportedTokenError,
          'Unsupported personal access token type')
    end
  end

  it_behaves_like 'token handling with unsupported token type'
end
