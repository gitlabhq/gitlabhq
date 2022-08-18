# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::EmailVerification::ValidateTokenService, :clean_gitlab_redis_rate_limiting do
  using RSpec::Parameterized::TableSyntax

  let(:service) { described_class.new(attr: attr, user: user, token: token) }
  let(:token) { 'token' }
  let(:encrypted_token) { Devise.token_generator.digest(User, attr, token) }
  let(:generated_at_attr) { attr == :unlock_token ? :locked_at : :confirmation_sent_at }
  let(:token_generated_at) { 1.minute.ago }
  let(:user) { build(:user, attr => encrypted_token, generated_at_attr => token_generated_at) }

  describe '#execute' do
    context 'with a valid attribute' do
      where(:attr) { [:unlock_token, :confirmation_token] }

      with_them do
        context 'when successful' do
          it 'returns a success status' do
            expect(service.execute).to eq(status: :success)
          end
        end

        context 'when rate limited' do
          before do
            allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)
          end

          it 'returns a failure status' do
            expect(service.execute).to eq(
              {
                status: :failure,
                reason: :rate_limited,
                message: "You've reached the maximum amount of tries. "\
                         'Wait 10 minutes or resend a new code and try again.'
              }
            )
          end
        end

        context 'when expired' do
          let(:token_generated_at) { 2.hours.ago }

          it 'returns a failure status' do
            expect(service.execute).to eq(
              {
                status: :failure,
                reason: :expired,
                message: 'The code has expired. Resend a new code and try again.'
              }
            )
          end
        end

        context 'when invalid' do
          let(:encrypted_token) { 'xxx' }

          it 'returns a failure status' do
            expect(service.execute).to eq(
              {
                status: :failure,
                reason: :invalid,
                message: 'The code is incorrect. Enter it again, or resend a new code.'
              }
            )
          end
        end
      end
    end

    context 'with an invalid attribute' do
      let(:attr) { :username }

      it 'raises an error' do
        expect { service.execute }.to raise_error(ArgumentError, 'Invalid attribute')
      end
    end
  end
end
