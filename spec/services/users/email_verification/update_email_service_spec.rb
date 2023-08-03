# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::EmailVerification::UpdateEmailService, feature_category: :instance_resiliency do
  let_it_be_with_reload(:user) { create(:user) }
  let(:email) { build_stubbed(:user).email }

  describe '#execute' do
    subject(:execute_service) { described_class.new(user: user).execute(email: email) }

    context 'when successful' do
      it { is_expected.to eq(status: :success) }

      it 'does not send a confirmation instructions email' do
        expect { execute_service }.not_to have_enqueued_mail(DeviseMailer, :confirmation_instructions)
      end

      it 'sets the unconfirmed_email and confirmation_sent_at fields', :freeze_time do
        expect { execute_service }
          .to change { user.unconfirmed_email }.from(nil).to(email)
          .and change { user.confirmation_sent_at }.from(nil).to(Time.current)
      end
    end

    context 'when rate limited' do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
          .with(:email_verification_code_send, scope: user).and_return(true)
      end

      it 'returns a failure status' do
        expect(execute_service).to eq(
          {
            status: :failure,
            reason: :rate_limited,
            message: format(s_("IdentityVerification|You've reached the maximum amount of tries. " \
                               'Wait %{interval} and try again.'), interval: 'about 1 hour')
          }
        )
      end
    end

    context 'when email reset has already been offered' do
      before do
        user.email_reset_offered_at = 1.minute.ago
      end

      it 'returns a failure status' do
        expect(execute_service).to eq(
          {
            status: :failure,
            reason: :already_offered,
            message: s_('IdentityVerification|Email update is only offered once.')
          }
        )
      end
    end

    context 'when email is unchanged' do
      let(:email) { user.email }

      it 'returns a failure status' do
        expect(execute_service).to eq(
          {
            status: :failure,
            reason: :no_change,
            message: s_('IdentityVerification|A code has already been sent to this email address. ' \
                        'Check your spam folder or enter another email address.')
          }
        )
      end
    end

    context 'when email is missing' do
      let(:email) { '' }

      it 'returns a failure status' do
        expect(execute_service).to eq(
          {
            status: :failure,
            reason: :validation_error,
            message: "Email can't be blank"
          }
        )
      end
    end

    context 'when email is not valid' do
      let(:email) { 'xxx' }

      it 'returns a failure status' do
        expect(execute_service).to eq(
          {
            status: :failure,
            reason: :validation_error,
            message: 'Email is invalid'
          }
        )
      end
    end

    context 'when email is already taken' do
      before do
        create(:user, email: email)
      end

      it 'returns a failure status' do
        expect(execute_service).to eq(
          {
            status: :failure,
            reason: :validation_error,
            message: 'Email has already been taken'
          }
        )
      end
    end
  end
end
