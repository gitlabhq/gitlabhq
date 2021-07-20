# frozen_string_literal: true

require 'spec_helper'

RSpec.describe U2fRegistration do
  let_it_be(:user) { create(:user) }

  let(:u2f_registration) do
    device = U2F::FakeU2F.new(FFaker::BaconIpsum.characters(5))
    create(:u2f_registration, name: 'u2f_device',
                              user: user,
                              certificate: Base64.strict_encode64(device.cert_raw),
                              key_handle: U2F.urlsafe_encode64(device.key_handle_raw),
                              public_key: Base64.strict_encode64(device.origin_public_key_raw))
  end

  describe 'callbacks' do
    describe '#create_webauthn_registration' do
      it 'creates webauthn registration' do
        u2f_registration.save!

        webauthn_registration = WebauthnRegistration.where(u2f_registration_id: u2f_registration.id)
        expect(webauthn_registration).to exist
      end

      it 'logs error' do
        allow(Gitlab::Auth::U2fWebauthnConverter).to receive(:new).and_raise('boom!')
        expect(Gitlab::AppJsonLogger).to(
          receive(:error).with(a_hash_including(event: 'u2f_migration',
                                                error: 'RuntimeError',
                                                message: 'U2F to WebAuthn conversion failed'))
        )

        u2f_registration.save!
      end
    end
  end
end
