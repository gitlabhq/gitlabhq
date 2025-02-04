# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::UpdateReviewerStateService, feature_category: :code_review_workflow do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:current_user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, reviewers: [current_user]) }
  let(:reviewer) { merge_request.merge_request_reviewers.find_by(user_id: current_user.id) }
  let(:project) { merge_request.project }
  let(:service) { described_class.new(project: project, current_user: current_user) }
  let(:state) { 'requested_changes' }
  let(:result) { service.execute(merge_request, state) }

  before do
    project.add_developer(current_user)
  end

  describe '#execute' do
    shared_examples_for 'failed service execution' do
      it 'returns an error' do
        expect(result[:status]).to eq :error
      end

      it_behaves_like 'does not trigger GraphQL subscription mergeRequestReviewersUpdated' do
        let(:action) { result }
      end
    end

    describe 'invalid permissions' do
      let(:service) { described_class.new(project: project, current_user: create(:user)) }

      it_behaves_like 'failed service execution'
    end

    describe 'reviewer exists' do
      it 'returns success' do
        expect(result[:status]).to eq :success
      end

      context 'when updating reviewer state' do
        where(:initial_state, :new_state) do
          'unreviewed'        | 'requested_changes'
          'unreviewed'        | 'reviewed'
          'unreviewed'        | 'approved'
          'unreviewed'        | 'unapproved'
          'unreviewed'        | 'review_started'
          'requested_changes' | 'unreviewed'
        end

        with_them do
          it do
            reviewer.update!(state: initial_state)

            result = service.execute(merge_request, new_state)

            expect(result[:status]).to eq :success
            expect(reviewer.reload.state).to eq new_state
          end
        end
      end

      it 'calls SystemNoteService.requested_changes' do
        expect(SystemNoteService).to receive(:requested_changes)
          .with(merge_request, current_user)

        expect(result[:status]).to eq :success
      end

      it 'does not call MergeRequests::RemoveApprovalService' do
        expect(MergeRequests::RemoveApprovalService).not_to receive(:new)

        expect(result[:status]).to eq :success
      end

      it_behaves_like 'triggers GraphQL subscription mergeRequestReviewersUpdated' do
        let(:action) { result }
      end

      it 'triggers GraphQL subscription userMergeRequestUpdated' do
        expect(GraphqlTriggers).to receive(:user_merge_request_updated).with(current_user, merge_request)

        result
      end

      context 'when merge_request_dashboard feature flag is enabled' do
        before do
          stub_feature_flags(merge_request_dashboard: true)
        end

        it 'invalidates cache counts for all assignees' do
          expect(merge_request.assignees).to all(receive(:invalidate_merge_request_cache_counts))

          expect(result[:status]).to eq :success
        end

        it 'invalidates cache counts for current user' do
          expect(current_user).to receive(:invalidate_merge_request_cache_counts)

          expect(result[:status]).to eq :success
        end
      end

      context 'when reviewer has approved' do
        before do
          create(:approval, user: current_user, merge_request: merge_request)
        end

        describe 'updating state of reviewer' do
          where(:initial_state, :new_state, :status) do
            'approved'       | 'reviewed'          | :error
            'approved'       | 'review_started'    | :error
            'approved'       | 'requested_changes' | :success
            'approved'       | 'unapproved'        | :success
          end

          with_them do
            it do
              reviewer.update!(state: initial_state)

              result = service.execute(merge_request, new_state)

              expect(result[:status]).to eq status
            end
          end
        end

        it 'removes approval when state is requested_changes' do
          expect_next_instance_of(
            MergeRequests::RemoveApprovalService,
            project: project, current_user: current_user
          ) do |service|
            expect(service).to receive(:execute)
              .with(merge_request, skip_system_note: true, skip_notification: true, skip_updating_state: true)
              .and_return({ success: true })
          end

          expect(result[:status]).to eq :success
        end

        it 'renders error when remove approval service fails' do
          expect_next_instance_of(
            MergeRequests::RemoveApprovalService,
            project: project, current_user: current_user
          ) do |service|
            expect(service).to receive(:execute)
              .with(merge_request, skip_system_note: true, skip_notification: true, skip_updating_state: true)
              .and_return(nil)
          end

          expect(result[:status]).to eq :error
          expect(result[:message]).to eq "Failed to remove approval"
        end
      end
    end
  end
end
