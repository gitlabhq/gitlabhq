# frozen_string_literal: true

require 'spec_helper'
require 'webauthn/fake_client'

RSpec.describe Webauthn::AuthenticateService, feature_category: :system_access do
  let_it_be_with_reload(:user) { create(:user) }

  # WebAuthn Request Options (from GitLab and stored in session store)
  let(:challenge) { Base64.strict_encode64(SecureRandom.random_bytes(32)) }
  let(:origin) { 'http://localhost' }

  # Setup authenticator (from user & browser)
  let(:client) { WebAuthn::FakeClient.new(origin) }

  # Registration Response
  let(:registration_challenge) { Base64.strict_encode64(SecureRandom.random_bytes(32)) }
  let(:webauthn_creation_result) do
    client.create( # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
      challenge: challenge,
      extensions: {}
    )
  end

  # Immediately save the registration
  let!(:webauthn_registration) do
    webauthn_credential = WebAuthn::Credential.from_create(webauthn_creation_result)

    WebauthnRegistration.create!(
      credential_xid: Base64.strict_encode64(webauthn_credential.raw_id),
      public_key: webauthn_credential.public_key,
      counter: 1,
      name: 'My WebAuthn Authenticator',
      user: user
    )
  end

  # Authentication Response
  let(:webauthn_authenticate_result) do
    client.get(
      challenge: challenge,
      sign_count: webauthn_registration.counter + 1, # A valid authenticator sign_count increments or doesn't change
      allow_credentials: user.second_factor_webauthn_registrations.pluck(:credential_xid),
      extensions: {}
    )
  end

  let!(:webauthn_credential) { WebAuthn::Credential.from_get(webauthn_authenticate_result) }
  let(:device_response) { webauthn_authenticate_result.to_json }

  # Main service
  subject(:authenticate_service) { described_class.new(user, device_response, challenge).execute }

  describe '#execute' do
    context 'with valid authentications' do
      let(:encoded_raw_id) { Base64.strict_encode64(webauthn_credential.raw_id) }
      let(:stored_webauthn_credential) do
        described_class.new(user, device_response, challenge)
          .send(:stored_passkey_or_second_factor_webauthn_credential, encoded_raw_id)
      end

      it 'returns true when the challenge matches' do
        expect(authenticate_service).to be_truthy
      end

      it 'updates the required webauthn_registration columns' do
        authenticate_service

        expect(stored_webauthn_credential.counter).to eq(webauthn_credential.sign_count)
        expect(stored_webauthn_credential.last_used_at).to be_present
      end

      context 'with a U2F migrated credential' do
        let(:webauthn_authenticate_result) do
          client.get(
            challenge: challenge,
            sign_count: webauthn_registration.counter + 1,
            extensions: { "app_id" => "http://localhost.ca" }
          )
        end

        it 'authenticates successfully' do
          expect(authenticate_service).to be_truthy
        end
      end

      context 'with passkeys' do
        let(:passkey_creation_result) do
          client.create( # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
            challenge: challenge,
            extensions: { "credProps" => { "rk" => true } }
          )
        end

        # Override the webauthn registration & authentication to work as a passkey
        let!(:webauthn_registration) do
          passkey_credential = WebAuthn::Credential.from_create(passkey_creation_result)

          WebauthnRegistration.create!(
            credential_xid: Base64.strict_encode64(passkey_credential.raw_id),
            public_key: passkey_credential.public_key,
            counter: 1,
            name: 'My WebAuthn Authenticator (Passkey)',
            user: user,
            authentication_mode: :passwordless,
            passkey_eligible: true
          )
        end

        let(:webauthn_authenticate_result) do
          client.get(
            challenge: challenge,
            sign_count: webauthn_registration.counter + 1,
            allow_credentials: user.passkeys.pluck(:credential_xid),
            extensions: { "credProps" => { "rk" => true } }
          )
        end

        context 'when the :passkeys Feature Flag is enabled' do
          it 'returns a passkey credential first, if available' do
            authenticate_service

            expect(stored_webauthn_credential.authentication_mode).to eq("passwordless")
          end
        end

        context 'when the :passkeys Feature Flag is disabled' do
          before do
            stub_feature_flags(passkeys: false)
          end

          it 'omits passkey credentials' do
            authenticate_service

            expect(stored_webauthn_credential).to be_nil
          end
        end
      end
    end

    context 'with invalid authentications' do
      shared_examples 'returns authentication failure' do
        it 'returns false' do
          expect(authenticate_service).to be_falsy
        end
      end

      context 'with a tampered challenge from the browser' do
        let(:compromised_challenge) { Base64.strict_encode64(SecureRandom.random_bytes(16)) }
        let(:webauthn_authenticate_result) do
          client.get(
            challenge: compromised_challenge,
            sign_count: webauthn_registration.counter
          )
        end

        it_behaves_like 'returns authentication failure'
      end

      context 'with invalid JSON response' do
        let(:device_response) { 'bad response' }

        it_behaves_like 'returns authentication failure'
      end

      context 'with a cloned authenticator' do
        let(:webauthn_authenticate_result) do
          client.get(
            challenge: challenge,
            sign_count: webauthn_registration.counter - 1
          )
        end

        it_behaves_like 'returns authentication failure'
      end

      context 'with a non-existent authenticator (not stored in GitLab)' do
        let(:different_client) { WebAuthn::FakeClient.new(origin) }

        let(:webauthn_creation_result) do
          different_client.create( # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
            challenge: registration_challenge
          )
        end

        let(:webauthn_authenticate_result) do
          different_client.get(
            challenge: challenge,
            sign_count: 1,
            allow_credentials: user.second_factor_webauthn_registrations.pluck(:credential_xid)
          )
        end

        it_behaves_like 'returns authentication failure'
      end
    end
  end
end
