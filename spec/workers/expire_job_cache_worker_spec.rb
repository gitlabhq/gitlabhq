# frozen_string_literal: true

require 'spec_helper'

describe ExpireJobCacheWorker do
  set(:pipeline) { create(:ci_empty_pipeline) }
  let(:project) { pipeline.project }

  subject { described_class.new }

  describe '#perform' do
    context 'with a job in the pipeline' do
      let(:job) { create(:ci_build, pipeline: pipeline) }

      it 'invalidates Etag caching for the job path' do
        pipeline_path = "/#{project.full_path}/pipelines/#{pipeline.id}.json"
        job_path = "/#{project.full_path}/builds/#{job.id}.json"

        expect_any_instance_of(Gitlab::EtagCaching::Store).to receive(:touch).with(pipeline_path)
        expect_any_instance_of(Gitlab::EtagCaching::Store).to receive(:touch).with(job_path)

        subject.perform(job.id)
      end
    end

    context 'when there is no job in the pipeline' do
      it 'does not change the etag store' do
        expect(Gitlab::EtagCaching::Store).not_to receive(:new)

        subject.perform(9999)
      end
    end
  end
end
