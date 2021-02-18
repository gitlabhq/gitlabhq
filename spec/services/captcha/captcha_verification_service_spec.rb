# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Captcha::CaptchaVerificationService do
  describe '#execute' do
    let(:captcha_response) { nil }
    let(:request) { double(:request) }
    let(:service) { described_class.new }

    subject { service.execute(captcha_response: captcha_response, request: request) }

    context 'when there is no captcha_response' do
      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when there is a captcha_response' do
      let(:captcha_response) { 'abc123' }

      before do
        expect(Gitlab::Recaptcha).to receive(:load_configurations!)
      end

      it 'returns false' do
        expect(service).to receive(:verify_recaptcha).with(response: captcha_response) { true }

        expect(subject).to eq(true)
      end

      it 'has a request method which returns the request' do
        subject

        expect(service.send(:request)).to eq(request)
      end
    end
  end
end
