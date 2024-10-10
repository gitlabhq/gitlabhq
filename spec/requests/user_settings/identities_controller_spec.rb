# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserSettings::IdentitiesController, feature_category: :system_access do
  include LoginHelpers
  include SessionHelpers

  let(:user) { create(:user) }
  let(:state) { SecureRandom.uuid }

  before do
    sign_in(user)
  end

  describe 'GET /-/user_settings/identities/new', :clean_gitlab_redis_sessions do
    subject(:request) { get new_user_settings_identities_path(state: state) }

    context 'when the state matches' do
      before do
        stub_session(
          session_data: {
            identity_link_state: state,
            identity_link_provider: 'jwt',
            identity_link_extern_uid: 'jwt-uid'
          }
        )
      end

      it 'returns 200 OK' do
        request

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when the user has an existing matching identity' do
        before do
          create(:identity, user: user, provider: 'jwt', extern_uid: 'jwt-uid')
        end

        it 'redirects to profile account path' do
          request

          expect(response).to redirect_to profile_account_path
        end
      end
    end

    context 'when the state does not match' do
      it 'returns 403 forbidden' do
        request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'POST /-/user_settings/identities', :clean_gitlab_redis_sessions do
    subject(:request) { post user_settings_identities_path }

    context 'with valid parameters' do
      before do
        stub_session(
          session_data: {
            identity_link_state: state,
            identity_link_provider: 'jwt',
            identity_link_extern_uid: 'jwt-uid'
          }
        )
      end

      it 'redirects and notifies the user that authentication method was updated' do
        request

        expect(response).to redirect_to profile_account_path
        expect(flash[:notice]).to eq(_('Authentication method updated'))
      end
    end

    context 'when required session data is not present' do
      before do
        stub_session(
          session_data: {
            identity_link_state: state,
            identity_link_provider: 'jwt'
          }
        )
      end

      it 'redirects and notifies the user that errors occurred' do
        request

        expect(response).to redirect_to profile_account_path
        expect(flash[:notice]).to eq(
          format(_('Error linking identity: %{errors}'), errors: 'Provider and Extern UID must be in the session.')
        )
      end
    end

    context 'when saving the identity produces errors' do
      before do
        create(:identity, provider: 'jwt', extern_uid: 'jwt-uid')

        stub_session(
          session_data: {
            identity_link_state: state,
            identity_link_extern_uid: 'jwt-uid',
            identity_link_provider: 'jwt'
          }
        )
      end

      it 'redirects and notifies the user that errors occurred' do
        request

        expect(response).to redirect_to profile_account_path
        expect(flash[:notice]).to eq(
          format(_('Error linking identity: %{errors}'),
            errors: "Extern uid has already been taken. " \
              "Please contact your administrator to generate a unique extern_uid / NameID")
        )
      end
    end
  end
end
