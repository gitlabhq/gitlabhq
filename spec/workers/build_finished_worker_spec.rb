# frozen_string_literal: true

require 'spec_helper'

describe BuildFinishedWorker do
  subject { described_class.new.perform(build.id) }

  describe '#perform' do
    let(:build) { create(:ci_build, :success, pipeline: create(:ci_pipeline)) }

    context 'when build exists' do
      let!(:build) { create(:ci_build) }

      it 'calculates coverage and calls hooks' do
        expect(BuildTraceSectionsWorker)
          .to receive(:new).ordered.and_call_original
        expect(BuildCoverageWorker)
          .to receive(:new).ordered.and_call_original

        expect_any_instance_of(BuildTraceSectionsWorker).to receive(:perform)
        expect_any_instance_of(BuildCoverageWorker).to receive(:perform)
        expect(BuildHooksWorker).to receive(:perform_async)
        expect(ArchiveTraceWorker).to receive(:perform_async)
        expect(ExpirePipelineCacheWorker).to receive(:perform_async)
        expect(ChatNotificationWorker).not_to receive(:perform_async)
        expect(Ci::BuildReportResultWorker).not_to receive(:perform)

        subject
      end
    end

    context 'when build does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(123) }
          .not_to raise_error
      end
    end

    context 'when build has a chat' do
      let(:build) { create(:ci_build, :success, pipeline: create(:ci_pipeline, source: :chat)) }

      it 'schedules a ChatNotification job' do
        expect(ChatNotificationWorker).to receive(:perform_async).with(build.id)

        subject
      end
    end

    context 'when build has a test report' do
      let(:build) { create(:ci_build, :test_reports) }

      it 'schedules a BuildReportResult job' do
        expect_next_instance_of(Ci::BuildReportResultWorker) do |worker|
          expect(worker).to receive(:perform).with(build.id)
        end

        subject
      end
    end
  end
end
