# frozen_string_literal: true

require 'spec_helper'
require 'webauthn/fake_client'

RSpec.describe Authn::Passkey::RegisterService, feature_category: :system_access do
  let_it_be_with_reload(:user) { create(:user) }

  # WebAuthn Request Options (from GitLab and stored in session store)
  let(:challenge) { Base64.strict_encode64(SecureRandom.random_bytes(32)) }
  let(:origin) { 'http://localhost' }

  # Setup authenticator (from user & browser)
  let(:client) { WebAuthn::FakeClient.new(origin) }

  # Response
  let(:webauthn_creation_result) do
    client.create( # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
      challenge: challenge,
      extensions: { "credProps" => { "rk" => true } },
      user_verified: true
    )
  end

  let(:device_response) { webauthn_creation_result.to_json }
  let(:device_name) { 'My WebAuthn Authenticator (Passkey)' }
  let(:params) { { device_response: device_response, name: device_name } }

  describe '#execute' do
    subject(:execute) { described_class.new(user, params, challenge).execute }

    shared_examples 'returns registration failure' do |message:|
      it 'does not send notification email' do
        allow(NotificationService).to receive(:new)
        expect(NotificationService).not_to receive(:new)

        execute
      end

      it 'returns a ServiceResponse.error with message' do
        expect(execute).to be_a(ServiceResponse)
        expect(execute).to be_error
        expect(execute.message).to be_present
        expect(execute.message).to match(message)
      end
    end

    shared_examples 'returns registration success' do
      it 'updates the required webauthn_registration columns' do
        registration = execute.payload

        expect(registration.credential_xid).to eq(Base64.strict_encode64(webauthn_credential.raw_id))
        expect(registration.public_key).to eq(webauthn_credential.public_key)
        expect(registration.counter).to eq(webauthn_credential.sign_count)
        expect(registration.name).to eq(device_name)
        expect(registration.user).to eq(user)
        expect(registration.authentication_mode).to eq("passwordless")
        expect(registration.passkey_eligible).to be_truthy
        expect(registration.last_used_at).to be_present
      end

      it 'sends the user notification email' do
        expect_next_instance_of(NotificationService) do |notification|
          expect(notification).to receive(:enabled_two_factor).with(
            user, :passkey, { device_name: device_name }
          )
        end

        execute
      end

      it 'returns a ServiceResponse.success with message' do
        expect(execute).to be_a(ServiceResponse)
        expect(execute).to be_success
        expect(execute.message).to be_present
        expect(execute.message).to match('Passkey added successfully!')
      end
    end

    context 'with valid registrations' do
      let(:webauthn_credential) { WebAuthn::Credential.from_create(Gitlab::Json.safe_parse(params[:device_response])) }

      it_behaves_like 'returns registration success'

      # As per https://www.w3.org/TR/webauthn/#dom-credentialpropertiesoutput-rk,
      # credProps["rk"] is OPTIONAL and some authenticators may not report it.
      context 'when the credential is passkey eligible, but do not provide credProps["rk"]' do
        let(:webauthn_creation_result) do
          client.create( # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
            challenge: challenge,
            extensions: { "credProps" => {} },
            user_verified: true
          )
        end

        it_behaves_like 'returns registration success'
      end
    end

    context 'with invalid registrations' do
      context 'with a tampered challenge from the browser' do
        let(:compromised_challenge) { Base64.strict_encode64(SecureRandom.random_bytes(16)) }

        let(:webauthn_creation_result) do
          client.create( # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
            challenge: compromised_challenge,
            extensions: { "credProps" => { "rk" => true } },
            user_verified: true
          )
        end

        it_behaves_like 'returns registration failure', message: 'Failed to verify WebAuthn challenge. Try again.'
      end

      context 'without user presence' do
        let(:webauthn_creation_result) do
          client.create( # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
            challenge: challenge,
            extensions: { "credProps" => { "rk" => true } },
            user_verified: false,
            user_present: false
          )
        end

        it_behaves_like 'returns registration failure',
          message: 'Failed to authenticate. Verify your identity with your device.'
      end

      context 'when user verification was not performed' do
        let(:webauthn_creation_result) do
          client.create( # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
            challenge: challenge,
            extensions: { "credProps" => { "rk" => true } },
            user_verified: false
          )
        end

        it_behaves_like 'returns registration failure',
          message: 'Failed to authenticate. Verify your identity with your device.'
      end

      context 'with an invalid JSON response' do
        let(:device_response) { 'bad response' }

        it_behaves_like 'returns registration failure', message: 'Your passkey did not send a valid JSON response.'
      end

      context 'with a tampered origin (origin spoofing)' do
        let(:webauthn_creation_result) do
          client.create( # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
            challenge: challenge,
            rp_id: 'localhost_origin_spoofed',
            extensions: { "credProps" => { "rk" => true } },
            user_verified: true
          )
        end

        it_behaves_like 'returns registration failure',
          message: 'Failed to authenticate due to a configuration issue. Try again later or contact support.'
      end

      context 'with an invalid device name' do
        let(:device_name) { nil }

        it_behaves_like 'returns registration failure',
          message: 'Validation failed: Name is too short (minimum is 0 characters)'
      end

      context 'when the credential is not passkey eligible' do
        let(:webauthn_creation_result) do
          client.create( # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
            challenge: challenge,
            extensions: { "credProps" => { "rk" => false } },
            user_verified: true
          )
        end

        it_behaves_like 'returns registration failure',
          message: 'Validation failed: This credential is not passkey eligible'
      end
    end
  end
end
