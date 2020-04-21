# frozen_string_literal: true

require 'spec_helper'

describe Spam::SpamVerdictService do
  include_context 'includes Spam constants'

  let(:fake_ip) { '1.2.3.4' }
  let(:fake_user_agent) { 'fake-user-agent' }
  let(:fake_referrer) { 'fake-http-referrer' }
  let(:env) do
    { 'action_dispatch.remote_ip' => fake_ip,
      'HTTP_USER_AGENT' => fake_user_agent,
      'HTTP_REFERRER' => fake_referrer }
  end
  let(:request) { double(:request, env: env) }

  let(:check_for_spam) { true }
  let(:issue) { build(:issue) }
  let(:service) do
    described_class.new(target: issue, request: request, options: {})
  end

  describe '#execute' do
    subject { service.execute }

    before do
      allow_next_instance_of(Spam::AkismetService) do |service|
        allow(service).to receive(:spam?).and_return(spam_verdict)
      end
    end

    context 'if Akismet considers it spam' do
      let(:spam_verdict) { true }

      context 'if reCAPTCHA is enabled' do
        before do
          stub_application_setting(recaptcha_enabled: true)
        end

        it 'requires reCAPTCHA' do
          expect(subject).to eq REQUIRE_RECAPTCHA
        end
      end

      context 'if reCAPTCHA is not enabled' do
        before do
          stub_application_setting(recaptcha_enabled: false)
        end

        it 'disallows the change' do
          expect(subject).to eq DISALLOW
        end
      end
    end

    context 'if Akismet does not consider it spam' do
      let(:spam_verdict) { false }

      it 'allows the change' do
        expect(subject).to eq ALLOW
      end
    end
  end
end
