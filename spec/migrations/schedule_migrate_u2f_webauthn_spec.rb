# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleMigrateU2fWebauthn do
  let(:migration_name) { described_class::MIGRATION }
  let(:u2f_registrations) { table(:u2f_registrations) }
  let(:webauthn_registrations) { table(:webauthn_registrations) }

  let(:users) { table(:users) }

  let(:user) { users.create!(email: 'email@email.com', name: 'foo', username: 'foo', projects_limit: 0) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)
  end

  context 'when there are u2f registrations' do
    let!(:u2f_reg_1) { create_u2f_registration(1, 'reg1') }
    let!(:u2f_reg_2) { create_u2f_registration(2, 'reg2') }

    it 'schedules a background migration' do
      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(migration_name).to be_scheduled_delayed_migration(2.minutes, 1, 1)
          expect(migration_name).to be_scheduled_delayed_migration(4.minutes, 2, 2)
          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end
  end

  context 'when there are no u2f registrations' do
    it 'does not schedule background migrations' do
      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(BackgroundMigrationWorker.jobs.size).to eq(0)
        end
      end
    end
  end

  def create_u2f_registration(id, name)
    device = U2F::FakeU2F.new(FFaker::BaconIpsum.characters(5))
    u2f_registrations.create!({ id: id,
                                certificate: Base64.strict_encode64(device.cert_raw),
                                key_handle: U2F.urlsafe_encode64(device.key_handle_raw),
                                public_key: Base64.strict_encode64(device.origin_public_key_raw),
                                counter: 5,
                                name: name,
                                user_id: user.id })
  end
end
