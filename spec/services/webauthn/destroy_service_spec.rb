# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Webauthn::DestroyService, feature_category: :system_access do
  let(:user) { create(:user, :two_factor_via_webauthn, registrations_count: 1) }
  let(:current_user) { user }

  describe '#execute' do
    let(:webauthn_registration) { user.second_factor_webauthn_registrations.first }
    let(:webauthn_id) { webauthn_registration.id }
    let(:webauthn_name) { webauthn_registration.name }

    subject { described_class.new(current_user, user, webauthn_id).execute }

    context 'with only one webauthn method enabled' do
      context 'when another user is calling the service' do
        context 'for a user without permissions' do
          before do
            allow(NotificationService).to receive(:new)
          end

          let(:current_user) { create(:user) }

          it 'does not destry the webauthn registration' do
            expect { subject }.not_to change { user.second_factor_webauthn_registrations.count }
          end

          it 'does not remove the user backup codes' do
            expect { subject }.not_to change { user.otp_backup_codes }
          end

          it 'returns error' do
            expect(subject[:status]).to eq(:error)
          end

          it 'does not send a notification email' do
            subject
            expect(NotificationService).not_to have_received(:new)
          end
        end

        context 'for an admin' do
          it 'destroys the webauthn registration' do
            expect { subject }.to change { user.second_factor_webauthn_registrations.count }.by(-1)
          end

          it 'removes the user backup codes' do
            subject

            expect(user.otp_backup_codes).to be_nil
          end

          it 'sends the user notification emails' do
            expect_next_instance_of(NotificationService) do |notification|
              expect(notification).to receive(:disabled_two_factor).with(user, :webauthn,
                { device_name: webauthn_name })
            end

            expect_next_instance_of(NotificationService) do |notification_service|
              expect(notification_service).to receive(:disabled_two_factor).with(user)
            end

            subject
          end
        end
      end

      context 'when current user is calling the service' do
        it 'removes the webauth registrations' do
          expect { subject }.to change { user.second_factor_webauthn_registrations.count }.by(-1)
        end

        it 'removes the user backup codes' do
          subject
          expect(user.otp_backup_codes).to be_nil
        end

        it 'sends the user notification emails' do
          expect_next_instance_of(NotificationService) do |notification_service|
            expect(notification_service).to receive(:disabled_two_factor).with(user, :webauthn,
              { device_name: webauthn_name })
          end

          expect_next_instance_of(NotificationService) do |notification_service|
            expect(notification_service).to receive(:disabled_two_factor).with(user)
          end

          subject
        end

        context 'when there is also OTP enabled' do
          before do
            user.otp_required_for_login = true
            user.otp_secret = User.generate_otp_secret(32)
            user.otp_grace_period_started_at = Time.current
            user.generate_otp_backup_codes!
            user.save!
          end

          it 'removes the webauth registrations' do
            expect { subject }.to change { user.second_factor_webauthn_registrations.count }.by(-1)
          end

          it 'does not remove the user backup codes' do
            expect { subject }.not_to change { user.otp_backup_codes }
          end

          it 'sends the user a notification email' do
            expect_next_instance_of(NotificationService) do |notification|
              expect(notification).to receive(:disabled_two_factor).with(user, :webauthn,
                { device_name: webauthn_name })
            end

            expect(NotificationService).not_to receive(:new)

            subject
          end
        end
      end
    end

    context 'with multiple webauthn methods enabled' do
      before do
        create(:webauthn_registration, user: user)
      end

      it 'destroys the webauthn registration' do
        expect { subject }.to change { user.second_factor_webauthn_registrations.count }.by(-1)
      end

      it 'does not remove the user backup codes' do
        expect { subject }.not_to change { user.otp_backup_codes }
      end

      it 'sends the user a notification email' do
        expect_next_instance_of(NotificationService) do |notification|
          expect(notification).to receive(:disabled_two_factor).with(user, :webauthn,
            { device_name: webauthn_name })
        end

        expect(NotificationService).not_to receive(:new)

        subject
      end
    end
  end
end
