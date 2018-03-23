require 'spec_helper'

describe ArchiveTraceWorker do
  describe '#perform' do
    subject { described_class.new.perform(job&.id) }

    context 'when job is found' do
      let(:job) { create(:ci_build) }

      it 'executes service' do
        expect_any_instance_of(Gitlab::Ci::Trace).to receive(:archive!)

        subject
      end
    end

    context 'when job is not found' do
      let(:job) { nil }

      it 'does not execute service' do
        expect_any_instance_of(Gitlab::Ci::Trace).not_to receive(:archive!)

        subject
      end
    end
  end
end
