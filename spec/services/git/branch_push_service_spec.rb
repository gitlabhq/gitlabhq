# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::BranchPushService, :use_clean_rails_redis_caching, :services, feature_category: :source_code_management do
  include RepoHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:project) { create(:project, :repository, maintainers: user) }

  let(:blankrev) { Gitlab::Git::SHA1_BLANK_SHA }
  let(:oldrev)   { sample_commit.parent_id }
  let(:newrev)   { sample_commit.id }
  let(:branch)   { 'master' }
  let(:ref)      { "refs/heads/#{branch}" }
  let(:push_options) { nil }
  let(:params) { { change: { oldrev: oldrev, newrev: newrev, ref: ref }, push_options: push_options } }

  let(:service) do
    described_class.new(project, user, **params)
  end

  subject(:execute_service) do
    service.execute
  end

  describe 'Push branches' do
    context 'new branch' do
      let(:oldrev) { blankrev }

      it { is_expected.to be_truthy }

      it 'calls the after_push_commit hook' do
        expect(project.repository).to receive(:after_push_commit).with('master')

        subject
      end

      it 'calls the after_create_branch hook' do
        expect(project.repository).to receive(:after_create_branch)

        subject
      end
    end

    context 'existing branch' do
      it { is_expected.to be_truthy }

      it 'calls the after_push_commit hook' do
        expect(project.repository).to receive(:after_push_commit).with('master')

        subject
      end
    end

    context 'rm branch' do
      let(:newrev) { blankrev }

      it { is_expected.to be_truthy }

      it 'calls the after_push_commit hook' do
        expect(project.repository).to receive(:after_push_commit).with('master')

        subject
      end

      it 'calls the after_remove_branch hook' do
        expect(project.repository).to receive(:after_remove_branch)

        subject
      end
    end
  end

  describe "Pipelines" do
    before do
      stub_ci_pipeline_to_return_yaml_file
    end

    it 'creates a pipeline with the right parameters' do
      expect(Ci::CreatePipelineService).to receive(:new).with(
        project,
        user,
        {
          before: oldrev,
          after: newrev,
          ref: ref,
          checkout_sha: SeedRepo::Commit::ID,
          variables_attributes: [],
          push_options: {}
        }
      ).and_call_original

      subject
    end

    it "creates a new pipeline" do
      expect { subject }.to change { Ci::Pipeline.count }

      pipeline = Ci::Pipeline.last
      expect(pipeline).to be_push
      expect(Gitlab::Git::BRANCH_REF_PREFIX + pipeline.ref).to eq(ref)
    end

    context 'when pipeline has errors' do
      before do
        config = YAML.dump({ test: { script: 'ls', only: ['feature'] } })
        stub_ci_pipeline_yaml_file(config)
      end

      it 'reports an error' do
        allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)
        expect(Sidekiq.logger).to receive(:warn)

        expect { subject }.not_to change { Ci::Pipeline.count }
      end

      context 'with push options' do
        let(:push_options) { { 'mr' => { 'create' => true } } }

        it 'sanitizes push options' do
          allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)
          expect(Sidekiq.logger).to receive(:warn) do |args|
            pipeline_params = args[:pipeline_params]
            expect(pipeline_params.keys).to match_array(%i[before after ref variables_attributes checkout_sha])
          end

          expect { subject }.not_to change { Ci::Pipeline.count }
        end
      end
    end

    context 'when .gitlab-ci.yml file is invalid' do
      before do
        stub_ci_pipeline_yaml_file('invalid yaml file')
      end

      it 'persists an error pipeline' do
        expect { subject }.to change { Ci::Pipeline.count }

        pipeline = Ci::Pipeline.last
        expect(pipeline).to be_push
        expect(pipeline).to be_failed
        expect(pipeline).to be_config_error
      end
    end
  end

  describe "Updates merge requests" do
    let(:oldrev) { blankrev }

    it "when pushing a new branch for the first time" do
      expect(UpdateMergeRequestsWorker)
        .to receive(:perform_async)
        .with(project.id, user.id, blankrev, newrev, ref, { 'push_options' => nil })
        .ordered

      subject
    end
  end

  describe "Webhooks" do
    before do
      create(:project_hook, push_events: true, project: project)
    end

    context "when pushing a branch for the first time" do
      let(:oldrev) { blankrev }

      it "executes webhooks" do
        expect(project).to receive(:execute_hooks)
        expect(project.default_branch).to eq("master")

        subject

        expect(project.protected_branches).not_to be_empty
        expect(project.protected_branches.first.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::MAINTAINER])
        expect(project.protected_branches.first.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::MAINTAINER])
      end

      it "with default branch protection disabled" do
        expect(project.namespace).to receive(:default_branch_protection_settings).and_return(Gitlab::Access::BranchProtection.protection_none)

        expect(project).to receive(:execute_hooks)
        expect(project.default_branch).to eq("master")
        subject
        expect(project.protected_branches).to be_empty
      end

      it "with default branch protection set to 'developers can push'" do
        expect(project.namespace).to receive(:default_branch_protection_settings).and_return(Gitlab::Access::BranchProtection.protection_partial)

        expect(project).to receive(:execute_hooks)
        expect(project.default_branch).to eq("master")

        subject

        expect(project.protected_branches).not_to be_empty
        expect(project.protected_branches.last.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::DEVELOPER])
        expect(project.protected_branches.last.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::MAINTAINER])
      end

      it "with an existing branch permission configured" do
        expect(project.namespace).to receive(:default_branch_protection_settings).and_return(Gitlab::Access::BranchProtection.protection_partial)

        create(:protected_branch, :no_one_can_push, :developers_can_merge, project: project, name: 'master')
        expect(project).to receive(:execute_hooks)
        expect(project.default_branch).to eq("master")
        expect(ProtectedBranches::CreateService).not_to receive(:new)

        subject

        expect(project.protected_branches).not_to be_empty
        expect(project.protected_branches.last.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::NO_ACCESS])
        expect(project.protected_branches.last.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::DEVELOPER])
      end

      it "with default branch protection set to 'developers can merge'" do
        expect(project.namespace).to receive(:default_branch_protection_settings).and_return(Gitlab::Access::BranchProtection.protected_against_developer_pushes)

        expect(project).to receive(:execute_hooks)
        expect(project.default_branch).to eq("master")
        subject
        expect(project.protected_branches).not_to be_empty
        expect(project.protected_branches.first.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::MAINTAINER])
        expect(project.protected_branches.first.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::DEVELOPER])
      end
    end

    context "when pushing new commits to existing branch" do
      it "executes webhooks" do
        expect(project).to receive(:execute_hooks)
        subject
      end
    end
  end

  describe "cross-reference notes" do
    let(:issue) { create :issue, project: project }
    let(:commit_author) { create :user }
    let(:commit) { project.commit }

    before do
      project.add_developer(commit_author)
      project.add_developer(user)

      allow(commit).to receive_messages(
        safe_message: "this commit \n mentions #{issue.to_reference}",
        references: [issue],
        author_name: commit_author.name,
        author_email: commit_author.email
      )

      allow(Commit).to receive(:build_from_sidekiq_hash)
        .and_return(commit)

      allow(project.repository).to receive(:commits_between).and_return([commit])
    end

    it "creates a note if a pushed commit mentions an issue", :sidekiq_might_not_need_inline do
      expect(SystemNoteService).to receive(:cross_reference).with(issue, commit, commit_author)

      subject
    end

    it "only creates a cross-reference note if one doesn't already exist" do
      SystemNoteService.cross_reference(issue, commit, user)

      expect(SystemNoteService).not_to receive(:cross_reference).with(issue, commit, commit_author)

      subject
    end

    it "defaults to the pushing user if the commit's author is not known", :sidekiq_inline, :use_clean_rails_redis_caching do
      allow(commit).to receive_messages(
        author_name: 'unknown name',
        author_email: 'unknown@email.com'
      )
      expect(SystemNoteService).to receive(:cross_reference).with(issue, commit, user)

      subject
    end

    context "when first push on a non-default branch" do
      let(:oldrev) { blankrev }
      let(:ref) { 'refs/heads/other' }

      it "finds references", :sidekiq_might_not_need_inline do
        allow(project.repository).to receive(:commits_between).with(blankrev, newrev).and_return([])
        allow(project.repository).to receive(:commits_between).with("master", newrev).and_return([commit])

        expect(SystemNoteService).to receive(:cross_reference).with(issue, commit, commit_author)

        subject
      end
    end
  end

  describe "issue metrics" do
    let(:issue) { create :issue, project: project }
    let(:commit_author) { create :user }
    let(:commit) { project.commit }
    let(:commit_time) { Time.current }

    before do
      project.add_developer(commit_author)
      project.add_developer(user)

      allow(commit).to receive_messages(
        safe_message: "this commit \n mentions #{issue.to_reference}",
        references: [issue],
        author_name: commit_author.name,
        author_email: commit_author.email,
        committed_date: commit_time
      )

      allow(Commit).to receive(:build_from_sidekiq_hash)
        .and_return(commit)

      allow(project.repository).to receive(:commits_between).and_return([commit])
    end

    context "while saving the 'first_mentioned_in_commit_at' metric for an issue" do
      it 'sets the metric for referenced issues', :sidekiq_inline, :use_clean_rails_redis_caching do
        subject

        expect(issue.reload.metrics.first_mentioned_in_commit_at).to be_like_time(commit_time)
      end

      it 'does not set the metric for non-referenced issues' do
        non_referenced_issue = create(:issue, project: project)
        subject

        expect(non_referenced_issue.reload.metrics.first_mentioned_in_commit_at).to be_nil
      end
    end
  end

  describe "closing issues from pushed commits containing a closing reference" do
    let(:issue) { create :issue, project: project }
    let(:other_issue) { create :issue, project: project }
    let(:commit_author) { create :user }
    let(:closing_commit) { project.commit }

    before do
      allow(closing_commit).to receive_messages(
        issue_closing_regex: /^([Cc]loses|[Ff]ixes) #\d+/,
        safe_message: "this is some work.\n\ncloses ##{issue.iid}",
        author_name: commit_author.name,
        author_email: commit_author.email
      )

      allow(project.repository).to receive(:commits_between)
        .and_return([closing_commit])

      allow(Commit).to receive(:build_from_sidekiq_hash)
        .and_return(closing_commit)

      project.add_maintainer(commit_author)
    end

    context "to default branches" do
      let(:user) { commit_author }

      it "closes issues", :sidekiq_might_not_need_inline do
        subject
        expect(Issue.find(issue.id)).to be_closed
      end

      it "adds a note indicating that the issue is now closed", :sidekiq_might_not_need_inline do
        expect(SystemNoteService).to receive(:change_status).with(issue, project, commit_author, "closed", closing_commit)
        subject
      end

      it "doesn't create additional cross-reference notes" do
        expect(SystemNoteService).not_to receive(:cross_reference)
        subject
      end
    end

    context "to non-default branches" do
      before do
        # Make sure the "default" branch is different
        allow(project).to receive(:default_branch).and_return('not-master')
      end

      it "creates cross-reference notes", :sidekiq_inline, :use_clean_rails_redis_caching do
        expect(SystemNoteService).to receive(:cross_reference).with(issue, closing_commit, commit_author)
        subject
      end

      it "doesn't close issues" do
        subject
        expect(Issue.find(issue.id)).to be_opened
      end
    end

    context "for jira issue tracker" do
      include JiraIntegrationHelpers

      let(:jira_tracker) { project.create_jira_integration if project.jira_integration.nil? }

      before do
        # project.create_jira_integration doesn't seem to invalidate the cache here
        project.has_external_issue_tracker = true
        stub_jira_integration_test
        jira_integration_settings
        stub_jira_urls("JIRA-1")

        allow(closing_commit).to receive_messages({
          issue_closing_regex: Regexp.new(Gitlab.config.gitlab.issue_closing_pattern),
          safe_message: message,
          author_name: commit_author.name,
          author_email: commit_author.email
        })

        allow(JIRA::Resource::Remotelink).to receive(:all).and_return([])

        allow(project.repository).to receive_messages(commits_between: [closing_commit])
      end

      after do
        jira_tracker.destroy!
      end

      context "mentioning an issue" do
        let(:message) { "this is some work.\n\nrelated to JIRA-1" }

        it "initiates one api call to jira server to mention the issue", :sidekiq_inline, :use_clean_rails_redis_caching do
          subject

          expect(WebMock).to have_requested(:post, jira_api_comment_url('JIRA-1')).with(
            body: /mentioned this issue in/
          ).once
        end
      end

      context "closing an issue" do
        let(:message) { "this is some work.\n\ncloses JIRA-1" }
        let(:comment_body) do
          {
            body: "Issue solved with [#{closing_commit.id}|http://#{Gitlab.config.gitlab.host}/#{project.full_path}/-/commit/#{closing_commit.id}]."
          }.to_json
        end

        before do
          open_issue   = JIRA::Resource::Issue.new(jira_tracker.client, attrs: { "id" => "JIRA-1" })
          closed_issue = open_issue.dup
          allow(open_issue).to receive(:resolution).and_return(false)
          allow(closed_issue).to receive(:resolution).and_return(true)
          allow(JIRA::Resource::Issue).to receive(:find).and_return(open_issue, closed_issue)

          allow_any_instance_of(JIRA::Resource::Issue).to receive(:key).and_return("JIRA-1")
        end

        context "using right markdown", :sidekiq_might_not_need_inline do
          let(:user) { commit_author }

          it "initiates one api call to jira server to close the issue" do
            subject

            expect(WebMock).to have_requested(:post, jira_api_transition_url('JIRA-1')).once
          end

          it "initiates one api call to jira server to comment on the issue" do
            subject

            expect(WebMock)
              .to have_requested(:post, jira_api_comment_url('JIRA-1'))
              .with(body: comment_body)
              .once
          end
        end

        context "using internal issue reference" do
          let(:user) { commit_author }

          context 'when internal issues are disabled' do
            before do
              project.issues_enabled = false
              project.save!
            end

            let(:message) { "this is some work.\n\ncloses #1" }

            it "does not initiates one api call to jira server to close the issue" do
              subject

              expect(WebMock).not_to have_requested(:post, jira_api_transition_url('JIRA-1'))
            end

            it "does not initiates one api call to jira server to comment on the issue" do
              subject

              expect(WebMock).not_to have_requested(:post, jira_api_comment_url('JIRA-1')).with(
                body: comment_body
              ).once
            end
          end

          context 'when internal issues are enabled', :sidekiq_might_not_need_inline do
            let(:issue) { create(:issue, project: project) }
            let(:message) { "this is some work.\n\ncloses JIRA-1 \n\n closes #{issue.to_reference}" }

            it "initiates one api call to jira server to close the jira issue" do
              subject

              expect(WebMock).to have_requested(:post, jira_api_transition_url('JIRA-1')).once
            end

            it "initiates one api call to jira server to comment on the jira issue" do
              subject

              expect(WebMock).to have_requested(:post, jira_api_comment_url('JIRA-1')).with(
                body: comment_body
              ).once
            end

            it "closes the internal issue" do
              subject
              expect(issue.reload).to be_closed
            end

            it "adds a note indicating that the issue is now closed" do
              expect(SystemNoteService).to receive(:change_status)
                .with(issue, project, commit_author, "closed", closing_commit)
              subject
            end
          end
        end
      end
    end
  end

  describe "empty project" do
    let(:project) { create(:project_empty_repo) }
    let(:ref) { 'refs/heads/feature' }
    let(:oldrev) { blankrev }

    before do
      allow(project).to receive(:default_branch).and_return('feature')
      expect(project).to receive(:change_head) { 'feature' }
    end

    it 'push to first branch updates HEAD' do
      subject
    end
  end

  describe "CI environments" do
    context 'create branch' do
      let(:oldrev) { blankrev }

      it 'does nothing' do
        expect(::Environments::StopService).not_to receive(:new)

        subject
      end
    end

    context 'update branch' do
      it 'does nothing' do
        expect(::Environments::StopService).not_to receive(:new)

        subject
      end
    end

    context 'delete branch' do
      let(:newrev) { blankrev }

      it 'stops environments' do
        expect_next_instance_of(::Environments::StopService) do |stop_service|
          expect(stop_service.project).to eq(project)
          expect(stop_service.current_user).to eq(user)
          expect(stop_service).to receive(:execute_for_branch).with(branch)
        end

        subject
      end
    end
  end

  describe 'artifacts' do
    context 'create branch' do
      let(:oldrev) { blankrev }

      it 'does nothing' do
        expect(::Ci::RefDeleteUnlockArtifactsWorker).not_to receive(:perform_async)

        subject
      end
    end

    context 'update branch' do
      it 'does nothing' do
        expect(::Ci::RefDeleteUnlockArtifactsWorker).not_to receive(:perform_async)

        subject
      end
    end

    context 'delete branch' do
      let(:newrev) { blankrev }

      it 'unlocks artifacts' do
        expect(::Ci::RefDeleteUnlockArtifactsWorker)
          .to receive(:perform_async).with(project.id, user.id, "refs/heads/#{branch}")

        subject
      end
    end
  end

  describe 'Hooks' do
    context 'run on a branch' do
      let(:process_commit_worker_pool) { Gitlab::Git::ProcessCommitWorkerPool.new }
      let(:params) { super().merge(process_commit_worker_pool: process_commit_worker_pool) }

      it 'delegates to Git::BranchHooksService' do
        expect_next_instance_of(::Git::BranchHooksService) do |hooks_service|
          expect(hooks_service.project).to eq(project)
          expect(hooks_service.current_user).to eq(user)
          expect(hooks_service.params).to include(
            change: {
              oldrev: oldrev,
              newrev: newrev,
              ref: ref
            },
            process_commit_worker_pool: process_commit_worker_pool
          )

          expect(hooks_service).to receive(:execute)
        end

        subject
      end
    end

    context 'run on a tag' do
      let(:ref) { 'refs/tags/v1.1.0' }

      it 'does nothing' do
        expect(::Git::BranchHooksService).not_to receive(:new)

        subject
      end
    end
  end

  context 'Jira Connect hooks' do
    let(:branch_to_sync) { nil }
    let(:commits_to_sync) { [] }

    shared_examples 'enqueues Jira sync worker' do
      specify :aggregate_failures do
        Sidekiq::Testing.fake! do
          if commits_to_sync.any?
            expect(JiraConnect::SyncBranchWorker)
              .to receive(:perform_in)
              .with(kind_of(Numeric), project.id, branch_to_sync, commits_to_sync, kind_of(Numeric))
              .and_call_original
          else
            expect(JiraConnect::SyncBranchWorker)
              .to receive(:perform_async)
              .with(project.id, branch_to_sync, commits_to_sync, kind_of(Numeric))
              .and_call_original
          end

          expect { subject }.to change(JiraConnect::SyncBranchWorker.jobs, :size).by(1)
        end
      end
    end

    shared_examples 'does not enqueue Jira sync worker' do
      specify do
        Sidekiq::Testing.fake! do
          expect { subject }.not_to change(JiraConnect::SyncBranchWorker.jobs, :size)
        end
      end
    end

    context 'with a Jira subscription' do
      before do
        create(:jira_connect_subscription, namespace: project.namespace)
      end

      context 'branch name contains Jira issue key' do
        let(:branch_to_sync) { 'branch-JIRA-123' }
        let(:ref) { "refs/heads/#{branch_to_sync}" }

        it_behaves_like 'enqueues Jira sync worker'
      end

      context 'commit message contains Jira issue key' do
        let(:commits_to_sync) { [newrev] }

        before do
          allow_any_instance_of(Commit).to receive(:safe_message).and_return('Commit with key JIRA-123')
        end

        it_behaves_like 'enqueues Jira sync worker'

        describe 'batch requests' do
          let(:commits_to_sync) { [sample_commit.id, another_sample_commit.id] }

          it 'enqueues multiple jobs' do
            # We have to stub this as we only have two valid commits to use
            stub_const('Git::BranchHooksService::JIRA_SYNC_BATCH_SIZE', 1)

            expect_any_instance_of(Git::BranchHooksService).to receive(:filtered_commit_shas).and_return(commits_to_sync)

            expect(JiraConnect::SyncBranchWorker)
              .to receive(:perform_in)
              .with(0.seconds, project.id, branch_to_sync, [commits_to_sync.first], kind_of(Numeric))
              .and_call_original

            expect(JiraConnect::SyncBranchWorker)
              .to receive(:perform_in)
              .with(10.seconds, project.id, branch_to_sync, [commits_to_sync.last], kind_of(Numeric))
              .and_call_original

            subject
          end
        end
      end

      context 'branch name and commit message does not contain Jira issue key' do
        it_behaves_like 'does not enqueue Jira sync worker'
      end
    end

    context 'without a Jira subscription' do
      it_behaves_like 'does not enqueue Jira sync worker'
    end
  end

  describe 'project target platforms detection' do
    let(:oldrev) { blankrev }

    it 'calls enqueue_record_project_target_platforms on the project' do
      expect(project).to receive(:enqueue_record_project_target_platforms)

      subject
    end
  end
end
