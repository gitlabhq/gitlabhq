require 'spec_helper'

describe Gitlab::Metrics::Sampler do
  let(:sampler) { described_class.new(5) }

  describe '#start' do
    it 'gathers a sample at a given interval' do
      expect(sampler).to receive(:sleep).with(5)
      expect(sampler).to receive(:sample)
      expect(sampler).to receive(:loop).and_yield

      sampler.start.join
    end
  end

  describe '#sample' do
    it 'samples various statistics' do
      expect(sampler).to receive(:sample_memory_usage)
      expect(sampler).to receive(:sample_file_descriptors)
      expect(sampler).to receive(:sample_objects)
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
      expect(MetricsWorker).to receive(:perform_async).
        with([an_instance_of(Hash)])

      sampler.sample_memory_usage
      sampler.flush
    end
  end

  describe '#sample_memory_usage' do
    it 'adds a metric containing the memory usage' do
      expect(Gitlab::Metrics::System).to receive(:memory_usage).
        and_return(9000)

      expect(Gitlab::Metrics::Metric).to receive(:new).
        with('memory_usage', value: 9000).
        and_call_original

      sampler.sample_memory_usage
    end
  end

  describe '#sample_file_descriptors' do
    it 'adds a metric containing the amount of open file descriptors' do
      expect(Gitlab::Metrics::System).to receive(:file_descriptor_count).
        and_return(4)

      expect(Gitlab::Metrics::Metric).to receive(:new).
        with('file_descriptors', value: 4).
        and_call_original

      sampler.sample_file_descriptors
    end
  end

  describe '#sample_objects' do
    it 'adds a metric containing the amount of allocated objects' do
      expect(Gitlab::Metrics::Metric).to receive(:new).
        with('object_counts', an_instance_of(Hash)).
        and_call_original

      sampler.sample_objects
    end
  end

  describe '#sample_gc' do
    it 'adds a metric containing garbage collection statistics' do
      expect(GC::Profiler).to receive(:total_time).and_return(0.24)

      expect(Gitlab::Metrics::Metric).to receive(:new).
        with('gc_statistics', an_instance_of(Hash)).
        and_call_original

      sampler.sample_gc
    end
  end
end
