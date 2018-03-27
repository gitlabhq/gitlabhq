require 'spec_helper'

describe BuildFinishedWorker do
  describe '#perform' do
    context 'when build exists' do
      let!(:build) { create(:ci_build) }

      it 'calculates coverage and calls hooks' do
        expect(BuildTraceSectionsWorker)
          .to receive(:new).ordered.and_call_original
        expect(BuildCoverageWorker)
          .to receive(:new).ordered.and_call_original

        expect_any_instance_of(BuildTraceSectionsWorker).to receive(:perform)
        expect_any_instance_of(BuildCoverageWorker).to receive(:perform)
        expect(BuildHooksWorker).to receive(:perform_async)
        expect(ArchiveTraceWorker).to receive(:perform_async)

        described_class.new.perform(build.id)
      end
    end

    context 'when build does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(123) }
          .not_to raise_error
      end
    end
  end
end
