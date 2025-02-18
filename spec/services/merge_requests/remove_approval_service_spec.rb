# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::RemoveApprovalService, feature_category: :code_review_workflow do
  describe '#execute' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:merge_request) { create(:merge_request, source_project: project, reviewers: [user]) }
    let!(:existing_approval) { create(:approval, merge_request: merge_request) }

    subject(:service) { described_class.new(project: project, current_user: user) }

    def execute!(skip_updating_state: false, skip_system_note: false, skip_notification: false)
      service.execute(merge_request, skip_updating_state: skip_updating_state, skip_system_note: skip_system_note,
        skip_notification: skip_notification)
    end

    before do
      project.add_developer(user)
    end

    shared_examples 'no-op call' do
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

      it_behaves_like 'does not trigger GraphQL subscription mergeRequestMergeStatusUpdated' do
        let(:action) { execute! }
      end

      it_behaves_like 'does not trigger GraphQL subscription mergeRequestReviewersUpdated' do
        let(:action) { execute! }
      end

      it_behaves_like 'does not trigger GraphQL subscription mergeRequestApprovalStateUpdated' do
        let(:action) { execute! }
      end
    end

    context 'with a user who has approved' do
      let!(:approval) { create(:approval, user: user, merge_request: merge_request) }
      let(:notification_service) { NotificationService.new }

      before do
        allow(service).to receive(:notification_service).and_return(notification_service)
      end

      context 'when the merge request is merged' do
        let(:merge_request) { create(:merge_request, :merged, source_project: project) }

        it_behaves_like 'no-op call'
      end

      it 'removes the approval' do
        expect { execute! }.to change { merge_request.approvals.size }.from(2).to(1)
      end

      it 'changes reviewers state to unapproved' do
        expect { execute! }.to change {
          merge_request.merge_request_reviewers.reload.all?(&:unapproved?)
        }.from(false).to(true)
      end

      it 'does not change reviewers state when skip_updating_state is true' do
        expect { execute!(skip_updating_state: true) }.not_to change {
          merge_request.merge_request_reviewers.reload.all?(&:unapproved?)
        }
      end

      it 'creates an unapproval note, triggers a web hook, and sends a notification' do
        expect(service).to receive(:execute_hooks).with(merge_request, 'unapproved')
        expect(SystemNoteService).to receive(:unapprove_mr)
        expect(notification_service).to receive_message_chain(:async, :unapprove_mr).with(merge_request, user)

        execute!
      end

      it 'does not trigger a web hook when skip_notification is true' do
        expect(service).not_to receive(:execute_hooks)

        execute!(skip_notification: true)
      end

      it 'does not send notification when skip_notification is true' do
        expect(notification_service).not_to receive(:async)

        execute!(skip_notification: true)
      end

      it 'does not create system note when skip_system_note is true' do
        expect(SystemNoteService).not_to receive(:unapprove_mr)

        execute!(skip_system_note: true)
      end

      it 'tracks merge request unapprove action' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to receive(:track_unapprove_mr_action).with(user: user)

        execute!
      end

      it 'does not track merge request unapprove action when skip_system_note is true' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter).not_to receive(:track_unapprove_mr_action)

        execute!(skip_system_note: true)
      end

      it_behaves_like 'triggers GraphQL subscription mergeRequestMergeStatusUpdated' do
        let(:action) { execute! }
      end

      it_behaves_like 'triggers GraphQL subscription mergeRequestReviewersUpdated' do
        let(:action) { execute! }
      end

      it_behaves_like 'triggers GraphQL subscription mergeRequestApprovalStateUpdated' do
        let(:action) { execute! }
      end

      it 'triggers GraphQL subscription userMergeRequestUpdated' do
        expect(GraphqlTriggers).to receive(:user_merge_request_updated).with(user, merge_request)

        execute!
      end
    end

    context 'with a user who has not approved' do
      it_behaves_like 'no-op call'
    end
  end
end
