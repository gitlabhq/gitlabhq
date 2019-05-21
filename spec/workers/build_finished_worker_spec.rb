# frozen_string_literal: true

require 'spec_helper'

describe BuildFinishedWorker do
  describe '#perform' do
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

        described_class.new.perform(build.id)
      end
    end

    context 'when build does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(123) }
          .not_to raise_error
      end
    end

    it 'schedules a ChatNotification job for a chat build' do
      build = create(:ci_build, :success, pipeline: create(:ci_pipeline, source: :chat))

      expect(ChatNotificationWorker)
        .to receive(:perform_async)
        .with(build.id)

      described_class.new.perform(build.id)
    end

    it 'does not schedule a ChatNotification job for a regular build' do
      build = create(:ci_build, :success, pipeline: create(:ci_pipeline))

      expect(ChatNotificationWorker)
        .not_to receive(:perform_async)

      described_class.new.perform(build.id)
    end
  end
end
