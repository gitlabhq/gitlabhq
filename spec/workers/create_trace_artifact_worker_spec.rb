require 'spec_helper'

describe CreateTraceArtifactWorker do
  describe '#perform' do
    subject { described_class.new.perform(job&.id) }

    context 'when job is found' do
      let(:job) { create(:ci_build) }

      it 'executes service' do
        expect_any_instance_of(Ci::CreateTraceArtifactService)
          .to receive(:execute)

        subject
      end
    end

    context 'when job is not found' do
      let(:job) { nil }

      it 'does not execute service' do
        expect_any_instance_of(Ci::CreateTraceArtifactService)
          .not_to receive(:execute)

        subject
      end
    end
  end
end
