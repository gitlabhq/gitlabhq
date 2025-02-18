# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CreateApprovalEventWorker, feature_category: :code_review_workflow do
  let!(:user) { create(:user) }
  let!(:project) { create(:project) }
  let!(:merge_request) { create(:merge_request, source_project: project) }
  let(:data) { { current_user_id: user.id, merge_request_id: merge_request.id, approved_at: Time.current.iso8601 } }
  let(:approved_event) { MergeRequests::ApprovedEvent.new(data: data) }

  it_behaves_like 'subscribes to event' do
    let(:event) { approved_event }
  end

  it 'calls MergeRequests::CreateApprovalEventService' do
    expect_next_instance_of(
      MergeRequests::CreateApprovalEventService,
      project: project, current_user: user
    ) do |service|
      expect(service).to receive(:execute).with(merge_request)
    end

    consume_event(subscriber: described_class, event: approved_event)
  end

  shared_examples 'when object does not exist' do
    it 'does not call MergeRequests::CreateApprovalEventService' do
      expect(MergeRequests::CreateApprovalEventService).not_to receive(:new)

      expect { consume_event(subscriber: described_class, event: approved_event) }
        .not_to raise_exception
    end
  end

  context 'when the user does not exist' do
    before do
      user.destroy!
    end

    it_behaves_like 'when object does not exist'
  end

  context 'when the merge request does not exist' do
    before do
      merge_request.destroy!
    end

    it_behaves_like 'when object does not exist'
  end
end
