# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BuildQueueWorker, feature_category: :continuous_integration do
  describe '#perform' do
    context 'when build exists' do
      let!(:build) { create(:ci_build) }

      it 'ticks runner queue value' do
        expect_next_instance_of(Ci::UpdateBuildQueueService) do |instance|
          expect(instance).to receive(:tick).with(build)
        end

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

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky
end
