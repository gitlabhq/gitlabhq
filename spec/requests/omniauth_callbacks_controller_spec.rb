# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniauthCallbacksController, feature_category: :system_access do
  include LoginHelpers
  include SessionHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:extern_uid) { generate(:username) }

  describe 'GET /users/auth/jwt/callback' do
    before do
      mock_auth_hash('jwt', extern_uid, user.email)
    end

    around do |example|
      with_omniauth_full_host { example.run }
    end

    context 'when the user is already signed in' do
      before do
        sign_in(user)
      end

      context 'when the user has a JWT identity' do
        before do
          create(:identity, provider: 'jwt', extern_uid: extern_uid, user: user)
        end

        it 'redirects to root path' do
          get user_jwt_omniauth_callback_path

          expect(response).to redirect_to root_path
        end
      end

      context 'when the user does not have a JWT identity' do
        it 'redirects to identities path to receive user authorization before linking the identity' do
          state = SecureRandom.uuid
          allow(SecureRandom).to receive(:uuid).and_return(state)

          get user_jwt_omniauth_callback_path

          expect(response)
            .to redirect_to new_user_settings_identities_path(
              provider: 'jwt',
              extern_uid: extern_uid,
              state: state
            )
        end
      end
    end
  end
end
