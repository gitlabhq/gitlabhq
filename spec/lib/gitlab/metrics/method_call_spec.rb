require 'spec_helper'

describe Gitlab::Metrics::MethodCall do
  let(:transaction) { double(:transaction, labels: {}) }
  let(:method_call) { described_class.new('Foo#bar', :Foo, '#bar', transaction) }

  describe '#measure' do
    after do
      described_class.reload_metric!(:gitlab_method_call_duration_seconds)
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

      context 'prometheus instrumentation is enabled' do
        before do
          Feature.get(:prometheus_metrics_method_instrumentation).enable
        end

        around do |example|
          Timecop.freeze do
            example.run
          end
        end

        it 'metric is not a NullMetric' do
          expect(described_class).not_to be_instance_of(Gitlab::Metrics::NullMetric)
        end

        it 'observes the performance of the supplied block' do
          expect(described_class.gitlab_method_call_duration_seconds)
            .to receive(:observe)
                  .with({ module: :Foo, method: '#bar' }, be_a_kind_of(Numeric))

          method_call.measure { 'foo' }
        end
      end

      context 'prometheus instrumentation is disabled' do
        before do
          Feature.get(:prometheus_metrics_method_instrumentation).disable
        end

        it 'observes using NullMetric' do
          expect(described_class.gitlab_method_call_duration_seconds).to be_instance_of(Gitlab::Metrics::NullMetric)
          expect(described_class.gitlab_method_call_duration_seconds).to receive(:observe)

          method_call.measure { 'foo' }
        end
      end
    end

    context 'when measurement is below threshold' do
      before do
        allow(method_call).to receive(:above_threshold?).and_return(false)
      end

      it 'does not observe the performance' do
        expect(described_class.gitlab_method_call_duration_seconds)
          .not_to receive(:observe)

        method_call.measure { 'foo' }
      end
    end
  end

  describe '#to_metric' do
    it 'returns a Metric instance' do
      expect(method_call).to receive(:real_time).and_return(4.0001).twice
      expect(method_call).to receive(:cpu_time).and_return(3.0001)

      method_call.measure { 'foo' }
      metric = method_call.to_metric

      expect(metric).to be_an_instance_of(Gitlab::Metrics::Metric)
      expect(metric.series).to eq('rails_method_calls')

      expect(metric.values[:duration]).to eq(4000)
      expect(metric.values[:cpu_duration]).to eq(3000)
      expect(metric.values[:call_count]).to be_an(Integer)

      expect(metric.tags).to eq({ method: 'Foo#bar' })
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
