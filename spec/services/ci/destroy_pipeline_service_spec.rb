# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::DestroyPipelineService do
  let_it_be(:project) { create(:project, :repository) }

  let!(:pipeline) { create(:ci_pipeline, :success, project: project, sha: project.commit.id) }

  subject { described_class.new(project, user).execute(pipeline) }

  context 'user is owner' do
    let(:user) { project.owner }

    it 'destroys the pipeline' do
      subject

      expect { pipeline.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'clears the cache', :use_clean_rails_redis_caching do
      create(:commit_status, :success, pipeline: pipeline, ref: pipeline.ref)

      expect(project.pipeline_status.has_status?).to be_truthy

      subject

      # We need to reset lazy_latest_pipeline cache to simulate a new request
      BatchLoader::Executor.clear_current

      # Need to use find to avoid memoization
      expect(Project.find(project.id).pipeline_status.has_status?).to be_falsey
    end

    it 'does not log an audit event' do
      expect { subject }.not_to change { AuditEvent.count }
    end

    context 'when the pipeline has jobs' do
      let!(:build) { create(:ci_build, project: project, pipeline: pipeline) }

      it 'destroys associated jobs' do
        subject

        expect { build.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'destroys associated stages' do
        stages = pipeline.stages

        subject

        expect(stages).to all(raise_error(ActiveRecord::RecordNotFound))
      end

      context 'when job has artifacts' do
        let!(:artifact) { create(:ci_job_artifact, :archive, job: build) }

        it 'destroys associated artifacts' do
          subject

          expect { artifact.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'inserts deleted objects for object storage files' do
          expect { subject }.to change { Ci::DeletedObject.count }
        end
      end
    end

    context 'when pipeline is in cancelable state' do
      before do
        allow(pipeline).to receive(:cancelable?).and_return(true)
      end

      it 'cancels the pipeline' do
        expect(pipeline).to receive(:cancel_running)

        subject
      end

      context 'when cancel_pipelines_prior_to_destroy is disabled' do
        before do
          stub_feature_flags(cancel_pipelines_prior_to_destroy: false)
        end

        it "doesn't cancel the pipeline" do
          expect(pipeline).not_to receive(:cancel_running)

          subject
        end
      end
    end
  end

  context 'user is not owner' do
    let(:user) { create(:user) }

    it 'raises an exception' do
      expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end
end
