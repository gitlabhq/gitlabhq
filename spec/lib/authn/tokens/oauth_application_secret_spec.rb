# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::OauthApplicationSecret, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }

  let(:oauth_application_secret) { create(:oauth_application) }

  subject(:token) { described_class.new(plaintext, :api_admin_token) }

  context 'with valid oauth application secret' do
    let(:plaintext) { oauth_application_secret.plaintext_secret }
    let(:valid_revocable) { oauth_application_secret }

    it_behaves_like 'finding the valid revocable'

    describe '#revoke!', :enable_admin_mode do
      subject(:revoke) { described_class.new(plaintext, :api_admin_token).revoke!(current_user) }

      context 'as admin' do
        let(:current_user) { admin }

        it 'successfully revokes the token' do
          expect { revoke }.to change { oauth_application_secret.reload.secret }
        end

        it 'does support revocation' do
          expect { revoke }.not_to raise_error
        end
      end

      context 'as a user' do
        let(:current_user) { user }

        it 'does not reset the token' do
          expect { revoke }.not_to change { oauth_application_secret.reload.secret }
        end

        it 'returns an error' do
          expect(revoke.error?).to be_truthy
        end
      end
    end
  end

  it_behaves_like 'token handling with unsupported token type'
end
