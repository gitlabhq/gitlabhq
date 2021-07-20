# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Captcha::CaptchaVerificationService do
  describe '#execute' do
    let(:captcha_response) { 'abc123' }
    let(:fake_ip) { '1.2.3.4' }
    let(:spam_params) do
      ::Spam::SpamParams.new(
        captcha_response: captcha_response,
        spam_log_id: double,
        ip_address: fake_ip,
        user_agent: double,
        referer: double
      )
    end

    let(:service) { described_class.new(spam_params: spam_params) }

    subject { service.execute }

    context 'when there is no captcha_response' do
      let(:captcha_response) { nil }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when there is a captcha_response' do
      before do
        expect(Gitlab::Recaptcha).to receive(:load_configurations!)
      end

      it 'returns false' do
        expect(service).to receive(:verify_recaptcha).with(response: captcha_response) { true }

        expect(subject).to eq(true)
      end

      it 'has a request method which returns an object with the ip address #remote_ip' do
        subject

        request_struct = service.send(:request)
        expect(request_struct).to respond_to(:remote_ip)
        expect(request_struct.remote_ip).to eq(fake_ip)
      end
    end
  end
end
