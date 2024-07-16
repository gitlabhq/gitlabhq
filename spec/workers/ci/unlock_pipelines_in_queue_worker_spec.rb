# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UnlockPipelinesInQueueWorker, :unlock_pipelines, :clean_gitlab_redis_shared_state, feature_category: :job_artifacts do
  let(:worker) { described_class.new }

  it 'is a limited capacity worker' do
    expect(described_class.new).to be_a(LimitedCapacity::Worker)
  end

  describe '#perform_work' do
    let(:service) { instance_double('Ci::UnlockPipelineService') }

    it 'pops the oldest pipeline ID from the queue and unlocks it' do
      pipeline_1 = create(:ci_pipeline, :artifacts_locked)
      pipeline_2 = create(:ci_pipeline, :artifacts_locked)

      enqueue_timestamp = nil
      travel_to(3.minutes.ago) do
        enqueue_timestamp = Time.current.utc.to_i
        Ci::UnlockPipelineRequest.enqueue(pipeline_1.id)
      end

      Ci::UnlockPipelineRequest.enqueue(pipeline_2.id)

      expect(Ci::UnlockPipelineService).to receive(:new).with(pipeline_1).and_return(service)
      expect(service)
        .to receive(:execute)
        .and_return(
          status: :success,
          skipped_already_leased: false,
          skipped_already_unlocked: false,
          exec_timeout: false,
          unlocked_job_artifacts: 3,
          unlocked_pipeline_artifacts: 2
        )

      expect(worker).to receive(:log_extra_metadata_on_done).with(:pipeline_id, pipeline_1.id)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:project, pipeline_1.project.full_path)

      unlock_timestamp = Time.current.utc
      unlock_wait_time = unlock_timestamp.to_i - enqueue_timestamp
      expect(worker).to receive(:log_extra_metadata_on_done).with(:unlock_wait_time, unlock_wait_time)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:remaining_pending, 1)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:skipped_already_leased, false)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:skipped_already_unlocked, false)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:exec_timeout, false)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:unlocked_job_artifacts, 3)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:unlocked_pipeline_artifacts, 2)

      travel_to(unlock_timestamp) do
        expect { worker.perform_work }
          .to change { pipeline_ids_waiting_to_be_unlocked }
          .from([pipeline_1.id, pipeline_2.id])
          .to([pipeline_2.id])
      end
    end

    context 'when queue is empty' do
      it 'does nothing but still logs information' do
        expect(Ci::UnlockPipelineService).not_to receive(:new)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:remaining_pending, 0)

        worker.perform_work
      end
    end

    context 'when pipeline ID does not exist' do
      before do
        Ci::UnlockPipelineRequest.enqueue(9999)
      end

      it 'does nothing' do
        expect(Ci::UnlockPipelineService).not_to receive(:new)
        expect(worker).not_to receive(:log_extra_metadata_on_done)

        worker.perform_work
      end
    end
  end

  describe '#remaining_work_count' do
    subject { worker.remaining_work_count }

    context 'and there are remaining unlock pipeline requests' do
      before do
        Ci::UnlockPipelineRequest.enqueue(123)
      end

      it { is_expected.to eq(1) }
    end

    context 'and there are no remaining unlock pipeline requests' do
      it { is_expected.to eq(0) }
    end
  end

  describe '#max_running_jobs' do
    subject { worker.max_running_jobs }

    before do
      stub_feature_flags(
        ci_unlock_pipelines_extra_low: false,
        ci_unlock_pipelines: false,
        ci_unlock_pipelines_medium: false,
        ci_unlock_pipelines_high: false
      )
    end

    it { is_expected.to eq(0) }

    context 'when ci_unlock_pipelines_extra_low flag is enabled' do
      before do
        stub_feature_flags(ci_unlock_pipelines_extra_low: true)
      end

      it { is_expected.to eq(described_class::MAX_RUNNING_EXTRA_LOW) }
    end

    context 'when ci_unlock_pipelines flag is enabled' do
      before do
        stub_feature_flags(ci_unlock_pipelines: true)
      end

      it { is_expected.to eq(described_class::MAX_RUNNING_LOW) }
    end

    context 'when ci_unlock_pipelines_medium flag is enabled' do
      before do
        stub_feature_flags(ci_unlock_pipelines_medium: true)
      end

      it { is_expected.to eq(described_class::MAX_RUNNING_MEDIUM) }
    end

    context 'when ci_unlock_pipelines_high flag is enabled' do
      before do
        stub_feature_flags(ci_unlock_pipelines_high: true)
      end

      it { is_expected.to eq(described_class::MAX_RUNNING_HIGH) }
    end
  end
end
