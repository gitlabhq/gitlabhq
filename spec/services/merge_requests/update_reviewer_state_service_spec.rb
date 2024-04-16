# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::UpdateReviewerStateService, feature_category: :code_review_workflow do
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

      it 'updates reviewers state' do
        expect(result[:status]).to eq :success
        expect(reviewer.state).to eq 'requested_changes'
      end

      it 'does not call MergeRequests::RemoveApprovalService' do
        expect(MergeRequests::RemoveApprovalService).not_to receive(:new)

        expect(result[:status]).to eq :success
      end

      it_behaves_like 'triggers GraphQL subscription mergeRequestReviewersUpdated' do
        let(:action) { result }
      end

      context 'when reviewer has approved' do
        before do
          create(:approval, user: current_user, merge_request: merge_request)
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
