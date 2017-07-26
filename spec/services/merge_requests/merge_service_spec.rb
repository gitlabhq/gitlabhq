require 'spec_helper'

describe MergeRequests::MergeService do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:merge_request) { create(:merge_request, :simple, author: user2, assignee: user2) }
  let(:project) { merge_request.project }

  before do
    project.team << [user, :master]
    project.team << [user2, :developer]
  end

  describe '#execute' do
    context 'valid params' do
      let(:service) { described_class.new(project, user, commit_message: 'Awesome message') }

      before do
        allow(service).to receive(:execute_hooks)

        perform_enqueued_jobs do
          service.execute(merge_request)
        end
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

    context 'project has exceeded size limit' do
      let(:service) { described_class.new(project, user, commit_message: 'Awesome message') }

      before do
        allow(project).to receive(:above_size_limit?).and_return(true)

        perform_enqueued_jobs do
          service.execute(merge_request)
        end
      end

      it 'returns the correct error message' do
        expect(merge_request.merge_error).to include('This merge request cannot be merged')
      end
    end

    context 'closes related issues' do
      let(:service) { described_class.new(project, user, commit_message: 'Awesome message') }

      before do
        allow(project).to receive(:default_branch).and_return(merge_request.target_branch)
      end

      it 'closes GitLab issue tracker issues' do
        issue  = create :issue, project: project
        commit = double('commit', safe_message: "Fixes #{issue.to_reference}")
        allow(merge_request).to receive(:commits).and_return([commit])

        service.execute(merge_request)

        expect(issue.reload.closed?).to be_truthy
      end

      context 'with JIRA integration' do
        include JiraServiceHelper

        let(:jira_tracker) { project.create_jira_service }
        let(:jira_issue)   { ExternalIssue.new('JIRA-123', project) }
        let(:commit)       { double('commit', safe_message: "Fixes #{jira_issue.to_reference}") }

        before do
          project.update_attributes!(has_external_issue_tracker: true)
          jira_service_settings
          stub_jira_urls(jira_issue.id)
          allow(merge_request).to receive(:commits).and_return([commit])
        end

        it 'closes issues on JIRA issue tracker' do
          jira_issue = ExternalIssue.new('JIRA-123', project)
          stub_jira_urls(jira_issue)
          commit = double('commit', safe_message: "Fixes #{jira_issue.to_reference}")
          allow(merge_request).to receive(:commits).and_return([commit])

          expect_any_instance_of(JiraService).to receive(:close_issue).with(merge_request, jira_issue).once

          service.execute(merge_request)
        end

        context "when jira_issue_transition_id is not present" do
          before do
            allow_any_instance_of(JIRA::Resource::Issue).to receive(:resolution).and_return(nil)
          end

          it "does not close issue" do
            allow(jira_tracker).to receive_messages(jira_issue_transition_id: nil)

            expect_any_instance_of(JiraService).not_to receive(:transition_issue)

            service.execute(merge_request)
          end
        end

        context "wrong issue markdown" do
          it 'does not close issues on JIRA issue tracker' do
            jira_issue = ExternalIssue.new('#JIRA-123', project)
            stub_jira_urls(jira_issue)
            commit = double('commit', safe_message: "Fixes #{jira_issue.to_reference}")
            allow(merge_request).to receive(:commits).and_return([commit])

            expect_any_instance_of(JiraService).not_to receive(:close_issue)

            service.execute(merge_request)
          end
        end
      end
    end

    context 'closes related todos' do
      let(:merge_request) { create(:merge_request, assignee: user, author: user) }
      let(:project) { merge_request.project }
      let(:service) { described_class.new(project, user, commit_message: 'Awesome message') }
      let!(:todo) do
        create(:todo, :assigned,
          project: project,
          author: user,
          user: user,
          target: merge_request)
      end

      before do
        allow(service).to receive(:execute_hooks)

        perform_enqueued_jobs do
          service.execute(merge_request)
          todo.reload
        end
      end

      it { expect(todo).to be_done }
    end

    context 'source branch removal' do
      context 'when the source branch is protected' do
        let(:service) do
          described_class.new(project, user, should_remove_source_branch: '1')
        end

        before do
          create(:protected_branch, project: project, name: merge_request.source_branch)
        end

        it 'does not delete the source branch' do
          expect(DeleteBranchService).not_to receive(:new)
          service.execute(merge_request)
        end
      end

      context 'when the source branch is the default branch' do
        let(:service) do
          described_class.new(project, user, should_remove_source_branch: '1')
        end

        before do
          allow(project).to receive(:root_ref?).with(merge_request.source_branch).and_return(true)
        end

        it 'does not delete the source branch' do
          expect(DeleteBranchService).not_to receive(:new)
          service.execute(merge_request)
        end
      end

      context 'when the source branch can be removed' do
        context 'when MR author set the source branch to be removed' do
          let(:service) do
            merge_request.merge_params['force_remove_source_branch'] = '1'
            merge_request.save!
            described_class.new(project, user, commit_message: 'Awesome message')
          end

          it 'removes the source branch using the author user' do
            expect(DeleteBranchService).to receive(:new)
              .with(merge_request.source_project, merge_request.author)
              .and_call_original
            service.execute(merge_request)
          end
        end

        context 'when MR merger set the source branch to be removed' do
          let(:service) do
            described_class.new(project, user, commit_message: 'Awesome message', should_remove_source_branch: '1')
          end

          it 'removes the source branch using the current user' do
            expect(DeleteBranchService).to receive(:new)
              .with(merge_request.source_project, user)
              .and_call_original
            service.execute(merge_request)
          end
        end
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

        allow(service).to receive(:repository).and_raise(GitHooksService::PreReceiveError, error_message)
        allow(service).to receive(:execute_hooks)

        service.execute(merge_request)

        expect(merge_request.merge_error).to include(error_message)
        expect(Rails.logger).to have_received(:error).with(a_string_matching(error_message))
      end

      it 'logs and saves error if there is a merge conflict' do
        error_message = 'Conflicts detected during merge'

        allow_any_instance_of(Repository).to receive(:merge).and_return(false)
        allow(service).to receive(:execute_hooks)

        service.execute(merge_request)

        expect(merge_request).to be_open
        expect(merge_request.merge_commit_sha).to be_nil
        expect(merge_request.merge_error).to include(error_message)
        expect(Rails.logger).to have_received(:error).with(a_string_matching(error_message))
      end

      context 'when squashing' do
        before do
          merge_request.update!(source_branch: 'master', target_branch: 'feature')
        end

        it 'logs and saves error if there is an error when squashing' do
          error_message = 'Failed to squash. Should be done manually'

          allow_any_instance_of(MergeRequests::SquashService).to receive(:squash).and_return(nil)
          merge_request.update(squash: true)

          service.execute(merge_request)

          expect(merge_request).to be_open
          expect(merge_request.merge_commit_sha).to be_nil
          expect(merge_request.merge_error).to include(error_message)
          expect(Rails.logger).to have_received(:error).with(a_string_matching(error_message))
        end

        it 'logs and saves error if there is a squash in progress' do
          error_message = 'another squash is already in progress'

          allow_any_instance_of(MergeRequest).to receive(:squash_in_progress?).and_return(true)
          merge_request.update(squash: true)

          service.execute(merge_request)

          expect(merge_request).to be_open
          expect(merge_request.merge_commit_sha).to be_nil
          expect(merge_request.merge_error).to include(error_message)
          expect(Rails.logger).to have_received(:error).with(a_string_matching(error_message))
        end
      end
    end
  end

  describe '#hooks_validation_pass?' do
    shared_examples 'hook validations are skipped when push rules unlicensed' do
      subject { service.hooks_validation_pass?(merge_request) }

      before do
        stub_licensed_features(push_rules: false)
      end

      it { is_expected.to be_truthy }
    end

    let(:service) { described_class.new(project, user, commit_message: 'Awesome message') }

    it 'returns true when valid' do
      expect(service.hooks_validation_pass?(merge_request)).to be_truthy
    end

    context 'commit message validation' do
      before do
        allow(project).to receive(:push_rule) { build(:push_rule, commit_message_regex: 'unmatched pattern .*') }
      end

      it_behaves_like 'hook validations are skipped when push rules unlicensed'

      it 'returns false and saves error when invalid' do
        expect(service.hooks_validation_pass?(merge_request)).to be_falsey
        expect(merge_request.merge_error).not_to be_empty
      end
    end

    context 'authors email validation' do
      before do
        allow(project).to receive(:push_rule) { build(:push_rule, author_email_regex: '.*@unmatchedemaildomain.com') }
      end

      it_behaves_like 'hook validations are skipped when push rules unlicensed'

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
