# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ToggleAttentionRequestedService do
  let(:current_user) { create(:user) }
  let(:user) { create(:user) }
  let(:assignee_user) { create(:user) }
  let(:merge_request) { create(:merge_request, reviewers: [user], assignees: [assignee_user]) }
  let(:reviewer) { merge_request.find_reviewer(user) }
  let(:assignee) { merge_request.find_assignee(assignee_user) }
  let(:project) { merge_request.project }
  let(:service) { described_class.new(project: project, current_user: current_user, merge_request: merge_request, user: user) }
  let(:result) { service.execute }
  let(:todo_service) { spy('todo service') }
  let(:notification_service) { spy('notification service') }

  before do
    allow(NotificationService).to receive(:new) { notification_service }
    allow(service).to receive(:todo_service).and_return(todo_service)
    allow(service).to receive(:notification_service).and_return(notification_service)
    allow(SystemNoteService).to receive(:request_attention)
    allow(SystemNoteService).to receive(:remove_attention_request)

    project.add_developer(current_user)
    project.add_developer(user)
  end

  describe '#execute' do
    context 'invalid permissions' do
      let(:service) { described_class.new(project: project, current_user: create(:user), merge_request: merge_request, user: user) }

      it 'returns an error' do
        expect(result[:status]).to eq :error
      end
    end

    context 'reviewer does not exist' do
      let(:service) { described_class.new(project: project, current_user: current_user, merge_request: merge_request, user: create(:user)) }

      it 'returns an error' do
        expect(result[:status]).to eq :error
      end
    end

    context 'reviewer exists' do
      before do
        reviewer.update!(state: :reviewed)
      end

      it 'returns success' do
        expect(result[:status]).to eq :success
      end

      it 'updates reviewers state' do
        service.execute
        reviewer.reload

        expect(reviewer.state).to eq 'attention_requested'
      end

      it 'adds who toggled attention' do
        service.execute
        reviewer.reload

        expect(reviewer.updated_state_by).to eq current_user
      end

      it 'creates a new todo for the reviewer' do
        expect(todo_service).to receive(:create_attention_requested_todo).with(merge_request, current_user, user)

        service.execute
      end

      it 'sends email to reviewer' do
        expect(notification_service).to receive_message_chain(:async, :attention_requested_of_merge_request).with(merge_request, current_user, user)

        service.execute
      end

      it 'removes attention requested state' do
        expect(MergeRequests::RemoveAttentionRequestedService).to receive(:new)
          .with(project: project, current_user: current_user, merge_request: merge_request)
          .and_call_original

        service.execute
      end

      it 'invalidates cache' do
        cache_mock = double

        expect(cache_mock).to receive(:delete).with(['users', user.id, 'attention_requested_open_merge_requests_count'])

        allow(Rails).to receive(:cache).and_return(cache_mock)

        service.execute
      end
    end

    context 'assignee exists' do
      let(:service) { described_class.new(project: project, current_user: current_user, merge_request: merge_request, user: assignee_user) }

      before do
        assignee.update!(state: :reviewed)
      end

      it 'returns success' do
        expect(result[:status]).to eq :success
      end

      it 'updates assignees state' do
        service.execute
        assignee.reload

        expect(assignee.state).to eq 'attention_requested'
      end

      it 'creates a new todo for the reviewer' do
        expect(todo_service).to receive(:create_attention_requested_todo).with(merge_request, current_user, assignee_user)

        service.execute
      end

      it 'creates a request attention system note' do
        expect(SystemNoteService).to receive(:request_attention).with(merge_request, merge_request.project, current_user, assignee_user)

        service.execute
      end

      it 'removes attention requested state' do
        expect(MergeRequests::RemoveAttentionRequestedService).to receive(:new)
          .with(project: project, current_user: current_user, merge_request: merge_request)
          .and_call_original

        service.execute
      end

      it_behaves_like 'invalidates attention request cache' do
        let(:users) { [assignee_user] }
      end
    end

    context 'assignee is the same as reviewer' do
      let(:merge_request) { create(:merge_request, reviewers: [user], assignees: [user]) }
      let(:service) { described_class.new(project: project, current_user: current_user, merge_request: merge_request, user: user) }
      let(:assignee) { merge_request.find_assignee(user) }

      before do
        reviewer.update!(state: :reviewed)
        assignee.update!(state: :reviewed)
      end

      it 'updates reviewers and assignees state' do
        service.execute
        reviewer.reload
        assignee.reload

        expect(reviewer.state).to eq 'attention_requested'
        expect(assignee.state).to eq 'attention_requested'
      end
    end

    context 'state is attention_requested' do
      before do
        reviewer.update!(state: :attention_requested)
      end

      it 'toggles state to reviewed' do
        service.execute
        reviewer.reload

        expect(reviewer.state).to eq "reviewed"
      end

      it 'does not create a new todo for the reviewer' do
        expect(todo_service).not_to receive(:create_attention_requested_todo).with(merge_request, current_user, assignee_user)

        service.execute
      end

      it 'creates a remove attention request system note' do
        expect(SystemNoteService).to receive(:remove_attention_request).with(merge_request, merge_request.project, current_user, user)

        service.execute
      end
    end
  end
end
