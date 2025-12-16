# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::WebauthnErrors, :aggregate_failures, feature_category: :system_access do
  let_it_be(:dummy_service) do
    Class.new do
      include Authn::WebauthnErrors
    end
  end

  subject(:dummy_instance) { dummy_service.new }

  using RSpec::Parameterized::TableSyntax

  describe '#webauthn_error_messages' do
    it 'returns a hash of specific webauthn device and passkey errors' do
      messages = dummy_instance.webauthn_error_messages

      expect(messages).to be_a(Hash)
      expect(messages).to be_frozen

      expect(messages.keys).to contain_exactly(
        'WebAuthn::AttestationStatementVerificationError',
        'WebAuthn::AttestedCredentialVerificationError',
        'WebAuthn::AuthenticatorDataVerificationError',
        'WebAuthn::ChallengeVerificationError',
        'WebAuthn::OriginVerificationError',
        'WebAuthn::RpIdVerificationError',
        'WebAuthn::SignatureVerificationError',
        'WebAuthn::SignCountVerificationError',
        'WebAuthn::TokenBindingVerificationError',
        'WebAuthn::TypeVerificationError',
        'WebAuthn::UserPresenceVerificationError',
        'WebAuthn::UserVerifiedVerificationError'
      )

      expect(messages.values).to all(
        have_key(:webauthn).and(have_key(:passkey))
      )
    end
  end

  describe '#webauthn_generic_error_messages' do
    it 'returns a hash of generic webauthn error messages for a webauthn device and passkey' do
      messages = dummy_instance.webauthn_generic_error_messages

      expect(messages).to be_a(Hash)
      expect(messages).to be_frozen

      expect(messages).to have_key(:webauthn)
      expect(messages).to have_key(:passkey)

      expect(messages[:webauthn]).to eq('Failed to add authentication method. Try again.')
      expect(messages[:passkey]).to eq('Failed to connect to your device. Try again.')
    end
  end

  describe '#webauthn_human_readable_errors' do
    let(:device_data_webauthn) { 'Failed to add authentication method. Try again.' }
    let(:device_data_passkey) { 'Failed to add passkey. Try again.' }
    let(:challenge_error) { 'Failed to verify WebAuthn challenge. Try again.' }
    let(:origin_error) { 'Unable to use this authentication method. Try a different authentication method.' }
    let(:rpid_error) { 'Failed to authenticate due to a configuration issue. Try again later or contact support.' }
    let(:token_binding_error) { 'Failed to verify connection security. Try adding the authentication method again.' }
    let(:type_error) { 'This authentication method is not supported. Use a different authentication method.' }
    let(:user_presence_error) { 'Failed to authenticate. Verify your identity with your device.' }
    let(:user_verified_error) { 'Failed to authenticate. Verify your identity with your device.' }
    let(:attestation_webauthn) { 'Could not verify device authenticity. Try using a different device.' }
    let(:attestation_passkey) { 'Could not verify passkey authenticity. Try using a different passkey.' }
    let(:attested_credential_webauthn) { 'Invalid credential data received. Try registering the device again.' }
    let(:attested_credential_passkey) { 'Invalid passkey data received. Try creating a new passkey.' }
    let(:signature_error) { 'Failed to verify cryptographic signature. Try authenticating again.' }
    let(:sign_count_webauthn) { 'Authenticator may have been cloned. Contact your administrator.' }
    let(:sign_count_passkey) { 'Passkey may have been cloned. Contact your administrator.' }
    let(:generic_webauthn) { 'Failed to add authentication method. Try again.' }
    let(:generic_passkey) { 'Failed to connect to your device. Try again.' }

    where(:error_message, :passkey, :expected_message) do
      'WebAuthn::AttestationStatementVerificationError' | false | ref(:attestation_webauthn)
      'WebAuthn::AttestationStatementVerificationError' | true | ref(:attestation_passkey)
      'WebAuthn::AttestedCredentialVerificationError'  | false | ref(:attested_credential_webauthn)
      'WebAuthn::AttestedCredentialVerificationError'  | true  | ref(:attested_credential_passkey)
      'WebAuthn::AuthenticatorDataVerificationError'   | false | ref(:device_data_webauthn)
      'WebAuthn::AuthenticatorDataVerificationError'   | true  | ref(:device_data_passkey)
      'WebAuthn::ChallengeVerificationError'           | false | ref(:challenge_error)
      'WebAuthn::ChallengeVerificationError'           | true  | ref(:challenge_error)
      'WebAuthn::OriginVerificationError'              | false | ref(:origin_error)
      'WebAuthn::OriginVerificationError'              | true  | ref(:origin_error)
      'WebAuthn::RpIdVerificationError'                | false | ref(:rpid_error)
      'WebAuthn::RpIdVerificationError'                | true  | ref(:rpid_error)
      'WebAuthn::SignatureVerificationError'           | false | ref(:signature_error)
      'WebAuthn::SignatureVerificationError'           | true  | ref(:signature_error)
      'WebAuthn::SignCountVerificationError'           | false | ref(:sign_count_webauthn)
      'WebAuthn::SignCountVerificationError'           | true  | ref(:sign_count_passkey)
      'WebAuthn::TokenBindingVerificationError'        | false | ref(:token_binding_error)
      'WebAuthn::TokenBindingVerificationError'        | true  | ref(:token_binding_error)
      'WebAuthn::TypeVerificationError'                | false | ref(:type_error)
      'WebAuthn::TypeVerificationError'                | true  | ref(:type_error)
      'WebAuthn::UserPresenceVerificationError'        | false | ref(:user_presence_error)
      'WebAuthn::UserPresenceVerificationError'        | true  | ref(:user_presence_error)
      'WebAuthn::UserVerifiedVerificationError'        | false | ref(:user_verified_error)
      'WebAuthn::UserVerifiedVerificationError'        | true  | ref(:user_verified_error)
      'random_string'                                   | true  | ref(:generic_passkey)
      'random_string'                                   | false | ref(:generic_webauthn)
      'random_string'                                   | nil   | ref(:generic_webauthn)
      nil                                               | false | nil
      nil                                               | true  | nil
      nil                                               | nil   | nil
    end

    with_them do
      it 'returns the appropriate error message' do
        result = dummy_instance.webauthn_human_readable_errors(error_message, passkey: passkey)

        expect(result).to eq(expected_message)
      end
    end
  end
end
