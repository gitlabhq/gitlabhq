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
            expect(subject).to eq({ status: :success })
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
      end
    end
  end
end
