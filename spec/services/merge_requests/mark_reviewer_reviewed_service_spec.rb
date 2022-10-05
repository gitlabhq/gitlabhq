# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MarkReviewerReviewedService do
  let(:current_user) { create(:user) }
  let(:merge_request) { create(:merge_request, reviewers: [current_user]) }
  let(:reviewer) { merge_request.merge_request_reviewers.find_by(user_id: current_user.id) }
  let(:project) { merge_request.project }
  let(:service) { described_class.new(project: project, current_user: current_user) }
  let(:result) { service.execute(merge_request) }

  before do
    project.add_developer(current_user)
  end

  describe '#execute' do
    shared_examples_for 'failed service execution' do
      it 'returns an error' do
        expect(result[:status]).to eq :error
      end

      it 'does not trigger graphql subscription mergeRequestReviewersUpdated' do
        expect(GraphqlTriggers).not_to receive(:merge_request_reviewers_updated)

        result
      end
    end

    describe 'invalid permissions' do
      let(:service) { described_class.new(project: project, current_user: create(:user)) }

      it_behaves_like 'failed service execution'
    end

    describe 'reviewer does not exist' do
      let(:service) { described_class.new(project: project, current_user: create(:user)) }

      it_behaves_like 'failed service execution'
    end

    describe 'reviewer exists' do
      it 'returns success' do
        expect(result[:status]).to eq :success
      end

      it 'updates reviewers state' do
        expect(result[:status]).to eq :success
        expect(reviewer.state).to eq 'reviewed'
      end

      it 'triggers graphql subscription mergeRequestReviewersUpdated' do
        expect(GraphqlTriggers).to receive(:merge_request_reviewers_updated).with(merge_request)

        result
      end
    end
  end
end
