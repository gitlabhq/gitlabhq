# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineSuccessUnlockArtifactsWorker, feature_category: :build_artifacts do
  describe '#perform' do
    subject(:perform) { described_class.new.perform(pipeline_id) }

    include_examples 'an idempotent worker' do
      subject(:idempotent_perform) { perform_multiple(pipeline.id, exec_times: 2) }

      let!(:older_pipeline) do
        create(:ci_pipeline, :success, :with_job, locked: :artifacts_locked).tap do |pipeline|
          create(:ci_job_artifact, job: pipeline.builds.first)
        end
      end

      let!(:pipeline) do
        create(:ci_pipeline, :success, :with_job, ref: older_pipeline.ref, tag: older_pipeline.tag, project: older_pipeline.project, locked: :unlocked).tap do |pipeline|
          create(:ci_job_artifact, job: pipeline.builds.first)
        end
      end

      it 'unlocks the artifacts from older pipelines' do
        expect { idempotent_perform }.to change { older_pipeline.reload.locked }.from('artifacts_locked').to('unlocked')
      end
    end

    context 'when pipeline exists' do
      let!(:pipeline) { create(:ci_pipeline, :success, :with_job) }
      let(:pipeline_id) { pipeline.id }

      before do
        allow(Ci::Pipeline).to receive(:find_by_id).with(pipeline.id).and_return(pipeline)
        allow(pipeline).to receive(:has_erasable_artifacts?).and_return(has_erasable_artifacts)
      end

      context 'when pipeline has erasable artifacts' do
        let(:has_erasable_artifacts) { true }

        it 'calls the unlock service' do
          service = spy(Ci::UnlockArtifactsService)
          expect(Ci::UnlockArtifactsService).to receive(:new).and_return(service)

          perform

          expect(service).to have_received(:execute)
        end
      end

      context 'when pipeline has no erasable artifacts' do
        let(:has_erasable_artifacts) { false }

        it 'does not call the unlock service' do
          expect(Ci::UnlockArtifactsService).not_to receive(:new)

          perform
        end
      end
    end

    context 'when pipeline does not exist' do
      let(:pipeline_id) { non_existing_record_id }

      it 'does not call service' do
        expect(Ci::UnlockArtifactsService).not_to receive(:new)

        perform
      end
    end
  end

  describe '.database_health_check_attrs' do
    it 'defines expected db health check attrs' do
      expect(described_class.database_health_check_attrs).to eq(
        gitlab_schema: :gitlab_ci,
        delay_by: described_class::DEFAULT_DEFER_DELAY,
        tables: [:ci_job_artifacts],
        block: nil
      )
    end
  end

  context 'with stop signal from database health check' do
    let(:pipeline_id) { non_existing_record_id }
    let(:health_signal_attrs) { described_class.database_health_check_attrs }
    let(:setter) { instance_double('Sidekiq::Job::Setter') }

    around do |example|
      with_sidekiq_server_middleware do |chain|
        chain.add Gitlab::SidekiqMiddleware::SkipJobs
        Sidekiq::Testing.inline! { example.run }
      end
    end

    before do
      stub_feature_flags("drop_sidekiq_jobs_#{described_class.name}": false)

      stop_signal = instance_double("Gitlab::Database::HealthStatus::Signals::Stop", stop?: true)
      allow(Gitlab::Database::HealthStatus).to receive(:evaluate).and_return([stop_signal])
    end

    it 'defers the job by set time' do
      expect_next_instance_of(described_class) do |worker|
        expect(worker).not_to receive(:perform).with(pipeline_id)
      end

      # stub the setter to avoid a call-loop between `.call` and `.perform_in` inside the SkipJobs middleware
      # as Sidekiq::Testing.inline! would immediately process scheduled jobs.
      expect(described_class).to receive(:deferred).and_return(setter)
      expect(setter).to receive(:perform_in).with(health_signal_attrs[:delay_by], pipeline_id)

      described_class.perform_async(pipeline_id)
    end
  end
end
