require 'spec_helper'

describe Gitlab::Sherlock::LineProfiler do
  let(:profiler) { described_class.new }

  describe '#profile' do
    it 'runs the profiler when using MRI' do
      allow(profiler).to receive(:mri?).and_return(true)
      allow(profiler).to receive(:profile_mri)

      profiler.profile { 'cats' }
    end

    it 'raises NotImplementedError when profiling an unsupported platform' do
      allow(profiler).to receive(:mri?).and_return(false)

      expect { profiler.profile { 'cats' } }.to raise_error(NotImplementedError)
    end
  end

  describe '#profile_mri' do
    it 'returns an Array containing the return value and profiling samples' do
      allow(profiler).to receive(:lineprof)
        .and_yield
        .and_return({ __FILE__ => [[0, 0, 0, 0]] })

      retval, samples = profiler.profile_mri { 42 }

      expect(retval).to eq(42)
      expect(samples).to eq([])
    end
  end

  describe '#aggregate_rblineprof' do
    let(:raw_samples) do
      { __FILE__ => [[30000, 30000, 5, 0], [15000, 15000, 4, 0]] }
    end

    it 'returns an Array of FileSample objects' do
      samples = profiler.aggregate_rblineprof(raw_samples)

      expect(samples).to be_an_instance_of(Array)
      expect(samples[0]).to be_an_instance_of(Gitlab::Sherlock::FileSample)
    end

    describe 'the first FileSample object' do
      let(:file_sample) do
        profiler.aggregate_rblineprof(raw_samples)[0]
      end

      it 'uses the correct file path' do
        expect(file_sample.file).to eq(__FILE__)
      end

      it 'contains a list of line samples' do
        line_sample = file_sample.line_samples[0]

        expect(line_sample).to be_an_instance_of(Gitlab::Sherlock::LineSample)

        expect(line_sample.duration).to eq(15.0)
        expect(line_sample.events).to eq(4)
      end

      it 'contains the total file execution time' do
        expect(file_sample.duration).to eq(30.0)
      end

      it 'contains the total amount of file events' do
        expect(file_sample.events).to eq(5)
      end
    end
  end
end
