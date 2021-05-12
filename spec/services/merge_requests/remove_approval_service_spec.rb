# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::RemoveApprovalService do
  describe '#execute' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:merge_request) { create(:merge_request, source_project: project) }
    let!(:existing_approval) { create(:approval, merge_request: merge_request) }

    subject(:service) { described_class.new(project: project, current_user: user) }

    def execute!
      service.execute(merge_request)
    end

    before do
      project.add_developer(user)
    end

    context 'with a user who has approved' do
      let!(:approval) { create(:approval, user: user, merge_request: merge_request) }

      it 'removes the approval' do
        expect { execute! }.to change { merge_request.approvals.size }.from(2).to(1)
      end

      it 'creates an unapproval note and triggers web hook' do
        expect(service).to receive(:execute_hooks).with(merge_request, 'unapproved')
        expect(SystemNoteService).to receive(:unapprove_mr)

        execute!
      end

      it 'tracks merge request unapprove action' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to receive(:track_unapprove_mr_action).with(user: user)

        execute!
      end
    end

    context 'with a user who has not approved' do
      it 'does not create an unapproval note and triggers web hook' do
        expect(service).not_to receive(:execute_hooks)
        expect(SystemNoteService).not_to receive(:unapprove_mr)

        execute!
      end

      it 'does not track merge request unapprove action' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .not_to receive(:track_unapprove_mr_action).with(user: user)

        execute!
      end
    end
  end
end
