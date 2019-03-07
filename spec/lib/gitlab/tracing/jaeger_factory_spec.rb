# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Tracing::JaegerFactory do
  describe '.create_tracer' do
    let(:service_name) { 'rspec' }

    shared_examples_for 'a jaeger tracer' do
      it 'responds to active_span methods' do
        expect(tracer).to respond_to(:active_span)
      end

      it 'yields control' do
        expect { |b| tracer.start_active_span('operation_name', &b) }.to yield_control
      end
    end

    context 'processes default connections' do
      it_behaves_like 'a jaeger tracer' do
        let(:tracer) { described_class.create_tracer(service_name, {}) }
      end
    end

    context 'handles debug options' do
      it_behaves_like 'a jaeger tracer' do
        let(:tracer) { described_class.create_tracer(service_name, { debug: "1" }) }
      end
    end

    context 'handles const sampler' do
      it_behaves_like 'a jaeger tracer' do
        let(:tracer) { described_class.create_tracer(service_name, { sampler: "const", sampler_param: "1" }) }
      end
    end

    context 'handles probabilistic sampler' do
      it_behaves_like 'a jaeger tracer' do
        let(:tracer) { described_class.create_tracer(service_name, { sampler: "probabilistic", sampler_param: "0.5" }) }
      end
    end

    context 'handles http_endpoint configurations' do
      it_behaves_like 'a jaeger tracer' do
        let(:tracer) { described_class.create_tracer(service_name, { http_endpoint: "http://localhost:1234" }) }
      end
    end

    context 'handles udp_endpoint configurations' do
      it_behaves_like 'a jaeger tracer' do
        let(:tracer) { described_class.create_tracer(service_name, { udp_endpoint: "localhost:4321" }) }
      end
    end

    context 'ignores invalid parameters' do
      it_behaves_like 'a jaeger tracer' do
        let(:tracer) { described_class.create_tracer(service_name, { invalid: "true" }) }
      end
    end

    context 'accepts the debug parameter when strict_parser is set' do
      it_behaves_like 'a jaeger tracer' do
        let(:tracer) { described_class.create_tracer(service_name, { debug: "1", strict_parsing: "1" }) }
      end
    end

    it 'rejects invalid parameters when strict_parser is set' do
      expect { described_class.create_tracer(service_name, { invalid: "true", strict_parsing: "1" }) }.to raise_error(StandardError)
    end
  end
end
