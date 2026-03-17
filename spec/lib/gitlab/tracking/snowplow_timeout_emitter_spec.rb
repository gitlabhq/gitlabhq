# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::SnowplowTimeoutEmitter, feature_category: :application_instrumentation do
  subject(:emitter) do
    described_class.new(endpoint: 'localhost', options: { protocol: protocol, method: 'post', buffer_size: 1 })
  end

  let(:protocol) { 'https' }

  describe '#http_post' do
    let(:payload) { { 'key' => 'value' } }
    let(:http) { instance_double(Net::HTTP) }
    let(:response) { instance_double(Net::HTTPResponse, code: response_code) }
    let(:response_code) { '200' }

    before do
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:request).and_return(response)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)
    end

    context 'with https protocol' do
      it 'sets open_timeout, read_timeout, and use_ssl' do
        emitter.send(:http_post, payload)

        expect(http).to have_received(:open_timeout=).with(described_class::HTTP_TIMEOUT)
        expect(http).to have_received(:read_timeout=).with(described_class::HTTP_TIMEOUT)
        expect(http).to have_received(:use_ssl=).with(true)
      end
    end

    context 'with http protocol' do
      let(:protocol) { 'http' }

      it 'sets open_timeout and read_timeout without use_ssl' do
        emitter.send(:http_post, payload)

        expect(http).to have_received(:open_timeout=).with(described_class::HTTP_TIMEOUT)
        expect(http).to have_received(:read_timeout=).with(described_class::HTTP_TIMEOUT)
        expect(http).not_to have_received(:use_ssl=)
      end
    end

    context 'when response is unsuccessful' do
      let(:response_code) { '500' }

      it 'logs a warning with the response status code' do
        allow(emitter.logger).to receive(:info)
        allow(emitter.logger).to receive(:debug)
        expect(emitter.logger).to receive(:add).with(Logger::WARN).and_yield

        emitter.send(:http_post, payload)
      end
    end
  end
end
