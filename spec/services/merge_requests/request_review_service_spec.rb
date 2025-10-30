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

      it 'invalidates cache counts' do
        expect(user).to receive(:invalidate_merge_request_cache_counts)
        expect(current_user).to receive(:invalidate_merge_request_cache_counts)

        service.execute(merge_request, user)
      end

      describe 'webhooks' do
        it 'executes webhook' do
          expect(service).to receive(:execute_hooks).with(
            merge_request,
            'update',
            hash_including(old_associations: anything)
          ).and_call_original

          service.execute(merge_request, user)
        end

        it 'includes old and current reviewer state with re_requested flag in webhook payload' do
          old_associations_data = nil
          current_merge_request = nil

          allow(service).to receive(:execute_hooks) do |mr, _action, options|
            old_associations_data = options[:old_associations]
            current_merge_request = mr
          end

          service.execute(merge_request, user)

          # Verify old associations structure
          expect(old_associations_data).to include(:reviewers_hook_attrs)
          expect(old_associations_data).to include(:re_requested_reviewer_id)
          expect(old_associations_data[:re_requested_reviewer_id]).to eq(reviewer.user_id)

          # Verify old reviewer state
          old_reviewer_data = old_associations_data[:reviewers_hook_attrs].find { |r| r[:id] == reviewer.user_id }
          expect(old_reviewer_data[:state]).to eq('reviewed')
          expect(old_reviewer_data[:re_requested]).to be(false)

          # Verify current reviewer state includes re_requested flag
          current_reviewers = current_merge_request.reviewers_hook_attrs(re_requested_reviewer_id: reviewer.user_id)
          current_reviewer_data = current_reviewers.find { |r| r[:id] == reviewer.user_id }
          expect(current_reviewer_data[:re_requested]).to be(true)
        end

        it 'ensures consistency between reviewers and changes.reviewers attributes' do
          # Test the actual webhook payload structure for consistency
          webhook_payload = nil

          allow(service).to receive(:execute_hooks) do |mr, action, options|
            webhook_payload = Gitlab::DataBuilder::Issuable.new(mr).build(
              user: user,
              changes: mr.hook_reviewer_changes(options[:old_associations]),
              action: action
            )
          end

          service.execute(merge_request, user)

          expect(webhook_payload).to be_present

          # Find reviewer B in both places
          reviewer_in_reviewers = webhook_payload[:reviewers].find { |r| r[:id] == reviewer.user_id }
          reviewer_in_changes = webhook_payload[:changes][:reviewers][:current].find { |r| r[:id] == reviewer.user_id }

          # Both should show re_requested: true for consistency
          expect(reviewer_in_reviewers[:re_requested]).to be(true)
          expect(reviewer_in_changes[:re_requested]).to be(true)
        end
      end
    end
  end
end
