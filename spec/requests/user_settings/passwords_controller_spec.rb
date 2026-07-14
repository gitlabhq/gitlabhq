# frozen_string_literal: true

require('spec_helper')

RSpec.describe UserSettings::PasswordsController, type: :request, feature_category: :system_access do
  let(:deactivated_user) { create(:user, :deactivated) }

  let(:password) { User.random_password }
  let(:password_confirmation) { password }
  let(:reset_password_token) { deactivated_user.send_reset_password_instructions }

  subject(:update_password) do
    put user_settings_password_path, params: {
      user: {
        password: password,
        password_confirmation: password_confirmation,
        reset_password_token: reset_password_token
      }
    }
  end

  describe '#new' do
    context 'when a deactivated user signs-in after an admin resets their password' do
      before do
        sign_in deactivated_user
        get new_user_settings_password_path
        deactivated_user.reload
      end

      it 'reactivates the user', :aggregate_failures do
        expect(deactivated_user[:state]).to eq('active')
        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'renders the update password page' do
        expect(response.body).to include('To continue, please update your password')
      end
    end
  end

  describe '#reset' do
    context 'when user is an SSO/OAuth user without a password' do
      let(:sso_user) { create(:omniauth_user, password_automatically_set: true) }

      before do
        sign_in sso_user
        stub_application_setting(disable_password_authentication_for_users_with_sso_identities: true)
      end

      it 'sends reset password instructions and does not return 404' do
        expect { put reset_user_settings_password_path }
          .to have_enqueued_mail(DeviseMailer, :reset_password_instructions)

        expect(response).to redirect_to(edit_user_settings_password_path)
      end
    end

    context 'when user has password authentication disabled and has already set a password' do
      let(:regular_user) { create(:user, password_automatically_set: false) }

      before do
        sign_in regular_user
        stub_application_setting(
          password_authentication_enabled_for_web: false,
          password_authentication_enabled_for_git: false
        )
      end

      it 'returns 404' do
        put reset_user_settings_password_path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#create' do
    context 'when a deactivated user signs-in after an admin resets their password' do
      before do
        sign_in deactivated_user
        get new_user_settings_password_path
        deactivated_user.reload
      end

      context 'when the user updates their password' do
        before do
          update_password
          get new_user_session_path
        end

        it 'redirects backs to the root path(sign-in page)', :aggregate_failures do
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end
end
