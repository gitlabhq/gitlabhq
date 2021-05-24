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
    it 'delays scheduling a job by calling perform_in with default delay' do
      expect(described_class).to receive(:perform_in).with(ApplicationWorker::DEFAULT_DELAY_INTERVAL.second, 123)

      described_class.perform_async(123)
    end
  end

  it_behaves_like 'worker with data consistency',
                  described_class,
                  data_consistency: :delayed
end
