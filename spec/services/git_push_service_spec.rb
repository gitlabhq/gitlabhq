require 'spec_helper'

describe GitPushService, services: true do
  include RepoHelpers

  let(:user)     { create(:user) }
  let(:project)  { create(:project, :repository) }
  let(:blankrev) { Gitlab::Git::BLANK_SHA }
  let(:oldrev)   { sample_commit.parent_id }
  let(:newrev)   { sample_commit.id }
  let(:ref)      { 'refs/heads/master' }

  before do
    project.add_master(user)
  end

  describe 'Push branches' do
    subject do
      execute_service(project, user, oldrev, newrev, ref)
    end

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

  describe "Git Push Data" do
    let(:commit) { project.commit(newrev) }

    subject { push_data_from_service(project, user, oldrev, newrev, ref) }

    it { is_expected.to include(object_kind: 'push') }
    it { is_expected.to include(before: oldrev) }
    it { is_expected.to include(after: newrev) }
    it { is_expected.to include(ref: ref) }
    it { is_expected.to include(user_id: user.id) }
    it { is_expected.to include(user_name: user.name) }
    it { is_expected.to include(project_id: project.id) }

    context "with repository data" do
      subject { push_data_from_service(project, user, oldrev, newrev, ref)[:repository] }

      it { is_expected.to include(name: project.name) }
      it { is_expected.to include(url: project.url_to_repo) }
      it { is_expected.to include(description: project.description) }
      it { is_expected.to include(homepage: project.web_url) }
    end

    context "with commits" do
      subject { push_data_from_service(project, user, oldrev, newrev, ref)[:commits] }

      it { is_expected.to be_an(Array) }
      it 'has 1 element' do
        expect(subject.size).to eq(1)
      end

      context "the commit" do
        subject { push_data_from_service(project, user, oldrev, newrev, ref)[:commits].first }

        it { is_expected.to include(id: commit.id) }
        it { is_expected.to include(message: commit.safe_message) }
        it { expect(subject[:timestamp].in_time_zone).to eq(commit.date.in_time_zone) }
        it do
          is_expected.to include(
            url: [
              Gitlab.config.gitlab.url,
              project.namespace.to_param,
              project.to_param,
              'commit',
              commit.id
            ].join('/')
          )
        end

        context "with a author" do
          subject { push_data_from_service(project, user, oldrev, newrev, ref)[:commits].first[:author] }

          it { is_expected.to include(name: commit.author_name) }
          it { is_expected.to include(email: commit.author_email) }
        end
      end
    end
  end

  describe "Pipelines" do
    subject { execute_service(project, user, oldrev, newrev, ref) }

    before do
      stub_ci_pipeline_to_return_yaml_file
    end

    it "creates a new pipeline" do
      expect { subject }.to change { Ci::Pipeline.count }
      expect(Ci::Pipeline.last).to be_push
    end
  end

  describe "Push Event" do
    let!(:push_data) { push_data_from_service(project, user, oldrev, newrev, ref) }
    let(:event) { Event.find_by_action(Event::PUSHED) }

    it { expect(event).to be_an_instance_of(PushEvent) }
    it { expect(event.project).to eq(project) }
    it { expect(event.action).to eq(Event::PUSHED) }
    it { expect(event.push_event_payload).to be_an_instance_of(PushEventPayload) }
    it { expect(event.push_event_payload.commit_from).to eq(oldrev) }
    it { expect(event.push_event_payload.commit_to).to eq(newrev) }
    it { expect(event.push_event_payload.ref).to eq('master') }

    context "Updates merge requests" do
      it "when pushing a new branch for the first time" do
        expect(UpdateMergeRequestsWorker).to receive(:perform_async)
                                                .with(project.id, user.id, blankrev, 'newrev', ref)
        execute_service(project, user, blankrev, 'newrev', ref )
      end
    end

    context "Sends System Push data" do
      it "when pushing on a branch" do
        expect(SystemHookPushWorker).to receive(:perform_async).with(push_data, :push_hooks)
        execute_service(project, user, oldrev, newrev, ref)
      end
    end
  end

  describe "Updates git attributes" do
    context "for default branch" do
      it "calls the copy attributes method for the first push to the default branch" do
        expect(project.repository).to receive(:copy_gitattributes).with('master')

        execute_service(project, user, blankrev, 'newrev', ref)
      end

      it "calls the copy attributes method for changes to the default branch" do
        expect(project.repository).to receive(:copy_gitattributes).with(ref)

        execute_service(project, user, 'oldrev', 'newrev', ref)
      end
    end

    context "for non-default branch" do
      before do
        # Make sure the "default" branch is different
        allow(project).to receive(:default_branch).and_return('not-master')
      end

      it "does not call copy attributes method" do
        expect(project.repository).not_to receive(:copy_gitattributes)

        execute_service(project, user, oldrev, newrev, ref)
      end
    end
  end

  describe "Webhooks" do
    context "execute webhooks" do
      it "when pushing a branch for the first time" do
        expect(project).to receive(:execute_hooks)
        expect(project.default_branch).to eq("master")
        execute_service(project, user, blankrev, 'newrev', ref)
        expect(project.protected_branches).not_to be_empty
        expect(project.protected_branches.first.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::MASTER])
        expect(project.protected_branches.first.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::MASTER])
      end

      it "when pushing a branch for the first time with default branch protection disabled" do
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_NONE)

        expect(project).to receive(:execute_hooks)
        expect(project.default_branch).to eq("master")
        execute_service(project, user, blankrev, 'newrev', ref)
        expect(project.protected_branches).to be_empty
      end

      it "when pushing a branch for the first time with default branch protection set to 'developers can push'" do
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_PUSH)

        expect(project).to receive(:execute_hooks)
        expect(project.default_branch).to eq("master")

        execute_service(project, user, blankrev, 'newrev', ref)

        expect(project.protected_branches).not_to be_empty
        expect(project.protected_branches.last.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::DEVELOPER])
        expect(project.protected_branches.last.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::MASTER])
      end

      it "when pushing a branch for the first time with an existing branch permission configured" do
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_PUSH)

        create(:protected_branch, :no_one_can_push, :developers_can_merge, project: project, name: 'master')
        expect(project).to receive(:execute_hooks)
        expect(project.default_branch).to eq("master")
        expect_any_instance_of(ProtectedBranches::CreateService).not_to receive(:execute)

        execute_service(project, user, blankrev, 'newrev', ref)

        expect(project.protected_branches).not_to be_empty
        expect(project.protected_branches.last.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::NO_ACCESS])
        expect(project.protected_branches.last.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::DEVELOPER])
      end

      it "when pushing a branch for the first time with default branch protection set to 'developers can merge'" do
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_MERGE)

        expect(project).to receive(:execute_hooks)
        expect(project.default_branch).to eq("master")
        execute_service(project, user, blankrev, 'newrev', ref)
        expect(project.protected_branches).not_to be_empty
        expect(project.protected_branches.first.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::MASTER])
        expect(project.protected_branches.first.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::DEVELOPER])
      end

      it "when pushing new commits to existing branch" do
        expect(project).to receive(:execute_hooks)
        execute_service(project, user, 'oldrev', 'newrev', ref)
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

      allow_any_instance_of(ProcessCommitWorker).to receive(:build_commit)
        .and_return(commit)

      allow(project.repository).to receive(:commits_between).and_return([commit])
    end

    it "creates a note if a pushed commit mentions an issue" do
      expect(SystemNoteService).to receive(:cross_reference).with(issue, commit, commit_author)

      execute_service(project, user, oldrev, newrev, ref)
    end

    it "only creates a cross-reference note if one doesn't already exist" do
      SystemNoteService.cross_reference(issue, commit, user)

      expect(SystemNoteService).not_to receive(:cross_reference).with(issue, commit, commit_author)

      execute_service(project, user, oldrev, newrev, ref)
    end

    it "defaults to the pushing user if the commit's author is not known" do
      allow(commit).to receive_messages(
        author_name: 'unknown name',
        author_email: 'unknown@email.com'
      )
      expect(SystemNoteService).to receive(:cross_reference).with(issue, commit, user)

      execute_service(project, user, oldrev, newrev, ref)
    end

    it "finds references in the first push to a non-default branch" do
      allow(project.repository).to receive(:commits_between).with(blankrev, newrev).and_return([])
      allow(project.repository).to receive(:commits_between).with("master", newrev).and_return([commit])

      expect(SystemNoteService).to receive(:cross_reference).with(issue, commit, commit_author)

      execute_service(project, user, blankrev, newrev, 'refs/heads/other')
    end
  end

  describe "issue metrics" do
    let(:issue) { create :issue, project: project }
    let(:commit_author) { create :user }
    let(:commit) { project.commit }
    let(:commit_time) { Time.now }

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

      allow_any_instance_of(ProcessCommitWorker).to receive(:build_commit)
        .and_return(commit)

      allow(project.repository).to receive(:commits_between).and_return([commit])
    end

    context "while saving the 'first_mentioned_in_commit_at' metric for an issue" do
      it 'sets the metric for referenced issues' do
        execute_service(project, user, oldrev, newrev, ref)

        expect(issue.reload.metrics.first_mentioned_in_commit_at).to be_like_time(commit_time)
      end

      it 'does not set the metric for non-referenced issues' do
        non_referenced_issue = create(:issue, project: project)
        execute_service(project, user, oldrev, newrev, ref)

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

      allow_any_instance_of(ProcessCommitWorker).to receive(:build_commit)
        .and_return(closing_commit)

      project.add_master(commit_author)
    end

    context "to default branches" do
      it "closes issues" do
        execute_service(project, commit_author, oldrev, newrev, ref)
        expect(Issue.find(issue.id)).to be_closed
      end

      it "adds a note indicating that the issue is now closed" do
        expect(SystemNoteService).to receive(:change_status).with(issue, project, commit_author, "closed", closing_commit)
        execute_service(project, commit_author, oldrev, newrev, ref)
      end

      it "doesn't create additional cross-reference notes" do
        expect(SystemNoteService).not_to receive(:cross_reference)
        execute_service(project, commit_author, oldrev, newrev, ref)
      end
    end

    context "to non-default branches" do
      before do
        # Make sure the "default" branch is different
        allow(project).to receive(:default_branch).and_return('not-master')
      end

      it "creates cross-reference notes" do
        expect(SystemNoteService).to receive(:cross_reference).with(issue, closing_commit, commit_author)
        execute_service(project, user, oldrev, newrev, ref)
      end

      it "doesn't close issues" do
        execute_service(project, user, oldrev, newrev, ref)
        expect(Issue.find(issue.id)).to be_opened
      end
    end

    context "for jira issue tracker" do
      include JiraServiceHelper

      let(:jira_tracker) { project.create_jira_service if project.jira_service.nil? }

      before do
        # project.create_jira_service doesn't seem to invalidate the cache here
        project.has_external_issue_tracker = true
        jira_service_settings
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

        it "initiates one api call to jira server to mention the issue" do
          execute_service(project, user, oldrev, newrev, ref)

          expect(WebMock).to have_requested(:post, jira_api_comment_url('JIRA-1')).with(
            body: /mentioned this issue in/
          ).once
        end
      end

      context "closing an issue" do
        let(:message)         { "this is some work.\n\ncloses JIRA-1" }
        let(:comment_body) do
          {
            body: "Issue solved with [#{closing_commit.id}|http://#{Gitlab.config.gitlab.host}/#{project.full_path}/commit/#{closing_commit.id}]."
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

        context "using right markdown" do
          it "initiates one api call to jira server to close the issue" do
            execute_service(project, commit_author, oldrev, newrev, ref)

            expect(WebMock).to have_requested(:post, jira_api_transition_url('JIRA-1')).once
          end

          it "initiates one api call to jira server to comment on the issue" do
            execute_service(project, commit_author, oldrev, newrev, ref)

            expect(WebMock).to have_requested(:post, jira_api_comment_url('JIRA-1')).with(
              body: comment_body
            ).once
          end
        end

        context "using internal issue reference" do
          context 'when internal issues are disabled' do
            before do
              project.issues_enabled = false
              project.save!
            end
            let(:message) { "this is some work.\n\ncloses #1" }

            it "does not initiates one api call to jira server to close the issue" do
              execute_service(project, commit_author, oldrev, newrev, ref)

              expect(WebMock).not_to have_requested(:post, jira_api_transition_url('JIRA-1'))
            end

            it "does not initiates one api call to jira server to comment on the issue" do
              execute_service(project, commit_author, oldrev, newrev, ref)

              expect(WebMock).not_to have_requested(:post, jira_api_comment_url('JIRA-1')).with(
                body: comment_body
              ).once
            end
          end

          context 'when internal issues are enabled' do
            let(:issue) { create(:issue, project: project) }
            let(:message) { "this is some work.\n\ncloses JIRA-1 \n\n closes #{issue.to_reference}" }

            it "initiates one api call to jira server to close the jira issue" do
              execute_service(project, commit_author, oldrev, newrev, ref)

              expect(WebMock).to have_requested(:post, jira_api_transition_url('JIRA-1')).once
            end

            it "initiates one api call to jira server to comment on the jira issue" do
              execute_service(project, commit_author, oldrev, newrev, ref)

              expect(WebMock).to have_requested(:post, jira_api_comment_url('JIRA-1')).with(
                body: comment_body
              ).once
            end

            it "closes the internal issue" do
              execute_service(project, commit_author, oldrev, newrev, ref)
              expect(issue.reload).to be_closed
            end

            it "adds a note indicating that the issue is now closed" do
              expect(SystemNoteService).to receive(:change_status)
                .with(issue, project, commit_author, "closed", closing_commit)
              execute_service(project, commit_author, oldrev, newrev, ref)
            end
          end
        end
      end
    end
  end

  describe "empty project" do
    let(:project) { create(:project_empty_repo) }
    let(:new_ref) { 'refs/heads/feature' }

    before do
      allow(project).to receive(:default_branch).and_return('feature')
      expect(project).to receive(:change_head) { 'feature'}
    end

    it 'push to first branch updates HEAD' do
      execute_service(project, user, blankrev, newrev, new_ref)
    end
  end

  describe "housekeeping" do
    let(:housekeeping) { Projects::HousekeepingService.new(project) }

    before do
      # Flush any raw key-value data stored by the housekeeping code.
      Gitlab::Redis::Cache.with { |conn| conn.flushall }
      Gitlab::Redis::Queues.with { |conn| conn.flushall }
      Gitlab::Redis::SharedState.with { |conn| conn.flushall }

      allow(Projects::HousekeepingService).to receive(:new).and_return(housekeeping)
    end

    after do
      Gitlab::Redis::Cache.with { |conn| conn.flushall }
      Gitlab::Redis::Queues.with { |conn| conn.flushall }
      Gitlab::Redis::SharedState.with { |conn| conn.flushall }
    end

    it 'does not perform housekeeping when not needed' do
      expect(housekeeping).not_to receive(:execute)

      execute_service(project, user, oldrev, newrev, ref)
    end

    context 'when housekeeping is needed' do
      before do
        allow(housekeeping).to receive(:needed?).and_return(true)
      end

      it 'performs housekeeping' do
        expect(housekeeping).to receive(:execute)

        execute_service(project, user, oldrev, newrev, ref)
      end

      it 'does not raise an exception' do
        allow(housekeeping).to receive(:try_obtain_lease).and_return(false)

        execute_service(project, user, oldrev, newrev, ref)
      end
    end

    it 'increments the push counter' do
      expect(housekeeping).to receive(:increment!)

      execute_service(project, user, oldrev, newrev, ref)
    end
  end

  describe '#update_caches' do
    let(:service) do
      described_class.new(project,
                          user,
                          oldrev: oldrev,
                          newrev: newrev,
                          ref: ref)
    end

    context 'on the default branch' do
      before do
        allow(service).to receive(:default_branch?).and_return(true)
      end

      it 'flushes the caches of any special files that have been changed' do
        commit = double(:commit)
        diff = double(:diff, new_path: 'README.md')

        expect(commit).to receive(:raw_deltas)
          .and_return([diff])

        service.push_commits = [commit]

        expect(ProjectCacheWorker).to receive(:perform_async)
          .with(project.id, %i(readme), %i(commit_count repository_size))

        service.update_caches
      end
    end

    context 'on a non-default branch' do
      before do
        allow(service).to receive(:default_branch?).and_return(false)
      end

      it 'does not flush any conditional caches' do
        expect(ProjectCacheWorker).to receive(:perform_async)
          .with(project.id, [], %i(commit_count repository_size))
          .and_call_original

        service.update_caches
      end
    end
  end

  describe '#process_commit_messages' do
    let(:service) do
      described_class.new(project,
                          user,
                          oldrev: oldrev,
                          newrev: newrev,
                          ref: ref)
    end

    it 'only schedules a limited number of commits' do
      service.push_commits = Array.new(1000, double(:commit, to_hash: {}, matches_cross_reference_regex?: true))

      expect(ProcessCommitWorker).to receive(:perform_async).exactly(100).times

      service.process_commit_messages
    end

    it "skips commits which don't include cross-references" do
      service.push_commits = [double(:commit, to_hash: {}, matches_cross_reference_regex?: false)]

      expect(ProcessCommitWorker).not_to receive(:perform_async)

      service.process_commit_messages
    end
  end

  describe '#update_signatures' do
    let(:service) do
      described_class.new(
        project,
        user,
        oldrev: oldrev,
        newrev: newrev,
        ref: 'refs/heads/master'
      )
    end

    context 'when the commit has a signature' do
      context 'when the signature is already cached' do
        before do
          create(:gpg_signature, commit_sha: sample_commit.id)
        end

        it 'does not queue a CreateGpgSignatureWorker' do
          expect(CreateGpgSignatureWorker).not_to receive(:perform_async).with(sample_commit.id, project.id)

          execute_service(project, user, oldrev, newrev, ref)
        end
      end

      context 'when the signature is not yet cached' do
        it 'queues a CreateGpgSignatureWorker' do
          expect(CreateGpgSignatureWorker).to receive(:perform_async).with(sample_commit.id, project.id)

          execute_service(project, user, oldrev, newrev, ref)
        end
      end
    end

    context 'when the commit does not have a signature' do
      before do
        allow(Gitlab::Git::Commit).to receive(:shas_with_signatures).with(project.repository, [sample_commit.id]).and_return([])
      end

      it 'does not queue a CreateGpgSignatureWorker' do
        expect(CreateGpgSignatureWorker).not_to receive(:perform_async).with(sample_commit.id, project.id)

        execute_service(project, user, oldrev, newrev, ref)
      end
    end
  end

  def execute_service(project, user, oldrev, newrev, ref)
    service = described_class.new(project, user, oldrev: oldrev, newrev: newrev, ref: ref)
    service.execute
    service
  end

  def push_data_from_service(project, user, oldrev, newrev, ref)
    execute_service(project, user, oldrev, newrev, ref).push_data
  end
end
