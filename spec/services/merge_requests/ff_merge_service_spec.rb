require 'spec_helper'

describe MergeRequests::FfMergeService do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:merge_request) do
    create(:merge_request,
           source_branch: 'flatten-dir',
           target_branch: 'improve/awesome',
           assignee: user2,
           author: create(:user))
  end
  let(:project) { merge_request.project }

  before do
    project.add_master(user)
    project.add_developer(user2)
  end

  describe '#execute' do
    context 'valid params' do
      let(:service) { described_class.new(project, user, {}) }

      before do
        allow(service).to receive(:execute_hooks)

        perform_enqueued_jobs do
          service.execute(merge_request)
        end
      end

      it "does not create merge commit" do
        source_branch_sha = merge_request.source_project.repository.commit(merge_request.source_branch).sha
        target_branch_sha = merge_request.target_project.repository.commit(merge_request.target_branch).sha
        expect(source_branch_sha).to eq(target_branch_sha)
      end

      it { expect(merge_request).to be_valid }
      it { expect(merge_request).to be_merged }

      it 'sends email to user2 about merge of new merge_request' do
        email = ActionMailer::Base.deliveries.last
        expect(email.to.first).to eq(user2.email)
        expect(email.subject).to include(merge_request.title)
      end

      it 'creates system note about merge_request merge' do
        note = merge_request.notes.last
        expect(note.note).to include 'merged'
      end
    end

    context "error handling" do
      let(:service) { described_class.new(project, user, commit_message: 'Awesome message') }

      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'logs and saves error if there is an exception' do
        error_message = 'error message'

        allow(service).to receive(:repository).and_raise("error message")
        allow(service).to receive(:execute_hooks)

        service.execute(merge_request)

        expect(merge_request.merge_error).to include(error_message)
        expect(Rails.logger).to have_received(:error).with(a_string_matching(error_message))
      end

      it 'logs and saves error if there is an PreReceiveError exception' do
        error_message = 'error message'

        allow(service).to receive(:repository).and_raise(Gitlab::Git::HooksService::PreReceiveError, error_message)
        allow(service).to receive(:execute_hooks)

        service.execute(merge_request)

        expect(merge_request.merge_error).to include(error_message)
        expect(Rails.logger).to have_received(:error).with(a_string_matching(error_message))
      end
    end
  end
end
