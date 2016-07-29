require 'spec_helper'

describe MergeRequests::MergeService, services: true do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:merge_request) { create(:merge_request, assignee: user2) }
  let(:project) { merge_request.project }

  before do
    project.team << [user, :master]
    project.team << [user2, :developer]
  end

  describe '#execute' do
    context 'valid params' do
      let(:service) { MergeRequests::MergeService.new(project, user, commit_message: 'Awesome message') }

      before do
        allow(service).to receive(:execute_hooks)

        perform_enqueued_jobs do
          service.execute(merge_request)
        end
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

    context 'remove source branch by author' do
      let(:service) do
        merge_request.merge_params['force_remove_source_branch'] = '1'
        merge_request.save!
        MergeRequests::MergeService.new(project, user, commit_message: 'Awesome message')
      end

      it 'removes the source branch' do
        expect(DeleteBranchService).to receive(:new).
          with(merge_request.source_project, merge_request.author).
          and_call_original
        service.execute(merge_request)
      end
    end

    context "error handling" do
      let(:service) { MergeRequests::MergeService.new(project, user, commit_message: 'Awesome message') }

      it 'saves error if there is an exception' do
        allow(service).to receive(:repository).and_raise("error")

        allow(service).to receive(:execute_hooks)

        service.execute(merge_request)

        expect(merge_request.merge_error).to eq("Something went wrong during merge")
      end

      it 'saves error if there is an PreReceiveError exception' do
        allow(service).to receive(:repository).and_raise(GitHooksService::PreReceiveError, "error")

        allow(service).to receive(:execute_hooks)

        service.execute(merge_request)

        expect(merge_request.merge_error).to eq("error")
      end
    end
  end

  describe '#hooks_validation_pass?' do
    let(:service) { MergeRequests::MergeService.new(project, user, commit_message: 'Awesome message') }

    it 'returns true when valid' do
      expect(service.hooks_validation_pass?(merge_request)).to be_truthy
    end

    context 'commit message validation' do
      before do
        allow(project).to receive(:push_rule) { build(:push_rule, commit_message_regex: 'unmatched pattern .*') }
      end

      it 'returns false and saves error when invalid' do
        expect(service.hooks_validation_pass?(merge_request)).to be_falsey
        expect(merge_request.merge_error).not_to be_empty
      end
    end

    context 'authors email validation' do
      before do
        allow(project).to receive(:push_rule) { build(:push_rule, author_email_regex: '.*@unmatchedemaildomain.com') }
      end

      it 'returns false and saves error when invalid' do
        expect(service.hooks_validation_pass?(merge_request)).to be_falsey
        expect(merge_request.merge_error).not_to be_empty
      end
    end

    context 'fast forward merge request' do
      it 'returns true when fast forward is enabled' do
        allow(project).to receive(:merge_requests_ff_only_enabled) { true }

        expect(service.hooks_validation_pass?(merge_request)).to be_truthy
      end
    end
  end
end
