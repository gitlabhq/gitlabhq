# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ProcessDraftNotePublishedWorker, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let(:data) { { current_user_id: user.id, merge_request_id: merge_request.id } }
  let(:approved_event) { MergeRequests::DraftNotePublishedEvent.new(data: data) }

  it_behaves_like 'subscribes to event' do
    let(:event) { approved_event }
  end

  it 'calls TodoService#new_review' do
    expect_next_instance_of(TodoService) do |todo_service|
      expect(todo_service)
        .to receive(:new_review)
        .with(merge_request, user)
    end

    consume_event(subscriber: described_class, event: approved_event)
  end

  context 'with review for merge request' do
    let(:review) { create(:review, project: project, merge_request: merge_request) }
    let(:data) { { current_user_id: user.id, merge_request_id: merge_request.id, review_id: review.id } }

    it 'calls NotificationService#new_review' do
      expect_next_instance_of(NotificationService) do |notification_service|
        expect(notification_service)
          .to receive(:new_review)
                .with(review)
      end

      consume_event(subscriber: described_class, event: approved_event)
    end
  end

  context 'without review for merge request' do
    it 'does not call NotificationService#new_review' do
      expect(NotificationService).not_to receive(:new)

      consume_event(subscriber: described_class, event: approved_event)
    end
  end

  context 'when discussions on merge request are resolved' do
    before do
      allow(MergeRequest).to receive(:find_by_id).with(merge_request.id).and_return(merge_request)
      allow(merge_request).to receive(:discussions_resolved?).and_return(true)
    end

    it 'calls NotificationService#resolve_all_discussions' do
      expect_next_instance_of(NotificationService) do |notification_service|
        expect(notification_service)
          .to receive(:resolve_all_discussions)
                .with(merge_request, user)
      end

      consume_event(subscriber: described_class, event: approved_event)
    end
  end

  shared_examples 'when object does not exist' do
    it 'logs and does not call TodoService#new_review' do
      expect(Sidekiq.logger).to receive(:info).with(hash_including(log_payload))
      expect(TodoService).not_to receive(:new)

      expect { consume_event(subscriber: described_class, event: approved_event) }
        .not_to raise_exception
    end
  end

  context 'when the user does not exist' do
    before do
      user.destroy!
    end

    it_behaves_like 'when object does not exist' do
      let(:log_payload) { { 'message' => 'Current user not found.', 'current_user_id' => user.id } }
    end
  end

  context 'when the merge request does not exist' do
    before do
      merge_request.destroy!
    end

    it_behaves_like 'when object does not exist' do
      let(:log_payload) { { 'message' => 'Merge request not found.', 'merge_request_id' => merge_request.id } }
    end
  end
end
