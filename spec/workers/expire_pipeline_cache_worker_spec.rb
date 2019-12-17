# frozen_string_literal: true

require 'spec_helper'

describe ExpirePipelineCacheWorker do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  subject { described_class.new }

  describe '#perform' do
    it 'executes the service' do
      expect_any_instance_of(Ci::ExpirePipelineCacheService).to receive(:execute).with(pipeline).and_call_original

      subject.perform(pipeline.id)
    end

    it "doesn't do anything if the pipeline not exist" do
      expect_any_instance_of(Ci::ExpirePipelineCacheService).not_to receive(:execute)
      expect_any_instance_of(Gitlab::EtagCaching::Store).not_to receive(:touch)

      subject.perform(617748)
    end
  end
end
