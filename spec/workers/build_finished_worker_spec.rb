require 'spec_helper'

describe BuildFinishedWorker do
  describe '#perform' do
    context 'when build exists' do
      let(:build) { create(:ci_build) }

      it 'calculates coverage and calls hooks' do
        expect(BuildCoverageWorker)
          .to receive(:new).ordered.and_call_original
        expect(BuildHooksWorker)
          .to receive(:new).ordered.and_call_original

        expect_any_instance_of(BuildCoverageWorker)
          .to receive(:perform)
        expect_any_instance_of(BuildHooksWorker)
          .to receive(:perform)

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
