# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::Collector::SentryAuthParser do
  describe '.parse' do
    let(:headers) { { 'X-Sentry-Auth' => "Sentry sentry_key=glet_1fedb514e17f4b958435093deb02048c" } }
    let(:request) { instance_double('ActionDispatch::Request', headers: headers) }

    subject { described_class.parse(request) }

    context 'with empty headers' do
      let(:headers) { {} }

      it 'fails with exception' do
        expect { subject }.to raise_error(StandardError)
      end
    end

    context 'with missing sentry_key' do
      let(:headers) { { 'X-Sentry-Auth' => "Sentry foo=bar" } }

      it 'returns empty value for public_key' do
        expect(subject[:public_key]).to be_nil
      end
    end

    it 'returns correct value for public_key' do
      expect(subject[:public_key]).to eq('glet_1fedb514e17f4b958435093deb02048c')
    end
  end
end
