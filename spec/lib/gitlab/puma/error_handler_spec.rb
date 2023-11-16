# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Puma::ErrorHandler, feature_category: :shared do
  subject { described_class.new(is_production) }

  let(:is_production) { true }
  let(:ex) { StandardError.new('Sample error message') }
  let(:env) { {} }
  let(:status_code) { 500 }

  describe '#execute' do
    it 'captures the exception and returns a Rack response' do
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        ex,
        { puma_env: env, status_code: status_code },
        { handler: 'puma_low_level' }
      ).and_call_original

      status, headers, message = subject.execute(ex, env, status_code)

      expect(status).to eq(500)
      expect(headers).to eq({})
      expect(message).to eq(described_class::PROD_ERROR_MESSAGE)
    end

    context 'when not in production' do
      let(:is_production) { false }

      it 'returns a Rack response with dev error message' do
        status, headers, message = subject.execute(ex, env, status_code)

        expect(status).to eq(500)
        expect(headers).to eq({})
        expect(message).to eq(described_class::DEV_ERROR_MESSAGE)
      end
    end

    context 'when status code is nil' do
      let(:status_code) { 500 }

      it 'defaults to error 500' do
        status, headers, message = subject.execute(ex, env, status_code)

        expect(status).to eq(500)
        expect(headers).to eq({})
        expect(message).to eq(described_class::PROD_ERROR_MESSAGE)
      end
    end

    context 'when status code is provided' do
      let(:status_code) { 404 }

      it 'uses the provided status code in the response' do
        status, headers, message = subject.execute(ex, env, status_code)

        expect(status).to eq(404)
        expect(headers).to eq({})
        expect(message).to eq(described_class::PROD_ERROR_MESSAGE)
      end
    end
  end
end
