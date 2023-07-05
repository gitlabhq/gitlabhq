# frozen_string_literal: true

require 'spec_helper'
require 'webauthn/fake_client'

RSpec.describe Webauthn::RegisterService, feature_category: :system_access do
  let(:client) { WebAuthn::FakeClient.new(origin) }
  let(:user) { create(:user) }
  let(:challenge) { Base64.strict_encode64(SecureRandom.random_bytes(32)) }

  let(:origin) { 'http://localhost' }

  describe '#execute' do
    it 'returns a registration if challenge matches' do
      create_result = client.create(challenge: challenge) # rubocop:disable Rails/SaveBang
      webauthn_credential = WebAuthn::Credential.from_create(create_result)

      params = { device_response: create_result.to_json, name: 'abc' }
      service = described_class.new(user, params, challenge)

      registration = service.execute
      expect(registration.credential_xid).to eq(Base64.strict_encode64(webauthn_credential.raw_id))
      expect(registration.errors.size).to eq(0)
    end

    it 'returns an error if challenge does not match' do
      create_result = client.create(challenge: Base64.strict_encode64(SecureRandom.random_bytes(16))) # rubocop:disable Rails/SaveBang

      params = { device_response: create_result.to_json, name: 'abc' }
      service = described_class.new(user, params, challenge)

      registration = service.execute
      expect(registration.errors.size).to eq(1)
    end
  end
end
