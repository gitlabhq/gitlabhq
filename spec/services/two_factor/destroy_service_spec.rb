# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TwoFactor::DestroyService, feature_category: :system_access do
  let_it_be(:current_user) { create(:user) }

  subject { described_class.new(current_user, user: user).execute }

  context 'disabling two-factor authentication' do
    shared_examples_for 'does not send notification email' do
      context 'notification', :mailer do
        it 'does not send a notification' do
          perform_enqueued_jobs do
            subject
          end

          should_not_email(user)
        end
      end
    end

    context 'when the user does not have two-factor authentication enabled' do
      let(:user) { current_user }

      it 'returns error' do
        expect(subject).to eq(
          {
            status: :error,
            message: 'Two-factor authentication is not enabled for this user'
          }
        )
      end

      it_behaves_like 'does not send notification email'
    end

    context 'when the user has two-factor authentication enabled' do
      context 'when the executor is not authorized to disable two-factor authentication' do
        context 'disabling the two-factor authentication of another user' do
          let(:user) { create(:user, :two_factor) }

          it 'returns error' do
            expect(subject).to eq(
              {
                status: :error,
                message: 'You are not authorized to perform this action'
              }
            )
          end

          it 'does not disable two-factor authentication' do
            expect { subject }.not_to change { user.reload.two_factor_enabled? }.from(true)
          end

          it_behaves_like 'does not send notification email'
        end
      end

      context 'when the executor is authorized to disable two-factor authentication' do
        shared_examples_for 'disables two-factor authentication' do
          it 'returns success' do
            expect(subject).to include({ status: :success })
          end

          it 'disables the two-factor authentication of the user' do
            expect { subject }.to change { user.reload.two_factor_enabled? }.from(true).to(false)
          end

          context 'notification', :mailer do
            it 'sends a notification' do
              perform_enqueued_jobs do
                subject
              end

              should_email(user)
            end
          end
        end

        context 'disabling their own two-factor authentication' do
          let(:current_user) { create(:user, :two_factor) }
          let(:user) { current_user }

          it_behaves_like 'disables two-factor authentication'
        end

        context 'admin disables the two-factor authentication of another user', :enable_admin_mode do
          let(:current_user) { create(:admin) }
          let(:user) { create(:user, :two_factor) }

          it_behaves_like 'disables two-factor authentication'
        end

        context 'when email OTP is required at minimum', :sidekiq_inline, :freeze_time do
          let(:current_user) { create(:user, :two_factor) }
          let(:user) { current_user }

          # This behavior is triggered by the call to
          # `Users::UpdateService` and `User`'s inclusion of the
          # `Authn::EmailOtpEnrollment` concern.
          # This spec is for testing in depth - full behavior is tested
          # in email_otp_enrollment_spec.rb
          it 'enrolls the user in email OTP' do
            stub_application_setting(require_minimum_email_based_otp_for_users_with_passwords: true)

            subject
            user.reload
            expect(user.email_otp_required_after).to eq(Time.current)
          end
        end
      end
    end
  end
end
