# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::RemoveAttentionRequestedService do
  let(:current_user) { create(:user) }
  let(:user) { create(:user) }
  let(:assignee_user) { create(:user) }
  let(:merge_request) { create(:merge_request, reviewers: [user], assignees: [assignee_user]) }
  let(:reviewer) { merge_request.find_reviewer(user) }
  let(:assignee) { merge_request.find_assignee(assignee_user) }
  let(:project) { merge_request.project }
  let(:service) { described_class.new(project: project, current_user: current_user, merge_request: merge_request, user: user) }
  let(:result) { service.execute }

  before do
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
      it 'returns success' do
        expect(result[:status]).to eq :success
      end

      it 'updates reviewers state' do
        service.execute
        reviewer.reload

        expect(reviewer.state).to eq 'reviewed'
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

        expect(assignee.state).to eq 'reviewed'
      end
    end

    context 'assignee is the same as reviewer' do
      let(:merge_request) { create(:merge_request, reviewers: [user], assignees: [user]) }
      let(:service) { described_class.new(project: project, current_user: current_user, merge_request: merge_request, user: user) }
      let(:assignee) { merge_request.find_assignee(user) }

      it 'updates reviewers and assignees state' do
        service.execute
        reviewer.reload
        assignee.reload

        expect(reviewer.state).to eq 'reviewed'
        expect(assignee.state).to eq 'reviewed'
      end
    end
  end
end
