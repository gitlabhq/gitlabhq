# frozen_string_literal: true

require 'spec_helper'
require 'webauthn/fake_client'

RSpec.describe Webauthn::RegisterService, feature_category: :system_access do
  let_it_be_with_reload(:user) { create(:user) }

  # WebAuthn Request Options (from GitLab and stored in session store)
  let(:challenge) { Base64.strict_encode64(SecureRandom.random_bytes(32)) }
  let(:origin) { 'http://localhost' }

  # Setup authenticator (from user & browser)
  let(:client) { WebAuthn::FakeClient.new(origin) }

  # Response
  let(:webauthn_creation_result) { client.create(challenge: challenge) } # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
  let(:device_response) { webauthn_creation_result.to_json }
  let(:device_name) { 'My WebAuthn Authenticator' }
  let(:params) { { device_response: device_response, name: device_name } }

  # Main service
  subject(:register_service) { described_class.new(user, params, challenge).execute }

  describe '#execute' do
    context 'with valid registrations' do
      let(:webauthn_credential) { WebAuthn::Credential.from_create(Gitlab::Json.parse(params[:device_response])) }

      it 'returns a registration if the challenge matches' do
        expect(register_service.credential_xid).to eq(Base64.strict_encode64(webauthn_credential.raw_id))
        expect(register_service.errors.size).to eq(0)
      end

      it 'updates the required webauthn_registration columns' do
        registration = register_service

        expect(registration.public_key).to eq(webauthn_credential.public_key)
        expect(registration.counter).to eq(webauthn_credential.sign_count)
        expect(registration.name).to eq(device_name)
        expect(registration.user).to eq(user)
        expect(registration.last_used_at).to be_present
      end

      context 'with a passkey-eligible authenticator' do
        let(:webauthn_creation_result) do
          client.create( # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
            challenge: challenge,
            extensions: { "credProps" => { "rk" => true } }
          )
        end

        it 'sets passkey_eligible to true' do
          expect(register_service.passkey_eligible).to be_truthy
        end
      end

      context 'with a non passkey-eligible authenticator' do
        let(:webauthn_creation_result) do
          client.create( # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
            challenge: challenge,
            extensions: { "credProps" => { "rk" => false } }
          )
        end

        it 'sets passkey_eligible to false' do
          expect(register_service.passkey_eligible).to be_falsy
        end
      end
    end

    context 'with invalid registrations' do
      shared_examples 'returns a WebAuthn error' do
        it 'returns a WebAuthn or a sub_error class' do
          expect(register_service.errors[:base]).to be_present
        end
      end

      context 'with a tampered challenge from the browser' do
        let(:compromised_challenge) { Base64.strict_encode64(SecureRandom.random_bytes(16)) }

        let(:webauthn_creation_result) do
          client.create(challenge: compromised_challenge) # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
        end

        it_behaves_like 'returns a WebAuthn error'
      end

      context 'with an invalid JSON response' do
        let(:device_response) { 'bad response' }

        it 'returns JSON parsing error' do
          expect(register_service.errors[:base]).to include(
            _('Your WebAuthn device did not send a valid JSON response.')
          )
        end

        it_behaves_like 'returns a WebAuthn error'
      end

      context 'with a tampered origin (origin spoofing)' do
        let(:webauthn_creation_result) do
          client.create( # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
            challenge: challenge,
            rp_id: 'localhost_origin_spoofed'
          )
        end

        it_behaves_like 'returns a WebAuthn error'
      end
    end
  end
end
