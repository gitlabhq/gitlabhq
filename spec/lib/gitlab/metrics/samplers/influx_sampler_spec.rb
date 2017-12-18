require 'spec_helper'

describe Gitlab::Metrics::Samplers::InfluxSampler do
  let(:sampler) { described_class.new(5) }

  after do
    Allocations.stop if Gitlab::Metrics.mri?
  end

  describe '#start' do
    it 'runs once and gathers a sample at a given interval' do
      expect(sampler).to receive(:sleep).with(a_kind_of(Numeric)).twice
      expect(sampler).to receive(:sample).once
      expect(sampler).to receive(:running).and_return(true, false)

      sampler.start.join
    end
  end

  describe '#sample' do
    it 'samples various statistics' do
      expect(sampler).to receive(:sample_memory_usage)
      expect(sampler).to receive(:sample_file_descriptors)
      expect(sampler).to receive(:sample_gc)
      expect(sampler).to receive(:flush)

      sampler.sample
    end

    it 'clears any GC profiles' do
      expect(sampler).to receive(:flush)
      expect(GC::Profiler).to receive(:clear)

      sampler.sample
    end
  end

  describe '#flush' do
    it 'schedules the metrics using Sidekiq' do
      expect(Gitlab::Metrics).to receive(:submit_metrics)
        .with([an_instance_of(Hash)])

      sampler.sample_memory_usage
      sampler.flush
    end
  end

  describe '#sample_memory_usage' do
    it 'adds a metric containing the memory usage' do
      expect(Gitlab::Metrics::System).to receive(:memory_usage)
        .and_return(9000)

      expect(sampler).to receive(:add_metric)
        .with(/memory_usage/, value: 9000)
        .and_call_original

      sampler.sample_memory_usage
    end
  end

  describe '#sample_file_descriptors' do
    it 'adds a metric containing the amount of open file descriptors' do
      expect(Gitlab::Metrics::System).to receive(:file_descriptor_count)
        .and_return(4)

      expect(sampler).to receive(:add_metric)
        .with(/file_descriptors/, value: 4)
        .and_call_original

      sampler.sample_file_descriptors
    end
  end

  describe '#sample_gc' do
    it 'adds a metric containing garbage collection statistics' do
      expect(GC::Profiler).to receive(:total_time).and_return(0.24)

      expect(sampler).to receive(:add_metric)
        .with(/gc_statistics/, an_instance_of(Hash))
        .and_call_original

      sampler.sample_gc
    end
  end

  describe '#add_metric' do
    it 'prefixes the series name for a Rails process' do
      expect(sampler).to receive(:sidekiq?).and_return(false)

      expect(Gitlab::Metrics::Metric).to receive(:new)
        .with('rails_cats', { value: 10 }, {})
        .and_call_original

      sampler.add_metric('cats', value: 10)
    end

    it 'prefixes the series name for a Sidekiq process' do
      expect(sampler).to receive(:sidekiq?).and_return(true)

      expect(Gitlab::Metrics::Metric).to receive(:new)
        .with('sidekiq_cats', { value: 10 }, {})
        .and_call_original

      sampler.add_metric('cats', value: 10)
    end
  end

  describe '#sleep_interval' do
    it 'returns a Numeric' do
      expect(sampler.sleep_interval).to be_a_kind_of(Numeric)
    end

    # Testing random behaviour is very hard, so treat this test as a basic smoke
    # test instead of a very accurate behaviour/unit test.
    it 'does not return the same interval twice in a row' do
      last = nil

      100.times do
        interval = sampler.sleep_interval

        expect(interval).not_to eq(last)

        last = interval
      end
    end
  end
end
