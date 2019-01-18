# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Tracing::JaegerFactory do
  describe '.create_tracer' do
    let(:service_name) { 'rspec' }

    it 'processes default connections' do
      expect(described_class.create_tracer(service_name, {})).to respond_to(:active_span)
    end

    it 'handles debug options' do
      expect(described_class.create_tracer(service_name, { debug: "1" })).to respond_to(:active_span)
    end

    it 'handles const sampler' do
      expect(described_class.create_tracer(service_name, { sampler: "const", sampler_param: "1" })).to respond_to(:active_span)
    end

    it 'handles probabilistic sampler' do
      expect(described_class.create_tracer(service_name, { sampler: "probabilistic", sampler_param: "0.5" })).to respond_to(:active_span)
    end

    it 'handles http_endpoint configurations' do
      expect(described_class.create_tracer(service_name, { http_endpoint: "http://localhost:1234" })).to respond_to(:active_span)
    end

    it 'handles udp_endpoint configurations' do
      expect(described_class.create_tracer(service_name, { udp_endpoint: "localhost:4321" })).to respond_to(:active_span)
    end

    it 'ignores invalid parameters' do
      expect(described_class.create_tracer(service_name, { invalid: "true" })).to respond_to(:active_span)
    end

    it 'accepts the debug parameter when strict_parser is set' do
      expect(described_class.create_tracer(service_name, { debug: "1", strict_parsing: "1" })).to respond_to(:active_span)
    end

    it 'rejects invalid parameters when strict_parser is set' do
      expect { described_class.create_tracer(service_name, { invalid: "true", strict_parsing: "1" }) }.to raise_error(StandardError)
    end
  end
end
