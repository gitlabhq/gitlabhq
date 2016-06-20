require 'spec_helper'

describe Gitlab::Metrics::MethodCall do
  let(:method_call) { described_class.new('Foo#bar', 'foo') }

  describe '#measure' do
    it 'measures the performance of the supplied block' do
      method_call.measure { 'foo' }

      expect(method_call.real_time).to be_a_kind_of(Numeric)
      expect(method_call.cpu_time).to be_a_kind_of(Numeric)
      expect(method_call.call_count).to eq(1)
    end
  end

  describe '#to_metric' do
    it 'returns a Metric instance' do
      method_call.measure { 'foo' }
      metric = method_call.to_metric

      expect(metric).to be_an_instance_of(Gitlab::Metrics::Metric)
      expect(metric.series).to eq('foo')

      expect(metric.values[:duration]).to be_a_kind_of(Numeric)
      expect(metric.values[:cpu_duration]).to be_a_kind_of(Numeric)
      expect(metric.values[:call_count]).to an_instance_of(Fixnum)

      expect(metric.tags).to eq({ method: 'Foo#bar' })
    end
  end

  describe '#above_threshold?' do
    it 'returns false when the total call time is not above the threshold' do
      expect(method_call.above_threshold?).to eq(false)
    end

    it 'returns true when the total call time is above the threshold' do
      expect(method_call).to receive(:real_time).and_return(9000)

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
