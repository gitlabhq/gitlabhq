# frozen_string_literal: true

require 'spec_helper'
require 'webauthn/fake_client'

RSpec.describe Authn::Passkey::AuthenticateService, feature_category: :system_access do
  let_it_be_with_reload(:user) { create(:user) }

  # WebAuthn Request Options (from GitLab and stored in session store)
  let(:challenge) { Base64.strict_encode64(SecureRandom.random_bytes(32)) }
  let(:origin) { 'http://localhost' }

  # Setup authenticator (from user & browser)
  let(:client) { WebAuthn::FakeClient.new(origin) }

  # Registration Response (passkey creation first)
  let(:registration_challenge) { Base64.strict_encode64(SecureRandom.random_bytes(32)) }
  let(:webauthn_creation_result) do
    client.create( # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
      challenge: registration_challenge,
      user_verified: true,
      extensions: { "credProps" => { "rk" => true } }
    )
  end

  # Immediately save the registration
  let!(:passkey_registration) do
    passkey_credential = WebAuthn::Credential.from_create(webauthn_creation_result)

    WebauthnRegistration.create!(
      credential_xid: Base64.strict_encode64(passkey_credential.raw_id),
      public_key: passkey_credential.public_key,
      counter: 1,
      name: 'My WebAuthn Authenticator (Passkey)',
      user: user,
      authentication_mode: :passwordless,
      passkey_eligible: true,
      last_used_at: Time.current
    )
  end

  # Authentication Response
  let(:webauthn_authenticate_result) do
    client.get(
      challenge: challenge,
      sign_count: passkey_registration.counter + 1,
      allow_credentials: user.passkeys.pluck(:credential_xid), # `[]` in grpd for browser to auto-"discover" credentials
      extensions: { "credProps" => { "rk" => true } }
    )
  end

  let(:webauthn_credential) { WebAuthn::Credential.from_get(webauthn_authenticate_result) }
  let(:device_response) { webauthn_authenticate_result.to_json }

  # Main service
  subject(:authenticate_service) { described_class.new(device_response, challenge).execute }

  describe '#execute' do
    shared_examples 'returns authentication failure' do
      it 'returns a Service.error' do
        expect(authenticate_service).to be_a(ServiceResponse)
        expect(authenticate_service).to be_error
        expect(authenticate_service.message).to be_present
      end
    end

    shared_examples 'returns authentication success' do
      it 'returns a Service.success' do
        expect(authenticate_service).to be_a(ServiceResponse)
        expect(authenticate_service).to be_success
      end
    end

    context 'with valid authentications' do
      let(:stored_webauthn_credential) { authenticate_service.payload.passkeys.first }

      it_behaves_like 'returns authentication success'

      it 'returns the user when the challenge matches' do
        expect(authenticate_service.payload).to eq(user)
      end

      it 'updates the required webauthn_registration columns' do
        expect(stored_webauthn_credential.counter).to eq(webauthn_credential.sign_count)
        expect(passkey_registration.last_used_at).to be_present
      end

      it 'authenticates with a passkey (passwordless sign_in)' do
        authenticate_service

        expect(passkey_registration.authentication_mode).to eq('passwordless')
      end
    end

    context 'with invalid authentications' do
      context 'with a tampered challenge from the browser' do
        let(:compromised_challenge) { Base64.strict_encode64(SecureRandom.random_bytes(16)) }

        let(:webauthn_authenticate_result) do
          client.get(
            challenge: compromised_challenge,
            sign_count: passkey_registration.counter + 1,
            allow_credentials: user.passkeys.pluck(:credential_xid),
            extensions: { "credProps" => { "rk" => true } }
          )
        end

        it_behaves_like 'returns authentication failure'
      end

      context 'with an invalid JSON response' do
        let(:device_response) { 'bad response' }

        it_behaves_like 'returns authentication failure'
      end

      context 'with a wrong origin (rpID)' do
        context 'with a cloned authenticator' do
          let(:webauthn_authenticate_result) do
            client.get(
              challenge: challenge,
              sign_count: passkey_registration.counter - 1,
              allow_credentials: user.passkeys.pluck(:credential_xid),
              extensions: { "credProps" => { "rk" => true } }
            )
          end

          it_behaves_like 'returns authentication failure'
        end

        context 'with a non-existent authenticator' do
          let(:different_client) { WebAuthn::FakeClient.new(origin) }

          let(:webauthn_creation_result) do
            different_client.create( # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
              challenge: registration_challenge,
              user_verified: true,
              extensions: { "credProps" => { "rk" => true } }
            )
          end

          let(:webauthn_authenticate_result) do
            different_client.get(
              challenge: challenge,
              sign_count: 1,
              allow_credentials: user.passkeys.pluck(:credential_xid),
              extensions: { "credProps" => { "rk" => true } }
            )
          end

          it_behaves_like 'returns authentication failure'
        end
      end

      context 'with a user trying to sign-in with a passkey, without having registered one' do
        let(:device_response) do
          create_response = client.create(challenge: challenge) # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
          credential_id = create_response["rawId"]

          create(:webauthn_registration,
            credential_xid: credential_id,
            user: user
          )

          webauthn_authenticate_result = client.get(
            challenge: challenge,
            sign_count: 1,
            allow_credentials: [credential_id]
          )

          webauthn_authenticate_result.to_json
        end

        it_behaves_like 'returns authentication failure'

        it 'returns an error message with a hyperlink to the passkey page' do
          expect(authenticate_service.message).to be_html_safe
          expect(authenticate_service.message).to include(
            'passkeys.md#add-a-passkey">setting up passkeys</a>.'
          )
        end
      end
    end
  end
end
