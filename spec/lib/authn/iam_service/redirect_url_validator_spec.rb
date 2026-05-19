# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Authn::IamService::RedirectUrlValidator, feature_category: :system_access do
  let(:iam_service_url) { 'https://iam.example.com' }

  before do
    allow(Authn::IamAuthService).to receive(:url).and_return(iam_service_url)
  end

  describe '.valid?' do
    context 'when the URL matches the IAM host, port, and uses https' do
      it 'returns true' do
        result = described_class.valid?("#{iam_service_url}/oauth2/authorize?x=1")

        expect(result).to be(true)
      end
    end

    context 'when the URL is blank' do
      it 'returns false' do
        result = described_class.valid?(nil)

        expect(result).to be(false)
      end
    end

    context 'when the URL points to a different host' do
      it 'returns false' do
        result = described_class.valid?('https://untrusted.example.com/oauth2/authorize')

        expect(result).to be(false)
      end
    end

    context 'when the URL uses a different port' do
      it 'returns false' do
        result = described_class.valid?('https://iam.example.com:9999/oauth2/authorize')

        expect(result).to be(false)
      end
    end

    context 'when the URL is malformed' do
      it 'returns false' do
        result = described_class.valid?('https://iam.example.com /oauth2/authorize')

        expect(result).to be(false)
      end
    end

    context 'when the URL has no scheme' do
      it 'returns false' do
        result = described_class.valid?('iam.example.com/oauth2/authorize')

        expect(result).to be(false)
      end
    end

    context 'when the URL uses http' do
      let(:http_url) { 'http://iam.example.com/oauth2/authorize' }
      let(:iam_service_url) { 'http://iam.example.com' }

      it 'rejects http outside development' do
        allow(Rails.env).to receive(:development?).and_return(false)

        result = described_class.valid?(http_url)

        expect(result).to be(false)
      end

      it 'accepts http in development' do
        allow(Rails.env).to receive(:development?).and_return(true)

        result = described_class.valid?(http_url)

        expect(result).to be(true)
      end
    end

    context 'when the URL uses a non-http/https scheme' do
      it 'returns false' do
        result = described_class.valid?('ftp://iam.example.com/oauth2/authorize')

        expect(result).to be(false)
      end
    end
  end
end
