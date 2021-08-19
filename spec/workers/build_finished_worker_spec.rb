# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BuildFinishedWorker do
  subject { described_class.new.perform(build.id) }

  describe '#perform' do
    context 'when build exists' do
      let_it_be(:build) { create(:ci_build, :success, pipeline: create(:ci_pipeline)) }

      before do
        stub_feature_flags(ci_build_finished_worker_namespace_changed: build.project)
        expect(Ci::Build).to receive(:find_by).with(id: build.id).and_return(build)
      end

      it 'calculates coverage and calls hooks', :aggregate_failures do
        expect(build).to receive(:update_coverage).ordered

        expect_next_instance_of(Ci::BuildReportResultService) do |build_report_result_service|
          expect(build_report_result_service).to receive(:execute).with(build)
        end

        expect(BuildHooksWorker).to receive(:perform_async)
        expect(ChatNotificationWorker).not_to receive(:perform_async)
        expect(Ci::ArchiveTraceWorker).to receive(:perform_in)

        subject
      end

      context 'with ci_build_finished_worker_namespace_changed feature flag disabled' do
        before do
          stub_feature_flags(ci_build_finished_worker_namespace_changed: false)
        end

        it 'calls deprecated worker' do
          expect(ArchiveTraceWorker).to receive(:perform_in)

          subject
        end
      end

      context 'when build is failed' do
        before do
          build.update!(status: :failed)
        end

        it 'adds a todo' do
          expect(::Ci::MergeRequests::AddTodoWhenBuildFailsWorker).to receive(:perform_async)

          subject
        end
      end

      context 'when build has a chat' do
        before do
          build.pipeline.update!(source: :chat)
        end

        it 'schedules a ChatNotification job' do
          expect(ChatNotificationWorker).to receive(:perform_async).with(build.id)

          subject
        end
      end
    end

    context 'when build does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(non_existing_record_id) }
          .not_to raise_error
      end
    end
  end
end
