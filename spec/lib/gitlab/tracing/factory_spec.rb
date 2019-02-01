# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Tracing::Factory do
  describe '.create_tracer' do
    let(:service_name) { 'rspec' }

    context "when tracing is not configured" do
      it 'ignores null connection strings' do
        expect(described_class.create_tracer(service_name, nil)).to be_nil
      end

      it 'ignores empty connection strings' do
        expect(described_class.create_tracer(service_name, '')).to be_nil
      end

      it 'ignores unknown implementations' do
        expect(described_class.create_tracer(service_name, 'opentracing://invalid_driver')).to be_nil
      end

      it 'ignores invalid connection strings' do
        expect(described_class.create_tracer(service_name, 'open?tracing')).to be_nil
      end
    end

    context "when tracing is configured with jaeger" do
      let(:mock_tracer) { double('tracer') }

      it 'processes default connections' do
        expect(Gitlab::Tracing::JaegerFactory).to receive(:create_tracer).with(service_name, {}).and_return(mock_tracer)

        expect(described_class.create_tracer(service_name, 'opentracing://jaeger')).to be(mock_tracer)
      end

      it 'processes connections with parameters' do
        expect(Gitlab::Tracing::JaegerFactory).to receive(:create_tracer).with(service_name, { a: '1', b: '2', c: '3' }).and_return(mock_tracer)

        expect(described_class.create_tracer(service_name, 'opentracing://jaeger?a=1&b=2&c=3')).to be(mock_tracer)
      end
    end
  end
end
