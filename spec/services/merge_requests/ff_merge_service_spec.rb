# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::FfMergeService do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:merge_request) do
    create(:merge_request,
           source_branch: 'flatten-dir',
           target_branch: 'improve/awesome',
           assignees: [user2],
           author: create(:user))
  end

  let(:project) { merge_request.project }
  let(:valid_merge_params) { { sha: merge_request.diff_head_sha } }

  before do
    project.add_maintainer(user)
    project.add_developer(user2)
  end

  describe '#execute' do
    context 'valid params' do
      let(:service) { described_class.new(project: project, current_user: user, params: valid_merge_params) }

      def execute_ff_merge
        perform_enqueued_jobs do
          service.execute(merge_request)
        end
      end

      before do
        allow(service).to receive(:execute_hooks)
      end

      it "does not create merge commit" do
        execute_ff_merge

        source_branch_sha = merge_request.source_project.repository.commit(merge_request.source_branch).sha
        target_branch_sha = merge_request.target_project.repository.commit(merge_request.target_branch).sha

        expect(source_branch_sha).to eq(target_branch_sha)
      end

      it 'keeps the merge request valid' do
        expect { execute_ff_merge }
          .not_to change { merge_request.valid? }
      end

      it 'updates the merge request to merged' do
        expect { execute_ff_merge }
          .to change { merge_request.merged? }
          .from(false)
          .to(true)
      end

      it 'sends email to user2 about merge of new merge_request' do
        execute_ff_merge

        email = ActionMailer::Base.deliveries.last
        expect(email.to.first).to eq(user2.email)
        expect(email.subject).to include(merge_request.title)
      end

      it 'creates resource event about merge_request merge' do
        execute_ff_merge

        event = merge_request.resource_state_events.last
        expect(event.state).to eq('merged')
      end

      it 'does not update squash_commit_sha if it is not a squash' do
        expect(merge_request).to receive(:update_and_mark_in_progress_merge_commit_sha).twice.and_call_original

        expect { execute_ff_merge }.not_to change { merge_request.squash_commit_sha }
        expect(merge_request.in_progress_merge_commit_sha).to be_nil
      end

      it 'updates squash_commit_sha if it is a squash' do
        expect(merge_request).to receive(:update_and_mark_in_progress_merge_commit_sha).twice.and_call_original

        merge_request.update!(squash: true)

        expect { execute_ff_merge }
          .to change { merge_request.squash_commit_sha }
          .from(nil)

        expect(merge_request.in_progress_merge_commit_sha).to be_nil
      end
    end

    context 'error handling' do
      let(:service) { described_class.new(project: project, current_user: user, params: valid_merge_params.merge(commit_message: 'Awesome message')) }

      before do
        allow(Gitlab::AppLogger).to receive(:error)
      end

      it 'logs and saves error if there is an exception' do
        error_message = 'error message'

        allow(service).to receive(:repository).and_raise("error message")
        allow(service).to receive(:execute_hooks)

        service.execute(merge_request)

        expect(merge_request.merge_error).to include(error_message)
        expect(Gitlab::AppLogger).to have_received(:error).with(a_string_matching(error_message))
      end

      it 'logs and saves error if there is an PreReceiveError exception' do
        error_message = 'error message'
        raw_message = 'The truth is out there'

        pre_receive_error = Gitlab::Git::PreReceiveError.new(raw_message, fallback_message: error_message)
        allow(service).to receive(:repository).and_raise(pre_receive_error)
        allow(service).to receive(:execute_hooks)
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          pre_receive_error,
          pre_receive_message: raw_message,
          merge_request_id: merge_request.id
        )

        service.execute(merge_request)

        expect(merge_request.merge_error).to include(error_message)
        expect(Gitlab::AppLogger).to have_received(:error).with(a_string_matching(error_message))
      end

      it 'does not update squash_commit_sha if squash merge is not successful' do
        merge_request.update!(squash: true)

        expect(project.repository.raw).to receive(:ff_merge) do
          raise 'Merge error'
        end

        expect { service.execute(merge_request) }.not_to change { merge_request.squash_commit_sha }
      end
    end
  end
end
