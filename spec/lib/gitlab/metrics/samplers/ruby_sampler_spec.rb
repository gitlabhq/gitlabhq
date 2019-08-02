require 'spec_helper'

describe Gitlab::Metrics::Samplers::RubySampler do
  let(:sampler) { described_class.new(5) }
  let(:null_metric) { double('null_metric', set: nil, observe: nil) }

  before do
    allow(Gitlab::Metrics::NullMetric).to receive(:instance).and_return(null_metric)
  end

  describe '#initialize' do
    it 'sets process_start_time_seconds' do
      Timecop.freeze do
        expect(sampler.metrics[:process_start_time_seconds].get).to eq(Time.now.to_i)
      end
    end
  end

  describe '#sample' do
    it 'samples various statistics' do
      expect(Gitlab::Metrics::System).to receive(:cpu_time)
      expect(Gitlab::Metrics::System).to receive(:file_descriptor_count)
      expect(Gitlab::Metrics::System).to receive(:memory_usage)
      expect(Gitlab::Metrics::System).to receive(:max_open_file_descriptors)
      expect(sampler).to receive(:sample_gc)

      sampler.sample
    end

    it 'adds a metric containing the process resident memory bytes' do
      expect(Gitlab::Metrics::System).to receive(:memory_usage).and_return(9000)

      expect(sampler.metrics[:process_resident_memory_bytes]).to receive(:set).with({}, 9000)

      sampler.sample
    end

    it 'adds a metric containing the amount of open file descriptors' do
      expect(Gitlab::Metrics::System).to receive(:file_descriptor_count)
                                           .and_return(4)

      expect(sampler.metrics[:file_descriptors]).to receive(:set).with({}, 4)

      sampler.sample
    end

    it 'adds a metric containing the process total cpu time' do
      expect(Gitlab::Metrics::System).to receive(:cpu_time).and_return(0.51)
      expect(sampler.metrics[:process_cpu_seconds_total]).to receive(:set).with({}, 0.51)

      sampler.sample
    end

    it 'adds a metric containing the process max file descriptors' do
      expect(Gitlab::Metrics::System).to receive(:max_open_file_descriptors).and_return(1024)
      expect(sampler.metrics[:process_max_fds]).to receive(:set).with({}, 1024)

      sampler.sample
    end

    it 'clears any GC profiles' do
      expect(GC::Profiler).to receive(:clear).at_least(:once)

      sampler.sample
    end
  end

  describe '#sample_gc' do
    let!(:sampler) { described_class.new(5) }

    let(:gc_reports) { [{ GC_TIME: 0.1 }, { GC_TIME: 0.2 }, { GC_TIME: 0.3 }] }

    it 're-enables GC::Profiler if needed' do
      expect(GC::Profiler).to receive(:enable)

      sampler.sample
    end

    it 'observes GC cycles time' do
      expect(sampler).to receive(:sample_gc_reports).and_return(gc_reports)

      expect(sampler.metrics[:gc_duration_seconds]).to receive(:observe).with({}, 0.1).ordered
      expect(sampler.metrics[:gc_duration_seconds]).to receive(:observe).with({}, 0.2).ordered
      expect(sampler.metrics[:gc_duration_seconds]).to receive(:observe).with({}, 0.3).ordered

      sampler.sample
    end

    it 'adds a metric containing garbage collection statistics' do
      GC.stat.keys.each do |key|
        expect(sampler.metrics[key]).to receive(:set).with({}, anything)
      end

      sampler.sample
    end
  end
end
