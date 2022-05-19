# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::RemoveAttentionRequestedService do
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

  before do
    allow(SystemNoteService).to receive(:remove_attention_request)

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
        reviewer.update!(state: :attention_requested)
      end

      it 'returns success' do
        expect(result[:status]).to eq :success
      end

      it 'updates reviewer state' do
        service.execute
        reviewer.reload

        expect(reviewer.state).to eq 'reviewed'
      end

      it 'creates a remove attention request system note' do
        expect(SystemNoteService)
          .to receive(:remove_attention_request)
          .with(merge_request, merge_request.project, current_user, user)

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
        assignee.update!(state: :attention_requested)
      end

      it 'returns success' do
        expect(result[:status]).to eq :success
      end

      it 'updates assignee state' do
        service.execute
        assignee.reload

        expect(assignee.state).to eq 'reviewed'
      end

      it_behaves_like 'invalidates attention request cache' do
        let(:users) { [assignee_user] }
      end

      it 'creates a remove attention request system note' do
        expect(SystemNoteService)
          .to receive(:remove_attention_request)
          .with(merge_request, merge_request.project, current_user, assignee_user)

        service.execute
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
        reviewer.update!(state: :attention_requested)
        assignee.update!(state: :attention_requested)
      end

      it 'returns success' do
        expect(result[:status]).to eq :success
      end

      it 'updates reviewers and assignees state' do
        service.execute
        reviewer.reload
        assignee.reload

        expect(reviewer.state).to eq 'reviewed'
        expect(assignee.state).to eq 'reviewed'
      end
    end

    context 'when state is already not attention_requested' do
      before do
        reviewer.update!(state: :reviewed)
      end

      it 'does not change state' do
        service.execute
        reviewer.reload

        expect(reviewer.state).to eq 'reviewed'
      end

      it 'does not create a remove attention request system note' do
        expect(SystemNoteService).not_to receive(:remove_attention_request)

        service.execute
      end
    end
  end
end
