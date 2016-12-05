require 'spec_helper'

describe Gitlab::Ci::Status::Stage::Factory do
  let(:pipeline) { create(:ci_pipeline) }
  let(:stage) { Ci::Stage.new(pipeline, name: 'test') }

  subject do
    described_class.new(stage)
  end

  let(:status) do
    subject.fabricate!
  end

  context 'when stage has a core status' do
    HasStatus::AVAILABLE_STATUSES.each do |core_status|
      context "when core status is #{core_status}" do
        let!(:build) do
          create(:ci_build, pipeline: pipeline, stage: 'test', status: core_status)
        end

        it "fabricates a core status #{core_status}" do
          expect(status).to be_a(
            Gitlab::Ci::Status.const_get(core_status.capitalize))
        end

        it 'extends core status with common pipeline methods' do
          expect(status).to have_details
          expect(status.details_path).to include "pipelines/#{pipeline.id}"
          expect(status.details_path).to include "##{stage.name}"
        end
      end
    end
  end
end
