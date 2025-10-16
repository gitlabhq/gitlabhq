# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TwoFactor::DestroyOtpService, feature_category: :system_access do
  let_it_be(:current_user) { create(:user) }

  subject(:execute) { described_class.new(current_user, user: user).execute }

  context 'when disabling the OTP authenticator' do
    context 'when the user does not have two-factor authentication enabled' do
      before do
        allow(NotificationService).to receive(:new)
      end

      let(:user) { current_user }

      it 'returns error' do
        expect(execute).to eq(
          {
            status: :error,
            message: _('This user does not have a one-time password authenticator registered.')
          }
        )
      end

      it 'does not send a notification email' do
        execute
        expect(NotificationService).not_to have_received(:new)
      end
    end

    context 'when the user has two-factor authentication enabled' do
      context 'when the executor is not authorized to disable the OTP authenticator' do
        context 'when disabling the OTP authenticator of another user' do
          before do
            allow(NotificationService).to receive(:new)
          end

          let(:user) { create(:user, :two_factor_via_otp) }

          it 'returns error' do
            expect(execute).to eq(
              {
                status: :error,
                message: _('You are not authorized to perform this action')
              }
            )
          end

          it 'does not disable the OTP authenticator' do
            expect { execute }.not_to change { user.reload.two_factor_otp_enabled? }.from(true)
          end

          it 'does not send a notification email' do
            execute
            expect(NotificationService).not_to have_received(:new)
          end
        end
      end

      context 'when the executor is authorized to disable the OTP authenticator' do
        shared_examples_for 'disables OTP authenticator' do
          it 'returns success' do
            expect(execute).to include({ status: :success })
          end

          it 'disables the OTP authenticator of the user' do
            expect { execute }.to change { user.reload.two_factor_otp_enabled? }.from(true).to(false)
          end
        end

        context 'when disabling their own OTP authenticator' do
          context 'when only OTP is enabled' do
            let(:current_user) { create(:user, :two_factor_via_otp) }
            let(:user) { current_user }

            it_behaves_like 'disables OTP authenticator'

            it 'removes the user backup codes' do
              execute
              expect(user.otp_backup_codes).to be_nil
            end

            it 'sends the user a notification emails' do
              expect_next_instance_of(NotificationService) do |notification|
                expect(notification).to receive(:disabled_two_factor).with(user, :otp)
              end

              expect_next_instance_of(NotificationService) do |notification|
                expect(notification).to receive(:disabled_two_factor).with(user)
              end

              execute
            end
          end

          context 'when multiple 2FA methods are enabled' do
            let(:current_user) do
              create(:user, :two_factor_via_otp, :two_factor_via_webauthn, registrations_count: 1)
            end

            let(:user) { current_user }

            it_behaves_like 'disables OTP authenticator'

            it 'does not remove the user backup codes' do
              expect { execute }.not_to change { user.otp_backup_codes }
            end

            it 'sends the user a notification email' do
              expect_next_instance_of(NotificationService) do |notification|
                expect(notification).to receive(:disabled_two_factor).with(user, :otp)
              end

              execute
            end
          end
        end

        context 'when admin disables the OTP authenticator of another user', :enable_admin_mode do
          let(:current_user) { create(:admin) }

          context 'when only OTP is enabled' do
            let(:user) { create(:user, :two_factor_via_otp) }

            it_behaves_like 'disables OTP authenticator'

            it 'removes the user backup codes' do
              execute
              expect(user.otp_backup_codes).to be_nil
            end

            it 'sends the user a notification emails' do
              expect_next_instance_of(NotificationService) do |notification|
                expect(notification).to receive(:disabled_two_factor).with(user, :otp)
              end

              expect_next_instance_of(NotificationService) do |notification|
                expect(notification).to receive(:disabled_two_factor).with(user)
              end

              execute
            end
          end

          context 'when multiple 2FA methods are enabled' do
            let(:user) do
              create(:user, :two_factor_via_otp, :two_factor_via_webauthn, registrations_count: 1)
            end

            it_behaves_like 'disables OTP authenticator'

            it 'does not remove the user backup codes' do
              expect { execute }.not_to change { user.otp_backup_codes }
            end

            it 'sends the user a notification email' do
              expect_next_instance_of(NotificationService) do |notification|
                expect(notification).to receive(:disabled_two_factor).with(user, :otp)
              end

              execute
            end
          end
        end
      end
    end
  end
end
