# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::U2fWebauthnConverter do
  let_it_be(:u2f_registration) do
    device = U2F::FakeU2F.new(FFaker::BaconIpsum.characters(5))
    create(:u2f_registration, name: 'u2f_device',
                              certificate: Base64.strict_encode64(device.cert_raw),
                              key_handle: U2F.urlsafe_encode64(device.key_handle_raw),
                              public_key: Base64.strict_encode64(device.origin_public_key_raw))
  end

  it 'converts u2f registration' do
    webauthn_credential = WebAuthn::U2fMigrator.new(
      app_id: Gitlab.config.gitlab.url,
      certificate: u2f_registration.certificate,
      key_handle: u2f_registration.key_handle,
      public_key: u2f_registration.public_key,
      counter: u2f_registration.counter
    ).credential

    converted_webauthn = described_class.new(u2f_registration).convert

    expect(converted_webauthn).to(
      include(user_id: u2f_registration.user_id,
              credential_xid: Base64.strict_encode64(webauthn_credential.id)))
  end
end
