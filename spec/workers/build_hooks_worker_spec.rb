# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BuildHooksWorker do
  describe '#perform' do
    context 'when build exists' do
      let!(:build) { create(:ci_build) }

      it 'calls build hooks' do
        expect_any_instance_of(Ci::Build)
          .to receive(:execute_hooks)

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

  describe '.perform_async' do
    context 'when delayed_perform_for_build_hooks_worker feature flag is disabled' do
      before do
        stub_feature_flags(delayed_perform_for_build_hooks_worker: false)
      end

      it 'does not call perform_in' do
        expect(described_class).not_to receive(:perform_in)
      end
    end

    it 'delays scheduling a job by calling perform_in' do
      expect(described_class).to receive(:perform_in).with(described_class::DATA_CONSISTENCY_DELAY.second, 123)

      described_class.perform_async(123)
    end
  end

  it_behaves_like 'worker with data consistency',
                  described_class,
                  feature_flag: :load_balancing_for_build_hooks_worker,
                  data_consistency: :delayed
end
