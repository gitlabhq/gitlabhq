# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::OptimisticLocking do
  let!(:pipeline) { create(:ci_pipeline) }
  let!(:pipeline2) { Ci::Pipeline.find(pipeline.id) }
  let(:histogram) { spy('prometheus metric') }

  before do
    allow(described_class)
      .to receive(:retry_lock_histogram)
      .and_return(histogram)
  end

  describe '#retry_lock' do
    let(:name) { 'optimistic_locking_spec' }

    context 'when state changed successfully without retries' do
      subject do
        described_class.retry_lock(pipeline, name: name) do |lock_subject|
          lock_subject.succeed
        end
      end

      it 'does not reload object' do
        expect(pipeline).not_to receive(:reset)
        expect(pipeline).to receive(:succeed).and_call_original

        subject
      end

      it 'does not create log record' do
        expect(described_class.retry_lock_logger).not_to receive(:info)

        subject
      end

      it 'adds number of retries to histogram' do
        subject

        expect(histogram).to have_received(:observe).with({}, 0)
      end
    end

    context 'when at least one retry happened, the change succeeded' do
      subject do
        described_class.retry_lock(pipeline2, name: 'optimistic_locking_spec') do |lock_subject|
          lock_subject.drop
        end
      end

      before do
        pipeline.succeed
      end

      it 'completes the action' do
        expect(pipeline2).to receive(:reset).and_call_original
        expect(pipeline2).to receive(:drop).twice.and_call_original

        subject
      end

      it 'creates a single log record' do
        expect(described_class.retry_lock_logger)
          .to receive(:info)
          .once
          .with(hash_including(:time_s, name: name, retries: 1))

        subject
      end

      it 'adds number of retries to histogram' do
        subject

        expect(histogram).to have_received(:observe).with({}, 1)
      end
    end

    context 'when MAX_RETRIES attempts exceeded' do
      subject do
        described_class.retry_lock(pipeline, max_retries, name: name) do |lock_subject|
          lock_subject.lock_version = 100
          lock_subject.drop
        end
      end

      let(:max_retries) { 2 }

      it 'raises an exception' do
        expect(pipeline).to receive(:drop).exactly(max_retries + 1).times.and_call_original

        expect { subject }.to raise_error(ActiveRecord::StaleObjectError)
      end

      it 'creates a single log record' do
        expect(described_class.retry_lock_logger)
          .to receive(:info)
          .once
          .with(hash_including(:time_s, name: name, retries: max_retries))

        expect { subject }.to raise_error(ActiveRecord::StaleObjectError)
      end

      it 'adds number of retries to histogram' do
        expect { subject }.to raise_error(ActiveRecord::StaleObjectError)

        expect(histogram).to have_received(:observe).with({}, max_retries)
      end
    end
  end

  describe '#retry_optimistic_lock' do
    context 'when locking module is mixed in' do
      let(:unlockable) do
        Class.new.include(described_class).new
      end

      it 'is an alias for retry_lock' do
        expect(unlockable.method(:retry_optimistic_lock))
          .to eq unlockable.method(:retry_lock)
      end
    end
  end
end
