# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BuildFinishedWorker do
  subject { described_class.new.perform(build.id) }

  describe '#perform' do
    let(:build) { create(:ci_build, :success, pipeline: create(:ci_pipeline)) }

    context 'when build exists' do
      let!(:build) { create(:ci_build) }

      it 'calculates coverage and calls hooks', :aggregate_failures do
        trace_worker = double('trace worker')
        coverage_worker = double('coverage worker')

        allow(BuildTraceSectionsWorker).to receive(:new).and_return(trace_worker)
        allow(BuildCoverageWorker).to receive(:new).and_return(coverage_worker)

        # Unfortunately, `ordered` does not seem to work when called within `allow_next_instance_of`
        # so we're doing this the long and dirty way
        expect(trace_worker).to receive(:perform).ordered
        expect(coverage_worker).to receive(:perform).ordered

        expect_next_instance_of(Ci::BuildReportResultWorker) do |instance|
          expect(instance).to receive(:perform)
        end
        expect_next_instance_of(Ci::TestCasesService) do |instance|
          expect(instance).to receive(:execute)
        end

        expect(BuildHooksWorker).to receive(:perform_async)
        expect(ExpirePipelineCacheWorker).to receive(:perform_async)
        expect(ChatNotificationWorker).not_to receive(:perform_async)
        expect(ArchiveTraceWorker).to receive(:perform_in)

        subject
      end
    end

    context 'when build does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(non_existing_record_id) }
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
  end
end
