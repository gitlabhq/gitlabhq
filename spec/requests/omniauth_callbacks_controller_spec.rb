# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniauthCallbacksController, :with_current_organization, :aggregate_failures, feature_category: :system_access do
  include LoginHelpers
  include SessionHelpers

  let(:user) { create(:user) }
  let(:extern_uid) { generate(:username) }

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

          expect(response).to redirect_to new_user_settings_identities_path(state: state)
          expect(session['identity_link_state']).to eq(state)
          expect(session['identity_link_extern_uid']).to eq(extern_uid)
          expect(session['identity_link_provider']).to eq('jwt')
        end
      end
    end
  end

  describe '#atlassian_oauth2' do
    describe 'omniauth with strategies for atlassian_oauth2 when the user and identity already exist' do
      shared_context 'with sign_up' do
        let(:extern_uid) { 'my-uid' }
        let(:user) { create(:atlassian_user, extern_uid: extern_uid) }
        let(:expected_context) do
          { 'meta.caller_id' => 'OmniauthCallbacksController#atlassian_oauth2',
            'meta.user' => user.username }
        end

        subject do
          stub_omniauth_setting(block_auto_created_users: false)

          post '/users/auth/atlassian_oauth2/callback'
        end

        include_examples 'set_current_context'
      end
    end
  end

  describe 'sign-in when the email matches an existing account and auto_link is disabled' do
    let(:extern_uid) { 'collision-uid' }
    let(:auth_email) { 'collision@example.com' }
    let(:password) { User.random_password }
    let(:existing_user) { create(:user, email: 'collision@example.com', password: password) }

    around do |example|
      with_omniauth_full_host { example.run }
    end

    before do
      existing_user
      stub_omniauth_setting(enabled: true, auto_link_user: false, allow_single_sign_on: ['atlassian_oauth2'])
      stub_omniauth_setting(block_auto_created_users: false)
      mock_auth_hash('atlassian_oauth2', extern_uid, auth_email)
    end

    it 'redirects to sign-in, stashes the pending identity, and does not create a user' do
      state = SecureRandom.uuid
      allow(SecureRandom).to receive(:uuid).and_return(state)

      expect do
        post '/users/auth/atlassian_oauth2/callback'
      end.not_to change { User.count }

      expect(response).to redirect_to(new_user_session_path)
      expect(request.env['warden']).not_to be_authenticated

      expect(session['identity_link_state']).to eq(state)
      expect(session['identity_link_provider']).to eq('atlassian_oauth2')
      expect(session['identity_link_extern_uid']).to eq(extern_uid)
      expect(session['identity_link_user_id']).to eq(existing_user.id)
      expect(session['user_return_to']).to eq(new_user_settings_identities_path(state: state))
      expect(flash[:notice]).to include('Sign in with your existing credentials to connect your')
    end

    it 'lands on the identity authorization page once the user signs in' do
      post '/users/auth/atlassian_oauth2/callback'

      state = session['identity_link_state']
      expect(state).to be_present
      expect(session['user_return_to']).to eq(new_user_settings_identities_path(state: state))

      post user_session_path(user: { login: existing_user.username, password: existing_user.password })

      expect(request.env['warden']).to be_authenticated
      expect(response).to redirect_to(new_user_settings_identities_path(state: state))
      expect(session['identity_link_provider']).to eq('atlassian_oauth2')
      expect(session['identity_link_extern_uid']).to eq(extern_uid)
      expect(session['identity_link_user_id']).to eq(existing_user.id)
    end

    context 'when the failure is not an email collision' do
      before do
        allow_next_instance_of(Gitlab::Auth::OAuth::User) do |auth_user|
          allow(auth_user).to receive(:existing_user_for_email_link).and_return(nil)
        end
      end

      it 'falls back to the 422 failure page and does not stash an identity' do
        post '/users/auth/atlassian_oauth2/callback'

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(request.env['warden']).not_to be_authenticated
        expect(session['identity_link_provider']).to be_nil
      end
    end
  end

  describe '#saml' do
    let(:last_request_id) { 'ONELOGIN_4fee3b046395c4e751011e97f8900b5273d56685' }
    let(:user) { create(:omniauth_user, :two_factor, extern_uid: 'my-uid', provider: 'saml') }
    let(:mock_saml_response) { File.read('spec/fixtures/authentication/saml_response.xml') }
    let(:saml_config) { mock_saml_config_with_upstream_two_factor_authn_contexts }

    before do
      stub_omniauth_saml_config(
        enabled: true,
        auto_link_saml_user: true,
        allow_single_sign_on: ['saml'],
        providers: [saml_config]
      )
      mock_auth_hash_with_saml_xml('saml', +'my-uid', user.email, mock_saml_response)
    end

    describe 'with IdP initiated request' do
      let(:expected_context) do
        { 'meta.caller_id' => 'OmniauthCallbacksController#saml',
          'meta.user' => user.username }
      end

      subject do
        sign_in user

        post '/users/auth/saml'
      end

      include_examples 'set_current_context'
    end
  end
end
