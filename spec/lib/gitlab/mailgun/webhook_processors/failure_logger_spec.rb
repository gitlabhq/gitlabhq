# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Mailgun::WebhookProcessors::FailureLogger do
  describe '#execute', :freeze_time, :clean_gitlab_redis_rate_limiting do
    let(:base_payload) do
      {
        'id' => 'U2kZkAiuScqcMTq-8Atz-Q',
        'event' => 'failed',
        'recipient' => 'recipient@gitlab.com',
        'reason' => 'bounce',
        'delivery-status' => {
          'code' => '421',
          'message' => '4.4.2 mxfront9g.mail.example.com Error: timeout exceeded'
        }
      }
    end

    context 'on permanent failure' do
      let(:processor) { described_class.new(base_payload.merge({ 'severity' => 'permanent' })) }

      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:rate_limits)
          .and_return(permanent_email_failure: { threshold: 1, interval: 1.minute })
      end

      context 'when threshold is not exceeded' do
        it 'increments counter but does not log the failure' do
          expect(Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(
            :permanent_email_failure, scope: 'recipient@gitlab.com'
          ).and_call_original
          expect(Gitlab::ErrorTracking::Logger).not_to receive(:error)

          processor.execute
        end
      end

      context 'when threshold is exceeded' do
        before do
          processor.execute
        end

        it 'increments counter and logs the failure' do
          expect(Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(
            :permanent_email_failure, scope: 'recipient@gitlab.com'
          ).and_call_original
          expect(Gitlab::ErrorTracking::Logger).to receive(:error).with(
            event: 'email_delivery_failure',
            mailgun_event_id: base_payload['id'],
            recipient: base_payload['recipient'],
            failure_type: 'permanent',
            failure_reason: base_payload['reason'],
            failure_code: base_payload['delivery-status']['code'],
            failure_message: base_payload['delivery-status']['message']
          )

          processor.execute
        end
      end
    end

    context 'on temporary failure' do
      let(:processor) { described_class.new(base_payload.merge({ 'severity' => 'temporary' })) }

      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:rate_limits)
          .and_return(temporary_email_failure: { threshold: 1, interval: 1.minute })
      end

      context 'when threshold is not exceeded' do
        it 'increments counter but does not log the failure' do
          expect(Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(
            :temporary_email_failure, scope: 'recipient@gitlab.com'
          ).and_call_original
          expect(Gitlab::ErrorTracking::Logger).not_to receive(:error)

          processor.execute
        end
      end

      context 'when threshold is exceeded' do
        before do
          processor.execute
        end

        it 'increments counter and logs the failure' do
          expect(Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(
            :temporary_email_failure, scope: 'recipient@gitlab.com'
          ).and_call_original
          expect(Gitlab::ErrorTracking::Logger).to receive(:error).with(
            event: 'email_delivery_failure',
            mailgun_event_id: base_payload['id'],
            recipient: base_payload['recipient'],
            failure_type: 'temporary',
            failure_reason: base_payload['reason'],
            failure_code: base_payload['delivery-status']['code'],
            failure_message: base_payload['delivery-status']['message']
          )

          processor.execute
        end
      end
    end

    context 'on other events' do
      let(:processor) { described_class.new(base_payload.merge({ 'event' => 'delivered' })) }

      it 'does nothing' do
        expect(Gitlab::ErrorTracking::Logger).not_to receive(:error)
        expect(Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)

        processor.execute
      end
    end
  end
end
