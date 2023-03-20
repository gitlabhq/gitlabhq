# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UpdateLockedUnknownArtifactsWorker, feature_category: :build_artifacts do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'executes an instance of Ci::JobArtifacts::UpdateUnknownLockedStatusService' do
      expect_next_instance_of(Ci::JobArtifacts::UpdateUnknownLockedStatusService) do |instance|
        expect(instance).to receive(:execute).and_call_original
      end

      expect(worker).to receive(:log_extra_metadata_on_done).with(:removed_count, 0)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:locked_count, 0)

      worker.perform
    end

    context 'with the ci_job_artifacts_backlog_work flag shut off' do
      before do
        stub_feature_flags(ci_job_artifacts_backlog_work: false)
      end

      it 'does not instantiate a new Ci::JobArtifacts::UpdateUnknownLockedStatusService' do
        expect(Ci::JobArtifacts::UpdateUnknownLockedStatusService).not_to receive(:new)

        worker.perform
      end

      it 'does not log any artifact counts' do
        expect(worker).not_to receive(:log_extra_metadata_on_done)

        worker.perform
      end

      it 'does not query the database' do
        query_count = ActiveRecord::QueryRecorder.new { worker.perform }.count

        expect(query_count).to eq(0)
      end
    end
  end
end
