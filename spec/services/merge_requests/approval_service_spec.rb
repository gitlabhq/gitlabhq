# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ApprovalService, feature_category: :code_review_workflow do
  describe '#execute' do
    let(:user)          { create(:user) }
    let(:merge_request) { create(:merge_request, reviewers: [user]) }
    let(:project)       { merge_request.project }
    let!(:todo)         { create(:todo, user: user, project: project, target: merge_request) }

    subject(:service) { described_class.new(project: project, current_user: user) }

    before do
      project.add_developer(user)
      stub_feature_flags ff_require_saml_auth_to_approve: false
    end

    shared_examples 'no-op call' do
      it 'does not reset approvals' do
        expect(merge_request.approvals).not_to receive(:reset)

        service.execute(merge_request)
      end

      it 'does not track merge request approve action' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .not_to receive(:track_approve_mr_action).with(user: user)

        service.execute(merge_request)
      end

      it_behaves_like 'does not trigger GraphQL subscription mergeRequestMergeStatusUpdated' do
        let(:action) { service.execute(merge_request) }
      end

      it 'does not publish MergeRequests::ApprovedEvent' do
        expect { service.execute(merge_request) }.not_to publish_event(MergeRequests::ApprovedEvent)
      end

      it_behaves_like 'does not trigger GraphQL subscription mergeRequestReviewersUpdated' do
        let(:action) { service.execute(merge_request) }
      end
    end

    context 'with invalid approval' do
      before do
        allow(merge_request.approvals).to receive(:new).and_return(double(save: false))
      end

      it_behaves_like 'no-op call'
    end

    context 'with an already approved MR' do
      before do
        merge_request.approvals.create!(user: user)
      end

      it_behaves_like 'no-op call'
    end

    context 'with a merged MR' do
      let(:merge_request) { create(:merge_request, :merged) }

      it_behaves_like 'no-op call'
    end

    context 'user cannot update the merge request' do
      before do
        project.add_guest(user)
      end

      it_behaves_like 'no-op call'
    end

    context 'with valid approval' do
      it 'resets approvals' do
        expect(merge_request.approvals).to receive(:reset)

        service.execute(merge_request)
      end

      it 'tracks merge request approve action' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to receive(:track_approve_mr_action).with(user: user, merge_request: merge_request)

        service.execute(merge_request)
      end

      context 'when generating a patch_id_sha' do
        it 'records a value' do
          service.execute(merge_request)

          expect(merge_request.approvals.last.patch_id_sha).to eq(merge_request.current_patch_id_sha)
        end

        context 'when MergeRequest#current_patch_id_sha is nil' do
          it 'records patch_id_sha as nil' do
            expect(merge_request).to receive(:current_patch_id_sha).and_return(nil)

            service.execute(merge_request)

            expect(merge_request.approvals.last.patch_id_sha).to be_nil
          end
        end
      end

      it 'publishes MergeRequests::ApprovedEvent' do
        expect { service.execute(merge_request) }
          .to publish_event(MergeRequests::ApprovedEvent)
          .with(current_user_id: user.id,
            merge_request_id: merge_request.id,
            approved_at: anything)
      end

      it 'changes reviewers state to unapproved' do
        expect { service.execute(merge_request) }.to change {
          merge_request.merge_request_reviewers.reload.all?(&:approved?)
        }.from(false).to(true)
      end

      it_behaves_like 'triggers GraphQL subscription mergeRequestMergeStatusUpdated' do
        let(:action) { service.execute(merge_request) }
      end

      it_behaves_like 'triggers GraphQL subscription mergeRequestReviewersUpdated' do
        let(:action) { service.execute(merge_request) }
      end

      it_behaves_like 'triggers GraphQL subscription mergeRequestApprovalStateUpdated' do
        let(:action) { service.execute(merge_request) }
      end

      it 'triggers GraphQL subscription userMergeRequestUpdated' do
        expect(GraphqlTriggers).to receive(:user_merge_request_updated).with(user, merge_request)

        service.execute(merge_request)
      end
    end
  end
end
