# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RefreshBuildArtifactsSizeStatisticsWorker do
  let(:worker) { described_class.new }

  describe '#perform_work' do
    before do
      expect_next_instance_of(Projects::RefreshBuildArtifactsSizeStatisticsService) do |instance|
        expect(instance).to receive(:execute).and_return(refresh)
      end
    end

    context 'when refresh job is present' do
      let(:refresh) do
        build(
          :project_build_artifacts_size_refresh,
          :running,
          project_id: 77,
          last_job_artifact_id: 123
        )
      end

      it 'logs refresh information' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:project_id, refresh.project_id)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:last_job_artifact_id, refresh.last_job_artifact_id)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:last_batch, refresh.destroyed?)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:refresh_started_at, refresh.refresh_started_at)

        worker.perform_work
      end
    end

    context 'when refresh job is not present' do
      let(:refresh) { nil }

      it 'logs refresh information' do
        expect(worker).not_to receive(:log_extra_metadata_on_done)

        worker.perform_work
      end
    end
  end

  describe '#remaining_work_count' do
    subject { worker.remaining_work_count }

    context 'and there are remaining refresh jobs' do
      before do
        create_list(:project_build_artifacts_size_refresh, 2, :pending)
      end

      it { is_expected.to eq(1) }
    end

    context 'and there are no remaining refresh jobs' do
      it { is_expected.to eq(0) }
    end
  end

  describe '#max_running_jobs' do
    subject { worker.max_running_jobs }

    it { is_expected.to eq(10) }

    context 'when projects_build_artifacts_size_refresh flag is disabled' do
      before do
        stub_feature_flags(projects_build_artifacts_size_refresh: false)
      end

      it { is_expected.to eq(0) }
    end
  end
end
