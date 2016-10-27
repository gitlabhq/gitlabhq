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

      it 'sends email to user2 about merge of new merge_request' do
        email = ActionMailer::Base.deliveries.last
        expect(email.to.first).to eq(user2.email)
        expect(email.subject).to include(merge_request.title)
      end

      it 'creates system note about merge_request merge' do
        note = merge_request.notes.last
        expect(note.note).to include 'Status changed to merged'
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

        before do
          project.update_attributes!(has_external_issue_tracker: true)
          jira_service_settings
        end

        it 'closes issues on JIRA issue tracker' do
          jira_issue = ExternalIssue.new('JIRA-123', project)
          commit = double('commit', safe_message: "Fixes #{jira_issue.to_reference}")
          allow(merge_request).to receive(:commits).and_return([commit])

          expect_any_instance_of(JiraService).to receive(:close_issue).with(merge_request, jira_issue).once

          service.execute(merge_request)
        end

        context "wrong issue markdown" do
          it 'does not close issues on JIRA issue tracker' do
            jira_issue = ExternalIssue.new('#123', project)
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
      let(:service) { MergeRequests::MergeService.new(project, user, commit_message: 'Awesome message') }
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
        allow(service).to receive(:repository).and_raise("error message")

        allow(service).to receive(:execute_hooks)

        service.execute(merge_request)

        expect(merge_request.merge_error).to eq("Something went wrong during merge: error message")
      end

      it 'saves error if there is an PreReceiveError exception' do
        allow(service).to receive(:repository).and_raise(GitHooksService::PreReceiveError, "error")

        allow(service).to receive(:execute_hooks)

        service.execute(merge_request)

        expect(merge_request.merge_error).to eq("error")
      end

      it 'aborts if there is a merge conflict' do
        allow_any_instance_of(Repository).to receive(:merge).and_return(false)
        allow(service).to receive(:execute_hooks)

        service.execute(merge_request)

        expect(merge_request.open?).to be_truthy
        expect(merge_request.merge_commit_sha).to be_nil
        expect(merge_request.merge_error).to eq("Conflicts detected during merge")
      end
    end
  end
end
