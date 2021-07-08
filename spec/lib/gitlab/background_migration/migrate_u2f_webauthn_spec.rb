# frozen_string_literal: true

require 'spec_helper'

require 'webauthn/u2f_migrator'

RSpec.describe Gitlab::BackgroundMigration::MigrateU2fWebauthn, :migration, schema: 20200925125321 do
  let(:users) { table(:users) }

  let(:user) { users.create!(email: 'email@email.com', name: 'foo', username: 'foo', projects_limit: 0) }

  let(:u2f_registrations) { table(:u2f_registrations) }
  let(:webauthn_registrations) { table(:webauthn_registrations) }

  let!(:u2f_registration_not_migrated) { create_u2f_registration(1, 'reg1') }
  let!(:u2f_registration_not_migrated_no_name) { create_u2f_registration(2, nil, 2) }
  let!(:u2f_registration_migrated) { create_u2f_registration(3, 'reg3') }

  subject { described_class.new.perform(1, 3) }

  before do
    converted_credential = convert_credential_for(u2f_registration_migrated)
    webauthn_registrations.create!(converted_credential)
  end

  it 'migrates all records' do
    expect { subject }.to change { webauthn_registrations.count }.from(1).to(3)

    all_webauthn_registrations = webauthn_registrations.all.map(&:attributes)

    [u2f_registration_not_migrated, u2f_registration_not_migrated_no_name].each do |u2f_registration|
      expected_credential = convert_credential_for(u2f_registration).except(:created_at).stringify_keys
      expect(all_webauthn_registrations).to include(a_hash_including(expected_credential))
    end
  end

  def create_u2f_registration(id, name, counter = 5)
    device = U2F::FakeU2F.new(FFaker::BaconIpsum.characters(5))
    u2f_registrations.create!({ id: id,
                                certificate: Base64.strict_encode64(device.cert_raw),
                                key_handle: U2F.urlsafe_encode64(device.key_handle_raw),
                                public_key: Base64.strict_encode64(device.origin_public_key_raw),
                                counter: counter,
                                name: name,
                                user_id: user.id })
  end

  def convert_credential_for(u2f_registration)
    converted_credential = WebAuthn::U2fMigrator.new(
      app_id: Gitlab.config.gitlab.url,
      certificate: u2f_registration.certificate,
      key_handle: u2f_registration.key_handle,
      public_key: u2f_registration.public_key,
      counter: u2f_registration.counter
    ).credential

    {
        credential_xid: Base64.strict_encode64(converted_credential.id),
        public_key: Base64.strict_encode64(converted_credential.public_key),
        counter: u2f_registration.counter,
        name: u2f_registration.name || '',
        user_id: u2f_registration.user_id,
        u2f_registration_id: u2f_registration.id,
        created_at: u2f_registration.created_at
    }
  end
end
