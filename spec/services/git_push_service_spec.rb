require 'spec_helper'

describe GitPushService, services: true do
  include RepoHelpers

  let(:user)          { create :user }
  let(:project)       { create :project }

  before do
    project.team << [user, :master]
    @blankrev = Gitlab::Git::BLANK_SHA
    @oldrev = sample_commit.parent_id
    @newrev = sample_commit.id
    @ref = 'refs/heads/master'
  end

  describe 'Push branches' do
    let(:oldrev) { @oldrev }
    let(:newrev) { @newrev }

    subject do
      execute_service(project, user, oldrev, newrev, @ref )
    end

    context 'new branch' do
      let(:oldrev) { @blankrev }

      it { is_expected.to be_truthy }

      it 'flushes general cached data' do
        expect(project.repository).to receive(:expire_cache).
          with('master', newrev)

        subject
      end

      it 'flushes the visible content cache' do
        expect(project.repository).to receive(:expire_has_visible_content_cache)

        subject
      end

      it 'flushes the branches cache' do
        expect(project.repository).to receive(:expire_branches_cache)

        subject
      end

      it 'flushes the branch count cache' do
        expect(project.repository).to receive(:expire_branch_count_cache)

        subject
      end
    end

    context 'existing branch' do
      it { is_expected.to be_truthy }

      it 'flushes general cached data' do
        expect(project.repository).to receive(:expire_cache).
          with('master', newrev)

        subject
      end

      it 'does not flush the branches cache' do
        expect(project.repository).not_to receive(:expire_branches_cache)

        subject
      end

      it 'does not flush the branch count cache' do
        expect(project.repository).not_to receive(:expire_branch_count_cache)

        subject
      end
    end

    context 'rm branch' do
      let(:newrev) { @blankrev }

      it { is_expected.to be_truthy }

      it 'flushes the visible content cache' do
        expect(project.repository).to receive(:expire_has_visible_content_cache)

        subject
      end

      it 'flushes the branches cache' do
        expect(project.repository).to receive(:expire_branches_cache)

        subject
      end

      it 'flushes the branch count cache' do
        expect(project.repository).to receive(:expire_branch_count_cache)

        subject
      end

      it 'flushes general cached data' do
        expect(project.repository).to receive(:expire_cache).
          with('master', newrev)

        subject
      end
    end
  end

  describe "Git Push Data" do
    before do
      service = execute_service(project, user, @oldrev, @newrev, @ref )
      @push_data = service.push_data
      @commit = project.commit(@newrev)
    end

    subject { @push_data }

    it { is_expected.to include(object_kind: 'push') }
    it { is_expected.to include(before: @oldrev) }
    it { is_expected.to include(after: @newrev) }
    it { is_expected.to include(ref: @ref) }
    it { is_expected.to include(user_id: user.id) }
    it { is_expected.to include(user_name: user.name) }
    it { is_expected.to include(project_id: project.id) }

    context "with repository data" do
      subject { @push_data[:repository] }

      it { is_expected.to include(name: project.name) }
      it { is_expected.to include(url: project.url_to_repo) }
      it { is_expected.to include(description: project.description) }
      it { is_expected.to include(homepage: project.web_url) }
    end

    context "with commits" do
      subject { @push_data[:commits] }

      it { is_expected.to be_an(Array) }
      it 'has 1 element' do
        expect(subject.size).to eq(1)
      end

      context "the commit" do
        subject { @push_data[:commits].first }

        it { is_expected.to include(id: @commit.id) }
        it { is_expected.to include(message: @commit.safe_message) }
        it { is_expected.to include(timestamp: @commit.date.xmlschema) }
        it do
          is_expected.to include(
            url: [
              Gitlab.config.gitlab.url,
              project.namespace.to_param,
              project.to_param,
              'commit',
              @commit.id
            ].join('/')
          )
        end

        context "with a author" do
          subject { @push_data[:commits].first[:author] }

          it { is_expected.to include(name: @commit.author_name) }
          it { is_expected.to include(email: @commit.author_email) }
        end
      end
    end
  end

  describe "Push Event" do
    before do
      service = execute_service(project, user, @oldrev, @newrev, @ref )
      @event = Event.find_by_action(Event::PUSHED)
      @push_data = service.push_data
    end

    it { expect(@event).not_to be_nil }
    it { expect(@event.project).to eq(project) }
    it { expect(@event.action).to eq(Event::PUSHED) }
    it { expect(@event.data).to eq(@push_data) }

    context "Updates merge requests" do
      it "when pushing a new branch for the first time" do
        expect(UpdateMergeRequestsWorker).to receive(:perform_async).
                                                with(project.id, user.id, @blankrev, 'newrev', 'refs/heads/master')
        execute_service(project, user, @blankrev, 'newrev', 'refs/heads/master' )
      end
    end
  end

  describe "Updates git attributes" do
    context "for default branch" do
      it "calls the copy attributes method for the first push to the default branch" do
        expect(project.repository).to receive(:copy_gitattributes).with('master')

        execute_service(project, user, @blankrev, 'newrev', 'refs/heads/master')
      end

      it "calls the copy attributes method for changes to the default branch" do
        expect(project.repository).to receive(:copy_gitattributes).with('refs/heads/master')

        execute_service(project, user, 'oldrev', 'newrev', 'refs/heads/master')
      end
    end

    context "for non-default branch" do
      before do
        # Make sure the "default" branch is different
        allow(project).to receive(:default_branch).and_return('not-master')
      end

      it "does not call copy attributes method" do
        expect(project.repository).not_to receive(:copy_gitattributes)

        execute_service(project, user, @oldrev, @newrev, @ref)
      end
    end
  end

  describe "Webhooks" do
    context "execute webhooks" do
      it "when pushing a branch for the first time" do
        expect(project).to receive(:execute_hooks)
        expect(project.default_branch).to eq("master")
        execute_service(project, user, @blankrev, 'newrev', 'refs/heads/master' )
        expect(project.protected_branches).not_to be_empty
        expect(project.protected_branches.first.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::MASTER])
        expect(project.protected_branches.first.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::MASTER])
      end

      it "when pushing a branch for the first time with default branch protection disabled" do
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_NONE)

        expect(project).to receive(:execute_hooks)
        expect(project.default_branch).to eq("master")
        execute_service(project, user, @blankrev, 'newrev', 'refs/heads/master' )
        expect(project.protected_branches).to be_empty
      end

      it "when pushing a branch for the first time with default branch protection set to 'developers can push'" do
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_PUSH)

        expect(project).to receive(:execute_hooks)
        expect(project.default_branch).to eq("master")

        execute_service(project, user, @blankrev, 'newrev', 'refs/heads/master' )

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

        execute_service(project, user, @blankrev, 'newrev', 'refs/heads/master' )

        expect(project.protected_branches).not_to be_empty
        expect(project.protected_branches.last.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::NO_ACCESS])
        expect(project.protected_branches.last.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::DEVELOPER])
      end

      it "when pushing a branch for the first time with default branch protection set to 'developers can merge'" do
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_MERGE)

        expect(project).to receive(:execute_hooks)
        expect(project.default_branch).to eq("master")
        execute_service(project, user, @blankrev, 'newrev', 'refs/heads/master' )
        expect(project.protected_branches).not_to be_empty
        expect(project.protected_branches.first.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::MASTER])
        expect(project.protected_branches.first.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::DEVELOPER])
      end

      it "when pushing new commits to existing branch" do
        expect(project).to receive(:execute_hooks)
        execute_service(project, user, 'oldrev', 'newrev', 'refs/heads/master' )
      end
    end
  end

  describe "cross-reference notes" do
    let(:issue) { create :issue, project: project }
    let(:commit_author) { create :user }
    let(:commit) { project.commit }

    before do
      project.team << [commit_author, :developer]
      project.team << [user, :developer]

      allow(commit).to receive_messages(
        safe_message: "this commit \n mentions #{issue.to_reference}",
        references: [issue],
        author_name: commit_author.name,
        author_email: commit_author.email
      )

      allow_any_instance_of(ProcessCommitWorker).to receive(:find_commit).
        and_return(commit)

      allow(project.repository).to receive(:commits_between).and_return([commit])
    end

    it "creates a note if a pushed commit mentions an issue" do
      expect(SystemNoteService).to receive(:cross_reference).with(issue, commit, commit_author)

      execute_service(project, user, @oldrev, @newrev, @ref )
    end

    it "only creates a cross-reference note if one doesn't already exist" do
      SystemNoteService.cross_reference(issue, commit, user)

      expect(SystemNoteService).not_to receive(:cross_reference).with(issue, commit, commit_author)

      execute_service(project, user, @oldrev, @newrev, @ref )
    end

    it "defaults to the pushing user if the commit's author is not known" do
      allow(commit).to receive_messages(
        author_name: 'unknown name',
        author_email: 'unknown@email.com'
      )
      expect(SystemNoteService).to receive(:cross_reference).with(issue, commit, user)

      execute_service(project, user, @oldrev, @newrev, @ref )
    end

    it "finds references in the first push to a non-default branch" do
      allow(project.repository).to receive(:commits_between).with(@blankrev, @newrev).and_return([])
      allow(project.repository).to receive(:commits_between).with("master", @newrev).and_return([commit])

      expect(SystemNoteService).to receive(:cross_reference).with(issue, commit, commit_author)

      execute_service(project, user, @blankrev, @newrev, 'refs/heads/other' )
    end
  end

  describe "issue metrics" do
    let(:issue) { create :issue, project: project }
    let(:commit_author) { create :user }
    let(:commit) { project.commit }
    let(:commit_time) { Time.now }

    before do
      project.team << [commit_author, :developer]
      project.team << [user, :developer]

      allow(commit).to receive_messages(
        safe_message: "this commit \n mentions #{issue.to_reference}",
        references: [issue],
        author_name: commit_author.name,
        author_email: commit_author.email,
        committed_date: commit_time
      )

      allow_any_instance_of(ProcessCommitWorker).to receive(:find_commit).
        and_return(commit)

      allow(project.repository).to receive(:commits_between).and_return([commit])
    end

    context "while saving the 'first_mentioned_in_commit_at' metric for an issue" do
      it 'sets the metric for referenced issues' do
        execute_service(project, user, @oldrev, @newrev, @ref)

        expect(issue.reload.metrics.first_mentioned_in_commit_at).to be_like_time(commit_time)
      end

      it 'does not set the metric for non-referenced issues' do
        non_referenced_issue = create(:issue, project: project)
        execute_service(project, user, @oldrev, @newrev, @ref)

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

      allow(project.repository).to receive(:commits_between).
        and_return([closing_commit])

      allow_any_instance_of(ProcessCommitWorker).to receive(:find_commit).
        and_return(closing_commit)

      project.team << [commit_author, :master]
    end

    context "to default branches" do
      it "closes issues" do
        execute_service(project, commit_author, @oldrev, @newrev, @ref )
        expect(Issue.find(issue.id)).to be_closed
      end

      it "adds a note indicating that the issue is now closed" do
        expect(SystemNoteService).to receive(:change_status).with(issue, project, commit_author, "closed", closing_commit)
        execute_service(project, commit_author, @oldrev, @newrev, @ref )
      end

      it "doesn't create additional cross-reference notes" do
        expect(SystemNoteService).not_to receive(:cross_reference)
        execute_service(project, commit_author, @oldrev, @newrev, @ref )
      end

      it "doesn't close issues when external issue tracker is in use" do
        allow_any_instance_of(Project).to receive(:default_issues_tracker?).
          and_return(false)
        external_issue_tracker = double(title: 'My Tracker', issue_path: issue.iid, reference_pattern: project.issue_reference_pattern)
        allow_any_instance_of(Project).to receive(:external_issue_tracker).and_return(external_issue_tracker)

        # The push still shouldn't create cross-reference notes.
        expect do
          execute_service(project, commit_author, @oldrev, @newrev,  'refs/heads/hurf' )
        end.not_to change { Note.where(project_id: project.id, system: true).count }
      end
    end

    context "to non-default branches" do
      before do
        # Make sure the "default" branch is different
        allow(project).to receive(:default_branch).and_return('not-master')
      end

      it "creates cross-reference notes" do
        expect(SystemNoteService).to receive(:cross_reference).with(issue, closing_commit, commit_author)
        execute_service(project, user, @oldrev, @newrev, @ref )
      end

      it "doesn't close issues" do
        execute_service(project, user, @oldrev, @newrev, @ref )
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

        allow(project.repository).to receive_messages(commits_between: [closing_commit])
      end

      after do
        jira_tracker.destroy!
      end

      context "mentioning an issue" do
        let(:message) { "this is some work.\n\nrelated to JIRA-1" }

        it "initiates one api call to jira server to mention the issue" do
          execute_service(project, user, @oldrev, @newrev, @ref)

          expect(WebMock).to have_requested(:post, jira_api_comment_url('JIRA-1')).with(
            body: /mentioned this issue in/
          ).once
        end
      end

      context "closing an issue" do
        let(:message)         { "this is some work.\n\ncloses JIRA-1" }
        let(:comment_body)    { { body: "Issue solved with [#{closing_commit.id}|http://localhost/#{project.path_with_namespace}/commit/#{closing_commit.id}]." }.to_json }

        context "using right markdown" do
          it "initiates one api call to jira server to close the issue" do
            execute_service(project, commit_author, @oldrev, @newrev, @ref )

            expect(WebMock).to have_requested(:post, jira_api_transition_url('JIRA-1')).once
          end

          it "initiates one api call to jira server to comment on the issue" do
            execute_service(project, commit_author, @oldrev, @newrev, @ref )

            expect(WebMock).to have_requested(:post, jira_api_comment_url('JIRA-1')).with(
              body: comment_body
            ).once
          end
        end

        context "using wrong markdown" do
          let(:message) { "this is some work.\n\ncloses #1" }

          it "does not initiates one api call to jira server to close the issue" do
            execute_service(project, commit_author, @oldrev, @newrev, @ref )

            expect(WebMock).not_to have_requested(:post, jira_api_transition_url('JIRA-1'))
          end

          it "does not initiates one api call to jira server to comment on the issue" do
            execute_service(project, commit_author, @oldrev, @newrev, @ref )

            expect(WebMock).not_to have_requested(:post, jira_api_comment_url('JIRA-1')).with(
              body: comment_body
            ).once
          end
        end
      end
    end
  end

  describe "empty project" do
    let(:project) { create(:project_empty_repo) }
    let(:new_ref) { 'refs/heads/feature'}

    before do
      allow(project).to receive(:default_branch).and_return('feature')
      expect(project).to receive(:change_head) { 'feature'}
    end

    it 'push to first branch updates HEAD' do
      execute_service(project, user, @blankrev, @newrev, new_ref )
    end
  end

  describe "housekeeping" do
    let(:housekeeping) { Projects::HousekeepingService.new(project) }

    before do
      # Flush any raw Redis data stored by the housekeeping code.
      Gitlab::Redis.with { |conn| conn.flushall }

      allow(Projects::HousekeepingService).to receive(:new).and_return(housekeeping)
    end

    after do
      Gitlab::Redis.with { |conn| conn.flushall }
    end

    it 'does not perform housekeeping when not needed' do
      expect(housekeeping).not_to receive(:execute)

      execute_service(project, user, @oldrev, @newrev, @ref)
    end

    context 'when housekeeping is needed' do
      before do
        allow(housekeeping).to receive(:needed?).and_return(true)
      end

      it 'performs housekeeping' do
        expect(housekeeping).to receive(:execute)

        execute_service(project, user, @oldrev, @newrev, @ref)
      end

      it 'does not raise an exception' do
        allow(housekeeping).to receive(:try_obtain_lease).and_return(false)

        execute_service(project, user, @oldrev, @newrev, @ref)
      end
    end

    it 'increments the push counter' do
      expect(housekeeping).to receive(:increment!)

      execute_service(project, user, @oldrev, @newrev, @ref)
    end
  end

  def execute_service(project, user, oldrev, newrev, ref)
    service = described_class.new(project, user, oldrev: oldrev, newrev: newrev, ref: ref )
    service.execute
    service
  end
end
