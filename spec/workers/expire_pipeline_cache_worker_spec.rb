# frozen_string_literal: true

require 'spec_helper'

describe ExpirePipelineCacheWorker do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  subject { described_class.new }

  describe '#perform' do
    it 'executes the service' do
      expect_next_instance_of(Ci::ExpirePipelineCacheService) do |instance|
        expect(instance).to receive(:execute).with(pipeline).and_call_original
      end

      subject.perform(pipeline.id)
    end

    it "doesn't do anything if the pipeline not exist" do
      expect_any_instance_of(Ci::ExpirePipelineCacheService).not_to receive(:execute)
      expect_any_instance_of(Gitlab::EtagCaching::Store).not_to receive(:touch)

      subject.perform(617748)
    end

    it "doesn't do anything if the pipeline cannot be cached" do
      allow_any_instance_of(Ci::Pipeline).to receive(:cacheable?).and_return(false)

      expect_any_instance_of(Ci::ExpirePipelineCacheService).not_to receive(:execute)
      expect_any_instance_of(Gitlab::EtagCaching::Store).not_to receive(:touch)

      subject.perform(pipeline.id)
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [pipeline.id] }
    end
  end
end
