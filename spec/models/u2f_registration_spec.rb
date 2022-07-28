# frozen_string_literal: true

require 'spec_helper'

RSpec.describe U2fRegistration do
  let_it_be(:user) { create(:user) }

  let(:u2f_registration_name) { 'u2f_device' }
  let(:u2f_registration) do
    device = U2F::FakeU2F.new(FFaker::BaconIpsum.characters(5))
    create(
      :u2f_registration, name: u2f_registration_name,
      user: user,
      certificate: Base64.strict_encode64(device.cert_raw),
      key_handle: U2F.urlsafe_encode64(device.key_handle_raw),
      public_key: Base64.strict_encode64(device.origin_public_key_raw)
    )
  end

  describe 'callbacks' do
    describe 'after create' do
      shared_examples_for 'creates webauthn registration' do
        it 'creates webauthn registration' do
          webauthn_registration = WebauthnRegistration.where(u2f_registration_id: u2f_registration.id)
          expect(webauthn_registration).to exist
        end
      end

      it_behaves_like 'creates webauthn registration'

      context 'when the u2f_registration has a blank name' do
        let(:u2f_registration_name) { '' }

        it_behaves_like 'creates webauthn registration'
      end

      context 'when the u2f_registration has the name as `nil`' do
        let(:u2f_registration_name) { nil }

        it_behaves_like 'creates webauthn registration'
      end

      it 'logs error' do
        allow(Gitlab::Auth::U2fWebauthnConverter).to receive(:new).and_raise('boom!')

        allow_next_instance_of(U2fRegistration) do |u2f_registration|
          allow(u2f_registration).to receive(:id).and_return(123)
        end

        expect(Gitlab::ErrorTracking).to(
          receive(:track_exception).with(kind_of(StandardError),
                                             u2f_registration_id: 123))

        u2f_registration
      end
    end

    describe 'after update' do
      context 'when counter is updated' do
        it 'updates the webauthn registration counter to be the same value' do
          new_counter = u2f_registration.counter + 1
          webauthn_registration = WebauthnRegistration.find_by(u2f_registration_id: u2f_registration.id)

          u2f_registration.update!(counter: new_counter)

          expect(u2f_registration.reload.counter).to eq(new_counter)
          expect(webauthn_registration.reload.counter).to eq(new_counter)
        end
      end

      context 'when sign count of registration is not updated' do
        it 'does not update the counter' do
          webauthn_registration = WebauthnRegistration.find_by(u2f_registration_id: u2f_registration.id)

          expect do
            u2f_registration.update!(name: 'a new name')
          end.not_to change { webauthn_registration.counter }
        end
      end
    end
  end
end
