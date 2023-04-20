# frozen_string_literal: true

require 'spec_helper'

RSpec.describe U2fRegistration do
  let_it_be(:user) { create(:user) }

  let(:u2f_registration_name) { 'u2f_device' }
  let(:app_id) { FFaker::BaconIpsum.characters(5) }
  let(:device) { U2F::FakeU2F.new(app_id) }

  describe '.authenticate' do
    context 'when registration is found' do
      it 'returns true' do
        create_u2f_registration
        device_challenge = U2F.urlsafe_encode64(SecureRandom.random_bytes(32))
        sign_response_json = device.sign_response(device_challenge)

        response = U2fRegistration.authenticate(
          user,
          app_id,
          sign_response_json,
          device_challenge
        )

        expect(response).to eq true
      end
    end

    context 'when registration not found' do
      it 'returns nil' do
        device_challenge = U2F.urlsafe_encode64(SecureRandom.random_bytes(32))
        sign_response_json = device.sign_response(device_challenge)

        # data is valid but user does not have any u2f_registrations
        response = U2fRegistration.authenticate(
          user,
          app_id,
          sign_response_json,
          device_challenge
        )

        expect(response).to eq nil
      end
    end

    context 'when args passed in are invalid' do
      it 'returns false' do
        some_app_id = 123
        invalid_json = 'invalid JSON'
        challenges = 'whatever'

        response = U2fRegistration.authenticate(
          user,
          some_app_id,
          invalid_json,
          challenges
        )

        expect(response).to eq false
      end
    end
  end

  def create_u2f_registration
    create(
      :u2f_registration,
      name: u2f_registration_name,
      user: user,
      certificate: Base64.strict_encode64(device.cert_raw),
      key_handle: U2F.urlsafe_encode64(device.key_handle_raw),
      public_key: Base64.strict_encode64(device.origin_public_key_raw)
    )
  end
end
