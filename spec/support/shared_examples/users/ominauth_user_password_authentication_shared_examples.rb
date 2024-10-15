# frozen_string_literal: true

RSpec.shared_examples 'OmniAuth user password authentication' do
  let(:user) { create(:omniauth_user) }

  context 'when omniauth user sets a local password' do
    before do
      user.update!(password_automatically_set: false)
    end

    it { is_expected.to eq(true) }

    context 'when password authentication is disabled for users with an SSO identity' do
      before do
        stub_application_setting(disable_password_authentication_for_users_with_sso_identities: true)
      end

      context 'when the user has no SSO identity' do
        let!(:user) { create(:user) }

        it { is_expected.to eq(true) }
      end

      context 'when the user has a SAML identity' do
        let!(:user) { create(:omniauth_user, provider: 'saml', password_automatically_set: false) }

        it { is_expected.to eq(false) }
      end

      context 'when the user has a different identity' do
        let!(:user) { create(:omniauth_user, password_automatically_set: false) }

        it { is_expected.to eq(false) }
      end
    end
  end
end
