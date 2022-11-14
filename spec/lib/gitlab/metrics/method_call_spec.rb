# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::MethodCall do
  let(:transaction) { Gitlab::Metrics::WebTransaction.new({}) }
  let(:method_call) { described_class.new('Foo#bar', :Foo, '#bar', transaction) }

  describe '#measure' do
    after do
      ::Gitlab::Metrics::Transaction.reload_metric!(:gitlab_method_call_duration_seconds)
    end

    it 'measures the performance of the supplied block' do
      method_call.measure { 'foo' }

      expect(method_call.real_time).to be_a_kind_of(Numeric)
      expect(method_call.cpu_time).to be_a_kind_of(Numeric)
      expect(method_call.call_count).to eq(1)
    end

    context 'when measurement is above threshold' do
      before do
        allow(method_call).to receive(:above_threshold?).and_return(true)
      end

      around do |example|
        freeze_time do
          example.run
        end
      end

      it 'metric is not a NullMetric' do
        method_call.measure { 'foo' }
        expect(::Gitlab::Metrics::WebTransaction.prometheus_metric(:gitlab_method_call_duration_seconds, :histogram)).not_to be_instance_of(Gitlab::Metrics::NullMetric)
      end

      it 'observes the performance of the supplied block' do
        expect(transaction)
          .to receive(:observe).with(:gitlab_method_call_duration_seconds, be_a_kind_of(Numeric), { method: "#bar", module: :Foo })

        method_call.measure { 'foo' }
      end
    end

    context 'when measurement is below threshold' do
      before do
        allow(method_call).to receive(:above_threshold?).and_return(false)
      end

      it 'does not observe the performance' do
        expect(transaction)
          .not_to receive(:observe)
                .with(:gitlab_method_call_duration_seconds, be_a_kind_of(Numeric))

        method_call.measure { 'foo' }
      end
    end
  end

  describe '#above_threshold?' do
    before do
      allow(Gitlab::Metrics).to receive(:method_call_threshold).and_return(100)
    end

    it 'returns false when the total call time is not above the threshold' do
      expect(method_call).to receive(:real_time).and_return(0.009)

      expect(method_call.above_threshold?).to eq(false)
    end

    it 'returns true when the total call time is above the threshold' do
      expect(method_call).to receive(:real_time).and_return(9)

      expect(method_call.above_threshold?).to eq(true)
    end
  end

  describe '#call_count' do
    context 'without any method calls' do
      it 'returns 0' do
        expect(method_call.call_count).to eq(0)
      end
    end

    context 'with method calls' do
      it 'returns the number of method calls' do
        method_call.measure { 'foo' }

        expect(method_call.call_count).to eq(1)
      end
    end
  end

  describe '#cpu_time' do
    context 'without timings' do
      it 'returns 0.0' do
        expect(method_call.cpu_time).to eq(0.0)
      end
    end

    context 'with timings' do
      it 'returns the total CPU time' do
        method_call.measure { 'foo' }

        expect(method_call.cpu_time >= 0.0).to be(true)
      end
    end
  end

  describe '#real_time' do
    context 'without timings' do
      it 'returns 0.0' do
        expect(method_call.real_time).to eq(0.0)
      end
    end

    context 'with timings' do
      it 'returns the total real time' do
        method_call.measure { 'foo' }

        expect(method_call.real_time >= 0.0).to be(true)
      end
    end
  end
end
