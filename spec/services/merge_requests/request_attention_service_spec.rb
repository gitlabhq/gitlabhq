# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::RequestAttentionService do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { create(:user) }
  let_it_be(:assignee_user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, reviewers: [user], assignees: [assignee_user]) }

  let(:reviewer) { merge_request.find_reviewer(user) }
  let(:assignee) { merge_request.find_assignee(assignee_user) }
  let(:project) { merge_request.project }

  let(:service) do
    described_class.new(
      project: project,
      current_user: current_user,
      merge_request: merge_request,
      user: user
    )
  end

  let(:result) { service.execute }
  let(:todo_svc) { instance_double('TodoService') }
  let(:notification_svc) { instance_double('NotificationService') }

  before do
    allow(service).to receive(:todo_service).and_return(todo_svc)
    allow(service).to receive(:notification_service).and_return(notification_svc)
    allow(todo_svc).to receive(:create_attention_requested_todo)
    allow(notification_svc).to receive_message_chain(:async, :attention_requested_of_merge_request)
    allow(SystemNoteService).to receive(:request_attention)

    project.add_developer(current_user)
    project.add_developer(user)
  end

  describe '#execute' do
    context 'when current user cannot update merge request' do
      let(:service) do
        described_class.new(
          project: project,
          current_user: create(:user),
          merge_request: merge_request,
          user: user
        )
      end

      it 'returns an error' do
        expect(result[:status]).to eq :error
      end
    end

    context 'when user is not a reviewer nor assignee' do
      let(:service) do
        described_class.new(
          project: project,
          current_user: current_user,
          merge_request: merge_request,
          user: create(:user)
        )
      end

      it 'returns an error' do
        expect(result[:status]).to eq :error
      end
    end

    context 'when user is a reviewer' do
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
        expect(todo_svc).to receive(:create_attention_requested_todo).with(merge_request, current_user, user)

        service.execute
      end

      it 'sends email to reviewer' do
        expect(notification_svc)
          .to receive_message_chain(:async, :attention_requested_of_merge_request)
          .with(merge_request, current_user, user)

        service.execute
      end

      it 'removes attention requested state' do
        expect(MergeRequests::RemoveAttentionRequestedService).to receive(:new)
          .with(project: project, current_user: current_user, merge_request: merge_request, user: current_user)
          .and_call_original

        service.execute
      end

      it_behaves_like 'invalidates attention request cache' do
        let(:users) { [user] }
      end
    end

    context 'when user is an assignee' do
      let(:service) do
        described_class.new(
          project: project,
          current_user: current_user,
          merge_request: merge_request,
          user: assignee_user
        )
      end

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
        expect(todo_svc).to receive(:create_attention_requested_todo).with(merge_request, current_user, assignee_user)

        service.execute
      end

      it 'creates a request attention system note' do
        expect(SystemNoteService)
          .to receive(:request_attention)
          .with(merge_request, merge_request.project, current_user, assignee_user)

        service.execute
      end

      it 'removes attention requested state' do
        expect(MergeRequests::RemoveAttentionRequestedService).to receive(:new)
          .with(project: project, current_user: current_user, merge_request: merge_request, user: current_user)
          .and_call_original

        service.execute
      end

      it_behaves_like 'invalidates attention request cache' do
        let(:users) { [assignee_user] }
      end
    end

    context 'when user is an assignee and reviewer at the same time' do
      let_it_be(:merge_request) { create(:merge_request, reviewers: [user], assignees: [user]) }

      let(:assignee) { merge_request.find_assignee(user) }

      let(:service) do
        described_class.new(
          project: project,
          current_user: current_user,
          merge_request: merge_request,
          user: user
        )
      end

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

    context 'when state is attention_requested' do
      before do
        reviewer.update!(state: :attention_requested)
      end

      it 'does not change state' do
        service.execute
        reviewer.reload

        expect(reviewer.state).to eq 'attention_requested'
      end

      it 'does not create a new todo for the reviewer' do
        expect(todo_svc).not_to receive(:create_attention_requested_todo).with(merge_request, current_user, user)

        service.execute
      end
    end
  end
end
