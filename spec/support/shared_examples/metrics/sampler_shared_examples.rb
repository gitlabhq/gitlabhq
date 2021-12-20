# frozen_string_literal: true

RSpec.shared_examples 'metrics sampler' do |env_prefix|
  context 'when sampling interval is passed explicitly' do
    subject(:sampler) { described_class.new(interval: 42, logger: double) }

    specify { expect(sampler.interval).to eq(42) }
  end

  context 'when sampling interval is passed through the environment' do
    subject(:sampler) { described_class.new(logger: double) }

    before do
      stub_env("#{env_prefix}_INTERVAL_SECONDS", '42')
    end

    specify { expect(sampler.interval).to eq(42) }
  end

  context 'when no sampling interval is passed anywhere' do
    subject(:sampler) { described_class.new(logger: double) }

    it 'uses the hardcoded default' do
      expect(sampler.interval).to eq(described_class::DEFAULT_SAMPLING_INTERVAL_SECONDS)
    end
  end

  describe '#start' do
    include WaitHelpers

    subject(:sampler) { described_class.new(interval: 0.1) }

    it 'calls the sample method on the sampler thread' do
      sampling_threads = []
      expect(sampler).to receive(:sample).at_least(:once) { sampling_threads << Thread.current }

      sampler.start

      wait_for('sampler has sampled', max_wait_time: 3) { sampling_threads.any? }
      expect(sampling_threads.first.name).to eq(sampler.thread_name)

      sampler.stop
    end

    context 'with warmup set to true' do
      subject(:sampler) { described_class.new(interval: 0.1, warmup: true) }

      it 'calls the sample method first on the caller thread' do
        sampling_threads = []
        current_thread = Thread.current
        # Instead of sampling, we're keeping track of which thread the sampling happened on.
        # We want the first sample to be on the spec thread, which would mean a blocking sample
        # before the actual sampler thread starts.
        expect(sampler).to receive(:sample).at_least(:once) { sampling_threads << Thread.current }

        sampler.start

        wait_for('sampler has sampled', max_wait_time: 3) { sampling_threads.size == 2 }

        expect(sampling_threads.first).to be(current_thread)
        expect(sampling_threads.last.name).to eq(sampler.thread_name)

        sampler.stop
      end
    end
  end

  describe '#safe_sample' do
    let(:logger) { Logger.new(File::NULL) }

    subject(:sampler) { described_class.new(logger: logger) }

    it 'calls #sample once' do
      expect(sampler).to receive(:sample)

      sampler.safe_sample
    end

    context 'when sampling fails with error' do
      before do
        expect(sampler).to receive(:sample).and_raise "something failed"
      end

      it 'recovers from errors' do
        expect { sampler.safe_sample }.not_to raise_error
      end

      context 'with logger' do
        let(:logger) { double('logger') }

        it 'logs errors' do
          expect(logger).to receive(:warn).with(an_instance_of(String))

          expect { sampler.safe_sample }.not_to raise_error
        end
      end
    end
  end
end
