require 'spec_helper'

describe BuildTraceSectionsWorker do
  describe '#perform' do
    context 'when build exists' do
      let!(:build) { create(:ci_build) }

      it 'updates trace sections' do
        expect_any_instance_of(Ci::Build)
          .to receive(:parse_trace_sections!)

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
