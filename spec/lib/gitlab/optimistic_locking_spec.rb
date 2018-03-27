require 'spec_helper'

describe Gitlab::OptimisticLocking do
  let!(:pipeline) { create(:ci_pipeline) }
  let!(:pipeline2) { Ci::Pipeline.find(pipeline.id) }

  describe '#retry_lock' do
    it 'does not reload object if state changes' do
      expect(pipeline).not_to receive(:reload)
      expect(pipeline).to receive(:succeed).and_call_original

      described_class.retry_lock(pipeline) do |subject|
        subject.succeed
      end
    end

    it 'retries action if exception is raised' do
      pipeline.succeed

      expect(pipeline2).to receive(:reload).and_call_original
      expect(pipeline2).to receive(:drop).twice.and_call_original

      described_class.retry_lock(pipeline2) do |subject|
        subject.drop
      end
    end

    it 'raises exception when too many retries' do
      expect(pipeline).to receive(:drop).twice.and_call_original

      expect do
        described_class.retry_lock(pipeline, 1) do |subject|
          subject.lock_version = 100
          subject.drop
        end
      end.to raise_error(ActiveRecord::StaleObjectError)
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
