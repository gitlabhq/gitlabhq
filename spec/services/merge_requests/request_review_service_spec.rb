# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::RequestReviewService do
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
    describe 'invalid permissions' do
      let(:service) { described_class.new(project: project, current_user: create(:user)) }

      it 'returns an error' do
        expect(result[:status]).to eq :error
      end
    end

    describe 'reviewer does not exist' do
      let(:result) { service.execute(merge_request, create(:user)) }

      it 'returns an error' do
        expect(result[:status]).to eq :error
      end
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
    end
  end
end
