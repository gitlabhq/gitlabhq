# frozen_string_literal: true

require 'spec_helper'
require 'webauthn/fake_client'

RSpec.describe Webauthn::AuthenticateService, feature_category: :system_access do
  let(:client) { WebAuthn::FakeClient.new(origin) }
  let(:user) { create(:user) }
  let(:challenge) { Base64.strict_encode64(SecureRandom.random_bytes(32)) }

  let(:origin) { 'http://localhost' }

  before do
    create_result = client.create(challenge: challenge) # rubocop:disable Rails/SaveBang

    webauthn_credential = WebAuthn::Credential.from_create(create_result)

    registration = WebauthnRegistration.new(
      credential_xid: Base64.strict_encode64(webauthn_credential.raw_id),
      public_key: webauthn_credential.public_key,
      counter: 0,
      name: 'name',
      user_id: user.id
    )
    registration.save!
  end

  describe '#execute' do
    it 'returns true if the response is valid and a matching stored credential is present' do
      get_result = client.get(challenge: challenge)

      get_result['clientExtensionResults'] = {}
      service = described_class.new(user, get_result.to_json, challenge)

      expect(service.execute).to eq true
    end

    context 'when response is valid but no matching stored credential is present' do
      it 'returns false' do
        other_client = WebAuthn::FakeClient.new(origin)
        other_client.create(challenge: challenge) # rubocop:disable Rails/SaveBang

        get_result = other_client.get(challenge: challenge)

        get_result['clientExtensionResults'] = {}
        service = described_class.new(user, get_result.to_json, challenge)

        expect(service.execute).to eq false
      end
    end

    context 'when device response includes invalid json' do
      it 'returns false' do
        service = described_class.new(user, 'invalid JSON', '')
        expect(service.execute).to eq false
      end
    end
  end
end
