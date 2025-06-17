# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::IncomingEmailToken, :aggregate_failures, feature_category: :system_access do
  let(:user) { create(:user) }

  subject(:token) { described_class.new(plaintext, :api_admin_token) }

  context 'with valid incoming email token' do
    let(:plaintext) { user.incoming_email_token }
    let(:valid_revocable) { user }
    let_it_be(:default_prefix) { ::User::INCOMING_MAIL_TOKEN_PREFIX }

    it_behaves_like 'finding the valid revocable'

    it_behaves_like 'contains instance prefix when enabled'

    describe '#revoke!' do
      subject(:revoke) { token.revoke!(user) }

      it 'successfully resets the token' do
        expect { revoke }.to change { user.reload.incoming_email_token }
        expect(revoke.success?).to be_truthy
      end
    end
  end

  it_behaves_like 'token handling with unsupported token type'
end
