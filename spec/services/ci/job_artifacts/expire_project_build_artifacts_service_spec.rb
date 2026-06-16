# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::ExpireProjectBuildArtifactsService, feature_category: :job_artifacts do
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:pipeline) { create(:ci_pipeline, :unlocked, project: project) }

  let(:expiry_time) { Time.current }

  RSpec::Matchers.define :have_locked_status do |expected_status|
    match do |job_artifacts|
      predicate = :"#{expected_status}?"
      job_artifacts.all? { |artifact| artifact.__send__(predicate) }
    end
  end

  RSpec::Matchers.define :expire_at do |expected_expiry|
    match do |job_artifacts|
      job_artifacts.all? { |artifact| artifact.expire_at.to_i == expected_expiry.to_i }
    end
  end

  RSpec::Matchers.define :have_no_expiry do
    match do |job_artifacts|
      job_artifacts.all? { |artifact| artifact.expire_at.nil? }
    end
  end

  describe '#execute' do
    subject(:execute) { described_class.new(project.id, expiry_time).execute }

    context 'with job containing erasable artifacts' do
      let_it_be_with_reload(:job) { create(:ci_build, :erasable, pipeline: pipeline) }

      it 'unlocks erasable job artifacts' do
        execute

        expect(job.job_artifacts).to have_locked_status(:artifact_unlocked)
      end

      it 'expires erasable job artifacts' do
        execute

        expect(job.job_artifacts).to expire_at(expiry_time)
      end
    end

    context 'with job containing trace artifacts' do
      let_it_be_with_reload(:job) { create(:ci_build, :trace_artifact, pipeline: pipeline) }

      it 'does not unlock trace artifacts' do
        execute

        expect(job.job_artifacts).to have_locked_status(:artifact_unknown)
      end

      it 'does not expire trace artifacts' do
        execute

        expect(job.job_artifacts).to have_no_expiry
      end
    end

    context 'with job from artifact locked pipeline' do
      let_it_be_with_reload(:job) { create(:ci_build, pipeline: pipeline) }
      let_it_be_with_reload(:locked_artifact) { create(:ci_job_artifact, :locked, job: job) }

      before do
        pipeline.artifacts_locked!
      end

      it 'does not unlock locked artifacts' do
        execute

        expect(job.job_artifacts).to have_locked_status(:artifact_artifacts_locked)
      end

      it 'does not expire locked artifacts' do
        execute

        expect(job.job_artifacts).to have_no_expiry
      end
    end

    context 'with job containing both erasable and trace artifacts' do
      let_it_be_with_reload(:job) { create(:ci_build, pipeline: pipeline) }
      let_it_be_with_reload(:erasable_artifact) { create(:ci_job_artifact, :archive, job: job) }
      let_it_be_with_reload(:trace_artifact) { create(:ci_job_artifact, :trace, job: job) }

      it 'unlocks erasable artifacts' do
        execute

        expect(erasable_artifact.artifact_unlocked?).to be_truthy
      end

      it 'expires erasable artifacts' do
        execute

        expect(erasable_artifact.expire_at.to_i).to eq(expiry_time.to_i)
      end

      it 'does not unlock trace artifacts' do
        execute

        expect(trace_artifact.artifact_unlocked?).to be_falsey
      end

      it 'does not expire trace artifacts' do
        execute

        expect(trace_artifact.expire_at).to be_nil
      end
    end

    context 'with multiple pipelines' do
      let_it_be_with_reload(:job) { create(:ci_build, :erasable, pipeline: pipeline) }

      let_it_be_with_reload(:pipeline2) { create(:ci_pipeline, :unlocked, project: project) }
      let_it_be_with_reload(:job2) { create(:ci_build, :erasable, pipeline: pipeline) }

      it 'unlocks artifacts across pipelines' do
        execute

        expect(job.job_artifacts).to have_locked_status(:artifact_unlocked)
        expect(job2.job_artifacts).to have_locked_status(:artifact_unlocked)
      end

      it 'expires artifacts across pipelines' do
        execute

        expect(job.job_artifacts).to expire_at(expiry_time)
        expect(job2.job_artifacts).to expire_at(expiry_time)
      end
    end

    context 'with artifacts belonging to another project' do
      let_it_be_with_reload(:job) { create(:ci_build, :erasable, pipeline: pipeline) }

      let_it_be_with_reload(:another_project) { create(:project) }
      let_it_be_with_reload(:another_pipeline) { create(:ci_pipeline, project: another_project) }
      let_it_be_with_reload(:another_job) { create(:ci_build, :erasable, pipeline: another_pipeline) }

      it 'does not unlock erasable artifacts in other projects' do
        execute

        expect(another_job.job_artifacts).to have_locked_status(:artifact_unknown)
      end

      it 'does not expire erasable artifacts in other projects' do
        execute

        expect(another_job.job_artifacts).to have_no_expiry
      end
    end
  end
end
