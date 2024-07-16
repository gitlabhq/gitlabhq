# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RefreshBuildArtifactsSizeStatisticsWorker, feature_category: :job_artifacts do
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
          id: 99,
          project_id: 77,
          last_job_artifact_id: 123
        )
      end

      it 'logs refresh information' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:refresh_id, refresh.id)
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

    before do
      stub_feature_flags(
        projects_build_artifacts_size_refresh: false,
        projects_build_artifacts_size_refresh_medium: false,
        projects_build_artifacts_size_refresh_high: false
      )
    end

    it { is_expected.to eq(0) }

    context 'when projects_build_artifacts_size_refresh flag is enabled' do
      before do
        stub_feature_flags(projects_build_artifacts_size_refresh: true)
      end

      it { is_expected.to eq(described_class::MAX_RUNNING_LOW) }
    end

    context 'when projects_build_artifacts_size_refresh_medium flag is enabled' do
      before do
        stub_feature_flags(projects_build_artifacts_size_refresh_medium: true)
      end

      it { is_expected.to eq(described_class::MAX_RUNNING_MEDIUM) }
    end

    context 'when projects_build_artifacts_size_refresh_high flag is enabled' do
      before do
        stub_feature_flags(projects_build_artifacts_size_refresh_high: true)
      end

      it { is_expected.to eq(described_class::MAX_RUNNING_HIGH) }
    end
  end
end
