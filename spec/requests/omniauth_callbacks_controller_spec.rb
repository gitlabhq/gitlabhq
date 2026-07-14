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

  describe 'sign-in when the current organization is read-only', :without_current_organization do
    let_it_be_with_reload(:read_only_organization) { create(:organization) }

    let(:extern_uid) { 'read-only-uid' }
    let(:auth_email) { 'new-user@example.com' }
    let(:organization_headers) do
      { Gitlab::Current::Organization::HTTP_HEADER => read_only_organization.id.to_s }
    end

    around do |example|
      with_omniauth_full_host { example.run }
    end

    before do
      stub_omniauth_setting(enabled: true, auto_link_user: true, allow_single_sign_on: ['atlassian_oauth2'])
      stub_omniauth_setting(block_auto_created_users: false)
      mock_auth_hash('atlassian_oauth2', extern_uid, auth_email)

      read_only_organization.start_read_only!(read_only_reason: 'migration')
      read_only_organization.confirm_read_only!

      stub_feature_flags(organization_read_only_enforcement: true)
    end

    context 'when the user does not yet exist (new-user INSERT)' do
      it 'blocks creation, surfaces the read-only flash, and redirects to sign-in' do
        expect do
          post '/users/auth/atlassian_oauth2/callback', headers: organization_headers
        end.not_to change { User.count }

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to eq(
          'This organization is currently in read-only mode. ' \
            'New account creation via SSO is currently unavailable.'
        )
        expect(request.env['warden']).not_to be_authenticated
      end
    end

    context 'when the user already exists (existing-user sign-in)' do
      let_it_be(:existing_user) do
        create(:atlassian_user, extern_uid: 'read-only-uid', organization: read_only_organization)
      end

      let(:auth_email) { existing_user.email }

      it 'permits sign-in without creating a user' do
        expect do
          post '/users/auth/atlassian_oauth2/callback', headers: organization_headers
        end.not_to change { User.count }

        expect(request.env['warden']).to be_authenticated
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
