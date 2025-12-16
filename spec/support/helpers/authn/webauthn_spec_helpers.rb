# frozen_string_literal: true

# These helpers allow you to easily test webauthn implementations
#
require 'webauthn/fake_client'

module Authn
  module WebauthnSpecHelpers
    def create_passkey(user)
      webauthn_creation_result = client.create( # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
        challenge: challenge, extensions: { "credProps" => { "rk" => true } }
      )

      passkey_credential = WebAuthn::Credential.from_create(webauthn_creation_result)

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

    # Mimick device response from browser to GitLab after a user completes authentication
    #
    def device_response_after_authentication(user, webauthn_credential)
      is_passkey = webauthn_credential.authentication_mode == :passwordless

      webauthn_authenticate_result = client.get(
        challenge: challenge,
        sign_count: webauthn_credential.counter + 1,
        allow_credentials: user.get_all_webauthn_credential_ids,
        extensions: { "credProps" => { "rk" => is_passkey } }
      )
      webauthn_authenticate_result.to_json
    end

    private

    def client
      @client ||= WebAuthn::FakeClient.new(origin)
    end

    def origin
      @origin ||= 'http://localhost'
    end

    def challenge
      @challenge ||= Base64.strict_encode64(SecureRandom.random_bytes(32))
    end
  end
end
