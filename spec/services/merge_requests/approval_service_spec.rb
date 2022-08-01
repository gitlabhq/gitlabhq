# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ApprovalService do
  describe '#execute' do
    let(:user)          { create(:user) }
    let(:merge_request) { create(:merge_request, reviewers: [user]) }
    let(:project)       { merge_request.project }
    let!(:todo)         { create(:todo, user: user, project: project, target: merge_request) }

    subject(:service) { described_class.new(project: project, current_user: user) }

    before do
      project.add_developer(user)
    end

    context 'with invalid approval' do
      before do
        allow(merge_request.approvals).to receive(:new).and_return(double(save: false))
      end

      it 'does not reset approvals' do
        expect(merge_request.approvals).not_to receive(:reset)

        service.execute(merge_request)
      end

      it 'does not track merge request approve action' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .not_to receive(:track_approve_mr_action).with(user: user)

        service.execute(merge_request)
      end

      it 'does not publish MergeRequests::ApprovedEvent' do
        expect { service.execute(merge_request) }.not_to publish_event(MergeRequests::ApprovedEvent)
      end

      it 'does not create an approval note' do
        expect(SystemNoteService).not_to receive(:approve_mr)

        service.execute(merge_request)
      end

      it 'does not mark pending todos as done' do
        service.execute(merge_request)

        expect(todo.reload).to be_pending
      end

      context 'async_after_approval feature flag is disabled' do
        before do
          stub_feature_flags(async_after_approval: false)
        end

        it 'does not create approve MR event' do
          expect(EventCreateService).not_to receive(:new)

          service.execute(merge_request)
        end
      end
    end

    context 'with valid approval' do
      let(:notification_service) { NotificationService.new }

      before do
        allow(service).to receive(:notification_service).and_return(notification_service)
      end

      it 'resets approvals' do
        expect(merge_request.approvals).to receive(:reset)

        service.execute(merge_request)
      end

      it 'tracks merge request approve action' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to receive(:track_approve_mr_action).with(user: user, merge_request: merge_request)

        service.execute(merge_request)
      end

      it 'publishes MergeRequests::ApprovedEvent' do
        expect { service.execute(merge_request) }
          .to publish_event(MergeRequests::ApprovedEvent)
          .with(current_user_id: user.id, merge_request_id: merge_request.id)
      end

      it 'creates an approval note and marks pending todos as done' do
        expect(SystemNoteService).to receive(:approve_mr).with(merge_request, user)

        service.execute(merge_request)

        expect(todo.reload).to be_done
      end

      it 'sends a notification when approving' do
        expect(notification_service).to receive_message_chain(:async, :approve_mr)
          .with(merge_request, user)

        service.execute(merge_request)
      end

      it 'removes attention requested state' do
        expect(MergeRequests::RemoveAttentionRequestedService).to receive(:new)
          .with(project: project, current_user: user, merge_request: merge_request, user: user)
          .and_call_original

        service.execute(merge_request)
      end

      context 'with remaining approvals' do
        it 'fires an approval webhook' do
          expect(service).to receive(:execute_hooks).with(merge_request, 'approved')

          service.execute(merge_request)
        end
      end

      context 'async_after_approval feature flag is disabled' do
        before do
          stub_feature_flags(async_after_approval: false)
          allow(service).to receive(:notification_service).and_return(notification_service)
        end

        it 'creates approve MR event' do
          expect_next_instance_of(EventCreateService) do |instance|
            expect(instance).to receive(:approve_mr)
              .with(merge_request, user)
          end

          service.execute(merge_request)
        end
      end
    end

    context 'user cannot update the merge request' do
      before do
        project.add_guest(user)
      end

      it 'does not update approvals' do
        expect { service.execute(merge_request) }.not_to change { merge_request.approvals.size }
      end
    end
  end
end
