require 'spec_helper'

describe Gitlab::Metrics::Samplers::RubySampler do
  let(:sampler) { described_class.new(5) }

  after do
    Allocations.stop if Gitlab::Metrics.mri?
  end

  describe '#sample' do
    it 'samples various statistics' do
      expect(Gitlab::Metrics::System).to receive(:memory_usage)
      expect(Gitlab::Metrics::System).to receive(:file_descriptor_count)
      expect(sampler).to receive(:sample_objects)
      expect(sampler).to receive(:sample_gc)

      sampler.sample
    end

    it 'adds a metric containing the memory usage' do
      expect(Gitlab::Metrics::System).to receive(:memory_usage)
                                           .and_return(9000)

      expect(sampler.metrics[:memory_usage]).to receive(:set)
                                                  .with({}, 9000)
                                                  .and_call_original

      sampler.sample
    end

    it 'adds a metric containing the amount of open file descriptors' do
      expect(Gitlab::Metrics::System).to receive(:file_descriptor_count)
                                           .and_return(4)

      expect(sampler.metrics[:file_descriptors]).to receive(:set)
                                                      .with({}, 4)
                                                      .and_call_original

      sampler.sample
    end

    it 'clears any GC profiles' do
      expect(GC::Profiler).to receive(:clear)

      sampler.sample
    end
  end

  describe '#sample_gc' do
    it 'adds a metric containing garbage collection time statistics' do
      expect(GC::Profiler).to receive(:total_time).and_return(0.24)

      expect(sampler.metrics[:total_time]).to receive(:set)
                                                .with({}, 240)
                                                .and_call_original

      sampler.sample
    end

    it 'adds a metric containing garbage collection statistics' do
      GC.stat.keys.each do |key|
        expect(sampler.metrics[key]).to receive(:set).with({}, anything).and_call_original
      end

      sampler.sample
    end
  end

  if Gitlab::Metrics.mri?
    describe '#sample_objects' do
      it 'adds a metric containing the amount of allocated objects' do
        expect(sampler.metrics[:objects_total]).to receive(:set)
                                                     .with(include(class: anything), be > 0)
                                                     .at_least(:once)
                                                     .and_call_original

        sampler.sample
      end

      it 'ignores classes without a name' do
        expect(Allocations).to receive(:to_hash).and_return({ Class.new => 4 })

        expect(sampler.metrics[:objects_total]).not_to receive(:set)
                                                         .with(include(class: 'object_counts'), anything)

        sampler.sample
      end
    end
  end
end
