# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeabilityCheckBatchWorker, feature_category: :code_review_workflow do
  subject { described_class.new }

  let_it_be(:project) { create(:project) }
  let_it_be(:another_project) { create(:project) }
  let_it_be(:user) { create(:user, developer_of: project, reporter_of: another_project) }

  describe '#perform' do
    context 'when some merge_requests do not exist' do
      it 'ignores unknown merge request ids' do
        expect(MergeRequests::MergeabilityCheckService).not_to receive(:new)

        expect(Sidekiq.logger).not_to receive(:error)

        subject.perform([1234, 5678], user.id)
      end
    end

    context 'when some merge_requests needs mergeability checks' do
      def merge_status_update_count(recorder, status)
        recorder.occurrences_starting_with(
          "UPDATE \"merge_requests\" SET \"merge_status\" = '#{status}'"
        ).values.sum
      end

      let(:mr1) do
        create(:merge_request, :unique_branches, source_project: project, merge_status: :unchecked)
      end

      let(:mr2) do
        create(:merge_request, :unique_branches, source_project: another_project, merge_status: :unchecked)
      end

      let(:mr3) do
        create(:merge_request, :unique_branches, source_project: project, merge_status: :can_be_merged)
      end

      let(:mr4) do
        create(:merge_request, :unique_branches, source_project: project, merge_status: :cannot_be_merged_recheck)
      end

      let(:mr5) do
        create(:merge_request, :unique_branches, source_project: project, merge_status: :cannot_be_merged_recheck)
      end

      let(:mr6) do
        create(:merge_request, :unique_branches, source_project: project, merge_status: :unchecked)
      end

      it 'batch updates merge_status to checking with 2 queries regardless of MR count' do
        recorder = ActiveRecord::QueryRecorder.new do
          subject.perform(
            [mr1.id, mr4.id, mr5.id, mr6.id],
            user.id
          )
        end

        expect(merge_status_update_count(recorder, 'checking')).to eq(1)
        expect(merge_status_update_count(recorder, 'cannot_be_merged_rechecking')).to eq(1)
      end

      it 'executes MergeabilityCheckService on merge requests that needs to be checked' do
        expect_next_instance_of(MergeRequests::MergeabilityCheckService, mr1) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success)
        end
        expect(MergeRequests::MergeabilityCheckService).not_to receive(:new).with(mr2.id)
        expect(MergeRequests::MergeabilityCheckService).not_to receive(:new).with(mr3.id)
        expect(MergeRequests::MergeabilityCheckService).not_to receive(:new).with(1234)

        subject.perform([mr1.id, mr2.id, mr3.id, 1234], user.id)
      end

      it 'structurally logs a failed mergeability check' do
        expect_next_instance_of(MergeRequests::MergeabilityCheckService, mr1) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.error(message: "solar flares"))
        end

        expect(Sidekiq.logger).to receive(:error).once
          .with(
            merge_request_id: mr1.id,
            worker: described_class.to_s,
            message: 'Failed to check mergeability of merge request: solar flares')

        subject.perform([mr1.id], user.id)
      end

      context 'when user is nil' do
        let(:user) { nil }

        it 'does not run any mergeability checks' do
          expect(MergeRequests::MergeabilityCheckService).not_to receive(:new)

          subject.perform([mr1.id], user)
        end
      end

      context 'when processing merge requests across multiple projects' do
        let!(:third_project) { create(:project) }
        let!(:fourth_project) { create(:project) }
        let!(:mr1) do
          create(:merge_request, :unique_branches, source_project: project, merge_status: :can_be_merged)
        end

        let!(:mr2) do
          create(:merge_request, :unique_branches, source_project: third_project, merge_status: :can_be_merged)
        end

        let!(:mr3) do
          create(:merge_request, :unique_branches, source_project: fourth_project, merge_status: :can_be_merged)
        end

        before do
          third_project.add_developer(user)
          fourth_project.add_developer(user)
        end

        it 'avoids N+1 queries for permission checks', :request_store do
          # NOTE: merge_statuses are set to can_be_merged to focus on permission checks as
          #  avoiding N+1 with mergeability checks are tricky with update queries.
          control = ActiveRecord::QueryRecorder.new do
            described_class.new.perform([mr1.id], user.id)
          end

          expect do
            described_class.new.perform([mr1.id, mr2.id, mr3.id], user.id)
          end.not_to exceed_query_limit(control)
        end
      end

      context 'when batch_merge_status_updates feature flag is disabled' do
        before do
          stub_feature_flags(batch_merge_status_updates: false)
        end

        it 'updates merge_status individually per merge request' do
          recorder = ActiveRecord::QueryRecorder.new do
            subject.perform(
              [mr1.id, mr4.id, mr5.id, mr6.id],
              user.id
            )
          end

          expect(merge_status_update_count(recorder, 'checking')).to eq(2)
          expect(merge_status_update_count(recorder, 'cannot_be_merged_rechecking')).to eq(2)
        end

        it 'executes MergeabilityCheckService on merge requests that needs to be checked' do
          expect_next_instance_of(MergeRequests::MergeabilityCheckService, mr1) do |service|
            expect(service).to receive(:execute).and_return(ServiceResponse.success)
          end
          expect(MergeRequests::MergeabilityCheckService).not_to receive(:new).with(mr2.id)
          expect(MergeRequests::MergeabilityCheckService).not_to receive(:new).with(mr3.id)
          expect(MergeRequests::MergeabilityCheckService).not_to receive(:new).with(1234)

          subject.perform([mr1.id, mr2.id, mr3.id, 1234], user.id)
        end

        it 'structurally logs a failed mergeability check' do
          expect_next_instance_of(MergeRequests::MergeabilityCheckService, mr1) do |service|
            expect(service).to receive(:execute).and_return(ServiceResponse.error(message: "solar flares"))
          end

          expect(Sidekiq.logger).to receive(:error).once
            .with(
              merge_request_id: mr1.id,
              worker: described_class.to_s,
              message: 'Failed to check mergeability of merge request: solar flares')

          subject.perform([mr1.id], user.id)
        end

        context 'when user is nil' do
          let(:user) { nil }

          it 'does not run any mergeability checks' do
            expect(MergeRequests::MergeabilityCheckService).not_to receive(:new)

            subject.perform([mr1.id], user)
          end
        end
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:merge_request) { create(:merge_request) }
      let(:job_args) { [[merge_request.id], user.id] }

      it 'is mergeable' do
        subject

        expect(merge_request).to be_mergeable
      end
    end
  end
end
