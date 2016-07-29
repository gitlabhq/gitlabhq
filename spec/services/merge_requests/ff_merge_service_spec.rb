require 'spec_helper'

describe MergeRequests::FfMergeService do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:merge_request) do
    create(:merge_request,
           source_branch: 'flatten-dir',
           target_branch: 'improve/awesome',
           assignee: user2)
  end
  let(:project) { merge_request.project }

  before do
    project.team << [user, :master]
    project.team << [user2, :developer]
  end

  describe :execute do
    context 'valid params' do
      let(:service) { MergeRequests::FfMergeService.new(project, user, {}) }

      before do
        allow(service).to receive(:execute_hooks)

        perform_enqueued_jobs do
          service.execute(merge_request)
        end
      end

      it "should not create merge commit" do
        source_branch_sha = merge_request.source_project.repository.commit(merge_request.source_branch).sha
        target_branch_sha = merge_request.target_project.repository.commit(merge_request.target_branch).sha
        expect(source_branch_sha).to eq(target_branch_sha)
      end

      it { expect(merge_request).to be_valid }
      it { expect(merge_request).to be_merged }

      it 'should send email to user2 about merge of new merge_request' do
        email = ActionMailer::Base.deliveries.last
        expect(email.to.first).to eq(user2.email)
        expect(email.subject).to include(merge_request.title)
      end

      it 'should create system note about merge_request merge' do
        note = merge_request.notes.last
        expect(note.note).to include 'Status changed to merged'
      end
    end
  end
end
