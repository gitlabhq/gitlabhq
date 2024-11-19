# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::RequestReviewService, feature_category: :code_review_workflow do
  let(:current_user) { create(:user) }
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request, reviewers: [user]) }
  let(:reviewer) { merge_request.find_reviewer(user) }
  let(:project) { merge_request.project }
  let(:service) { described_class.new(project: project, current_user: current_user) }
  let(:result) { service.execute(merge_request, user) }
  let(:todo_service) { spy('todo service') }
  let(:notification_service) { spy('notification service') }

  before do
    allow(NotificationService).to receive(:new) { notification_service }
    allow(service).to receive(:todo_service).and_return(todo_service)
    allow(service).to receive(:notification_service).and_return(notification_service)

    reviewer.update!(state: MergeRequestReviewer.states[:reviewed])

    project.add_developer(current_user)
    project.add_developer(user)
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

    describe 'reviewer does not exist' do
      let(:result) { service.execute(merge_request, create(:user)) }

      it_behaves_like 'failed service execution'
    end

    describe 'reviewer exists' do
      it 'returns success' do
        expect(result[:status]).to eq :success
      end

      it 'updates reviewers state' do
        service.execute(merge_request, user)
        reviewer.reload

        expect(reviewer.state).to eq 'unreviewed'
      end

      it 'sends email to reviewer' do
        expect(notification_service).to receive_message_chain(:async, :review_requested_of_merge_request).with(merge_request, current_user, user)

        service.execute(merge_request, user)
      end

      it 'creates a new todo for the reviewer' do
        expect(todo_service).to receive(:create_request_review_todo).with(merge_request, current_user, user)

        service.execute(merge_request, user)
      end

      it 'creates a sytem note' do
        expect(SystemNoteService)
          .to receive(:request_review)
          .with(merge_request, project, current_user, user, false)

        service.execute(merge_request, user)
      end

      it_behaves_like 'triggers GraphQL subscription mergeRequestReviewersUpdated' do
        let(:action) { result }
      end

      it 'calls MergeRequests::RemoveApprovalService' do
        expect_next_instance_of(
          MergeRequests::RemoveApprovalService,
          project: project, current_user: user
        ) do |service|
          expect(service).to receive(:execute).with(merge_request, skip_system_note: true, skip_notification: true, skip_updating_state: true).and_return({ success: true })
        end

        service.execute(merge_request, user)
      end

      context 'when merge_request_dashboard feature flag is enabled' do
        before do
          stub_feature_flags(merge_request_dashboard: true)
        end

        it 'invalidates cache counts' do
          expect(user).to receive(:invalidate_merge_request_cache_counts)
          expect(current_user).to receive(:invalidate_merge_request_cache_counts)

          service.execute(merge_request, user)
        end
      end
    end
  end
end
