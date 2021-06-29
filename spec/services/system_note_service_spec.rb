# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemNoteService do
  include Gitlab::Routing
  include RepoHelpers
  include AssetsHelpers
  include DesignManagementTestHelpers

  let_it_be(:group)    { create(:group) }
  let_it_be(:project)  { create(:project, :repository, group: group) }
  let_it_be(:author)   { create(:user) }

  let(:noteable) { create(:issue, project: project) }
  let(:issue)    { noteable }

  describe '.add_commits' do
    let(:new_commits) { double }
    let(:old_commits) { double }
    let(:oldrev)      { double }

    it 'calls CommitService' do
      expect_next_instance_of(::SystemNotes::CommitService) do |service|
        expect(service).to receive(:add_commits).with(new_commits, old_commits, oldrev)
      end

      described_class.add_commits(noteable, project, author, new_commits, old_commits, oldrev)
    end
  end

  describe '.tag_commit' do
    let(:tag_name) { double }

    it 'calls CommitService' do
      expect_next_instance_of(::SystemNotes::CommitService) do |service|
        expect(service).to receive(:tag_commit).with(tag_name)
      end

      described_class.tag_commit(noteable, project, author, tag_name)
    end
  end

  describe '.change_assignee' do
    let(:assignee) { double }

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:change_assignee).with(assignee)
      end

      described_class.change_assignee(noteable, project, author, assignee)
    end
  end

  describe '.change_issuable_assignees' do
    let(:assignees) { [double, double] }

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:change_issuable_assignees).with(assignees)
      end

      described_class.change_issuable_assignees(noteable, project, author, assignees)
    end
  end

  describe '.change_issuable_reviewers' do
    let(:reviewers) { [double, double] }

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:change_issuable_reviewers).with(reviewers)
      end

      described_class.change_issuable_reviewers(noteable, project, author, reviewers)
    end
  end

  describe '.close_after_error_tracking_resolve' do
    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:close_after_error_tracking_resolve)
      end

      described_class.close_after_error_tracking_resolve(noteable, project, author)
    end
  end

  describe '.relate_issue' do
    let(:noteable_ref) { double }
    let(:noteable) { double }

    before do
      allow(noteable).to receive(:project).and_return(double)
    end

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:relate_issue).with(noteable_ref)
      end

      described_class.relate_issue(noteable, noteable_ref, double)
    end
  end

  describe '.unrelate_issue' do
    let(:noteable_ref) { double }
    let(:noteable) { double }

    before do
      allow(noteable).to receive(:project).and_return(double)
    end

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:unrelate_issue).with(noteable_ref)
      end

      described_class.unrelate_issue(noteable, noteable_ref, double)
    end
  end

  describe '.change_due_date' do
    let(:due_date) { double }

    it 'calls TimeTrackingService' do
      expect_next_instance_of(::SystemNotes::TimeTrackingService) do |service|
        expect(service).to receive(:change_due_date).with(due_date)
      end

      described_class.change_due_date(noteable, project, author, due_date)
    end
  end

  describe '.change_status' do
    let(:status) { double }
    let(:source) { double }

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:change_status).with(status, source)
      end

      described_class.change_status(noteable, project, author, status, source)
    end
  end

  describe '.merge_when_pipeline_succeeds' do
    it 'calls MergeRequestsService' do
      sha = double

      expect_next_instance_of(::SystemNotes::MergeRequestsService) do |service|
        expect(service).to receive(:merge_when_pipeline_succeeds).with(sha)
      end

      described_class.merge_when_pipeline_succeeds(noteable, project, author, sha)
    end
  end

  describe '.cancel_merge_when_pipeline_succeeds' do
    it 'calls MergeRequestsService' do
      expect_next_instance_of(::SystemNotes::MergeRequestsService) do |service|
        expect(service).to receive(:cancel_merge_when_pipeline_succeeds)
      end

      described_class.cancel_merge_when_pipeline_succeeds(noteable, project, author)
    end
  end

  describe '.abort_merge_when_pipeline_succeeds' do
    it 'calls MergeRequestsService' do
      reason = double

      expect_next_instance_of(::SystemNotes::MergeRequestsService) do |service|
        expect(service).to receive(:abort_merge_when_pipeline_succeeds).with(reason)
      end

      described_class.abort_merge_when_pipeline_succeeds(noteable, project, author, reason)
    end
  end

  describe '.change_title' do
    let(:title) { double }

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:change_title).with(title)
      end

      described_class.change_title(noteable, project, author, title)
    end
  end

  describe '.change_description' do
    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:change_description)
      end

      described_class.change_description(noteable, project, author)
    end
  end

  describe '.change_issue_confidentiality' do
    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:change_issue_confidentiality)
      end

      described_class.change_issue_confidentiality(noteable, project, author)
    end
  end

  describe '.change_branch' do
    it 'calls MergeRequestsService' do
      old_branch = double('old_branch')
      new_branch = double('new_branch')
      branch_type = double('branch_type')
      event_type = double('event_type')

      expect_next_instance_of(::SystemNotes::MergeRequestsService) do |service|
        expect(service).to receive(:change_branch).with(branch_type, event_type, old_branch, new_branch)
      end

      described_class.change_branch(noteable, project, author, branch_type, event_type, old_branch, new_branch)
    end
  end

  describe '.change_branch_presence' do
    it 'calls MergeRequestsService' do
      presence = double
      branch = double
      branch_type = double

      expect_next_instance_of(::SystemNotes::MergeRequestsService) do |service|
        expect(service).to receive(:change_branch_presence).with(branch_type, branch, presence)
      end

      described_class.change_branch_presence(noteable, project, author, branch_type, branch, presence)
    end
  end

  describe '.new_issue_branch' do
    it 'calls MergeRequestsService' do
      branch = double
      branch_project = double

      expect_next_instance_of(::SystemNotes::MergeRequestsService) do |service|
        expect(service).to receive(:new_issue_branch).with(branch, branch_project: branch_project)
      end

      described_class.new_issue_branch(noteable, project, author, branch, branch_project: branch_project)
    end
  end

  describe '.new_merge_request' do
    it 'calls MergeRequestsService' do
      merge_request = double

      expect_next_instance_of(::SystemNotes::MergeRequestsService) do |service|
        expect(service).to receive(:new_merge_request).with(merge_request)
      end

      described_class.new_merge_request(noteable, project, author, merge_request)
    end
  end

  describe '.zoom_link_added' do
    it 'calls ZoomService' do
      expect_next_instance_of(::SystemNotes::ZoomService) do |service|
        expect(service).to receive(:zoom_link_added)
      end

      described_class.zoom_link_added(noteable, project, author)
    end
  end

  describe '.zoom_link_removed' do
    it 'calls ZoomService' do
      expect_next_instance_of(::SystemNotes::ZoomService) do |service|
        expect(service).to receive(:zoom_link_removed)
      end

      described_class.zoom_link_removed(noteable, project, author)
    end
  end

  describe '.cross_reference' do
    let(:mentioner) { double }

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:cross_reference).with(mentioner)
      end

      described_class.cross_reference(double, mentioner, double)
    end
  end

  describe '.cross_reference_disallowed?' do
    let(:mentioner) { double }

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:cross_reference_disallowed?).with(mentioner)
      end

      described_class.cross_reference_disallowed?(double, mentioner)
    end
  end

  describe '.cross_reference_exists?' do
    let(:mentioner) { double }

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:cross_reference_exists?).with(mentioner)
      end

      described_class.cross_reference_exists?(double, mentioner)
    end
  end

  describe '.noteable_moved' do
    let(:noteable_ref) { double }
    let(:direction) { double }

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:noteable_moved).with(noteable_ref, direction)
      end

      described_class.noteable_moved(double, double, noteable_ref, double, direction: direction)
    end
  end

  describe '.noteable_cloned' do
    let(:noteable_ref) { double }
    let(:direction) { double }

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:noteable_cloned).with(noteable_ref, direction)
      end

      described_class.noteable_cloned(double, double, noteable_ref, double, direction: direction)
    end
  end

  describe 'Jira integration' do
    include JiraServiceHelper

    let(:project)         { create(:jira_project, :repository) }
    let(:author)          { create(:user) }
    let(:issue)           { create(:issue, project: project) }
    let(:merge_request)   { create(:merge_request, :simple, target_project: project, source_project: project) }
    let(:jira_issue)      { ExternalIssue.new("JIRA-1", project)}
    let(:jira_tracker)    { project.jira_integration }
    let(:commit)          { project.commit }
    let(:comment_url)     { jira_api_comment_url(jira_issue.id) }
    let(:success_message) { "SUCCESS: Successfully posted to http://jira.example.net." }

    before do
      stub_jira_integration_test
      stub_jira_urls(jira_issue.id)
      jira_integration_settings
    end

    def cross_reference(type, link_exists = false)
      noteable = type == 'commit' ? commit : merge_request

      links = []
      if link_exists
        url = if type == 'commit'
                "#{Settings.gitlab.base_url}/#{project.namespace.path}/#{project.path}/-/commit/#{commit.id}"
              else
                "#{Settings.gitlab.base_url}/#{project.namespace.path}/#{project.path}/-/merge_requests/#{merge_request.iid}"
              end

        link = double(object: { 'url' => url })
        links << link
        expect(link).to receive(:save!)
      end

      allow(JIRA::Resource::Remotelink).to receive(:all).and_return(links)

      described_class.cross_reference(jira_issue, noteable, author)
    end

    noteable_types = %w(merge_requests commit)

    noteable_types.each do |type|
      context "when noteable is a #{type}" do
        it "blocks cross reference when #{type.underscore}_events is false" do
          jira_tracker.update!("#{type}_events" => false)

          expect(cross_reference(type)).to eq(s_('JiraService|Events for %{noteable_model_name} are disabled.') % { noteable_model_name: type.pluralize.humanize.downcase })
        end

        it "creates cross reference when #{type.underscore}_events is true" do
          jira_tracker.update!("#{type}_events" => true)

          expect(cross_reference(type)).to eq(success_message)
        end
      end

      context 'when a new cross reference is created' do
        it 'creates a new comment and remote link' do
          cross_reference(type)

          expect(WebMock).to have_requested(:post, jira_api_comment_url(jira_issue))
          expect(WebMock).to have_requested(:post, jira_api_remote_link_url(jira_issue))
        end
      end

      context 'when a link exists' do
        it 'updates a link but does not create a new comment' do
          expect(WebMock).not_to have_requested(:post, jira_api_comment_url(jira_issue))

          cross_reference(type, true)
        end
      end
    end

    describe "new reference" do
      let(:favicon_path) { "http://localhost/assets/#{find_asset('favicon.png').digest_path}" }

      before do
        allow(JIRA::Resource::Remotelink).to receive(:all).and_return([])
      end

      context 'for commits' do
        it "creates comment" do
          result = described_class.cross_reference(jira_issue, commit, author)

          expect(result).to eq(success_message)
        end

        it "creates remote link" do
          described_class.cross_reference(jira_issue, commit, author)

          expect(WebMock).to have_requested(:post, jira_api_remote_link_url(jira_issue)).with(
            body: hash_including(
              GlobalID: "GitLab",
              relationship: 'mentioned on',
              object: {
                url: project_commit_url(project, commit),
                title: "Commit - #{commit.title}",
                icon: { title: "GitLab", url16x16: favicon_path },
                status: { resolved: false }
              }
            )
          ).once
        end
      end

      context 'for issues' do
        let(:issue) { create(:issue, project: project) }

        it "creates comment" do
          result = described_class.cross_reference(jira_issue, issue, author)

          expect(result).to eq(success_message)
        end

        it "creates remote link" do
          described_class.cross_reference(jira_issue, issue, author)

          expect(WebMock).to have_requested(:post, jira_api_remote_link_url(jira_issue)).with(
            body: hash_including(
              GlobalID: "GitLab",
              relationship: 'mentioned on',
              object: {
                url: project_issue_url(project, issue),
                title: "Issue - #{issue.title}",
                icon: { title: "GitLab", url16x16: favicon_path },
                status: { resolved: false }
              }
            )
          ).once
        end
      end

      context 'for snippets' do
        let(:snippet) { create(:snippet, project: project) }

        it "creates comment" do
          result = described_class.cross_reference(jira_issue, snippet, author)

          expect(result).to eq(success_message)
        end

        it "creates remote link" do
          described_class.cross_reference(jira_issue, snippet, author)

          expect(WebMock).to have_requested(:post, jira_api_remote_link_url(jira_issue)).with(
            body: hash_including(
              GlobalID: "GitLab",
              relationship: 'mentioned on',
              object: {
                url: project_snippet_url(project, snippet),
                title: "Snippet - #{snippet.title}",
                icon: { title: "GitLab", url16x16: favicon_path },
                status: { resolved: false }
              }
            )
          ).once
        end
      end
    end

    describe "existing reference" do
      before do
        allow(JIRA::Resource::Remotelink).to receive(:all).and_return([])
        message = double('message')
        allow(message).to receive(:include?) { true }
        allow_next_instance_of(JIRA::Resource::Issue) do |instance|
          allow(instance).to receive(:comments).and_return([OpenStruct.new(body: message)])
        end
      end

      it "does not return success message" do
        result = described_class.cross_reference(jira_issue, commit, author)

        expect(result).not_to eq(success_message)
      end

      it 'does not try to create comment and remote link' do
        subject

        expect(WebMock).not_to have_requested(:post, jira_api_comment_url(jira_issue))
        expect(WebMock).not_to have_requested(:post, jira_api_remote_link_url(jira_issue))
      end
    end
  end

  describe '.change_time_estimate' do
    it 'calls TimeTrackingService' do
      expect_next_instance_of(::SystemNotes::TimeTrackingService) do |service|
        expect(service).to receive(:change_time_estimate)
      end

      described_class.change_time_estimate(noteable, project, author)
    end
  end

  describe '.discussion_continued_in_issue' do
    let(:discussion) { create(:diff_note_on_merge_request, project: project).to_discussion }
    let(:merge_request) { discussion.noteable }
    let(:issue) { create(:issue, project: project) }

    def reloaded_merge_request
      MergeRequest.find(merge_request.id)
    end

    subject { described_class.discussion_continued_in_issue(discussion, project, author, issue) }

    it_behaves_like 'a system note' do
      let(:expected_noteable) { discussion.first_note.noteable }
      let(:action)              { 'discussion' }
    end

    it 'creates a new note in the discussion' do
      # we need to completely rebuild the merge request object, or the `@discussions` on the merge request are not reloaded.
      expect { subject }.to change { reloaded_merge_request.discussions.first.notes.size }.by(1)
    end

    it 'mentions the created issue in the system note' do
      expect(subject.note).to include(issue.to_reference)
    end
  end

  describe '.change_time_spent' do
    it 'calls TimeTrackingService' do
      expect_next_instance_of(::SystemNotes::TimeTrackingService) do |service|
        expect(service).to receive(:change_time_spent)
      end

      described_class.change_time_spent(noteable, project, author)
    end
  end

  describe '.handle_merge_request_draft' do
    it 'calls MergeRequestsService' do
      expect_next_instance_of(::SystemNotes::MergeRequestsService) do |service|
        expect(service).to receive(:handle_merge_request_draft)
      end

      described_class.handle_merge_request_draft(noteable, project, author)
    end
  end

  describe '.add_merge_request_draft_from_commit' do
    it 'calls MergeRequestsService' do
      commit = double

      expect_next_instance_of(::SystemNotes::MergeRequestsService) do |service|
        expect(service).to receive(:add_merge_request_draft_from_commit).with(commit)
      end

      described_class.add_merge_request_draft_from_commit(noteable, project, author, commit)
    end
  end

  describe '.change_task_status' do
    let(:new_task) { double }

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:change_task_status).with(new_task)
      end

      described_class.change_task_status(noteable, project, author, new_task)
    end
  end

  describe '.resolve_all_discussions' do
    it 'calls MergeRequestsService' do
      expect_next_instance_of(::SystemNotes::MergeRequestsService) do |service|
        expect(service).to receive(:resolve_all_discussions)
      end

      described_class.resolve_all_discussions(noteable, project, author)
    end
  end

  describe '.diff_discussion_outdated' do
    it 'calls MergeRequestsService' do
      discussion = double
      change_position = double

      expect_next_instance_of(::SystemNotes::MergeRequestsService) do |service|
        expect(service).to receive(:diff_discussion_outdated).with(discussion, change_position)
      end

      described_class.diff_discussion_outdated(discussion, project, author, change_position)
    end
  end

  describe '.mark_duplicate_issue' do
    let(:canonical_issue) { double }

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:mark_duplicate_issue).with(canonical_issue)
      end

      described_class.mark_duplicate_issue(noteable, project, author, canonical_issue)
    end
  end

  describe '.mark_canonical_issue_of_duplicate' do
    let(:duplicate_issue) { double }

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:mark_canonical_issue_of_duplicate).with(duplicate_issue)
      end

      described_class.mark_canonical_issue_of_duplicate(noteable, project, author, duplicate_issue)
    end
  end

  describe '.discussion_lock' do
    let(:issuable) { double }

    before do
      allow(issuable).to receive(:project).and_return(double)
    end

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:discussion_lock)
      end

      described_class.discussion_lock(issuable, double)
    end
  end

  describe '.auto_resolve_prometheus_alert' do
    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:auto_resolve_prometheus_alert)
      end

      described_class.auto_resolve_prometheus_alert(noteable, project, author)
    end
  end

  describe '.design_version_added' do
    let(:version) { create(:design_version) }

    it 'calls DesignManagementService' do
      expect_next_instance_of(SystemNotes::DesignManagementService) do |service|
        expect(service).to receive(:design_version_added).with(version)
      end

      described_class.design_version_added(version)
    end
  end

  describe '.design_discussion_added' do
    let(:discussion_note) { create(:diff_note_on_design) }

    it 'calls DesignManagementService' do
      expect_next_instance_of(SystemNotes::DesignManagementService) do |service|
        expect(service).to receive(:design_discussion_added).with(discussion_note)
      end

      described_class.design_discussion_added(discussion_note)
    end
  end

  describe '.approve_mr' do
    it 'calls MergeRequestsService' do
      expect_next_instance_of(::SystemNotes::MergeRequestsService) do |service|
        expect(service).to receive(:approve_mr)
      end

      described_class.approve_mr(noteable, author)
    end
  end

  describe '.unapprove_mr' do
    it 'calls MergeRequestsService' do
      expect_next_instance_of(::SystemNotes::MergeRequestsService) do |service|
        expect(service).to receive(:unapprove_mr)
      end

      described_class.unapprove_mr(noteable, author)
    end
  end

  describe '.change_alert_status' do
    let(:alert) { build(:alert_management_alert) }

    it 'calls AlertManagementService' do
      expect_next_instance_of(SystemNotes::AlertManagementService) do |service|
        expect(service).to receive(:change_alert_status).with(alert)
      end

      described_class.change_alert_status(alert, author)
    end
  end

  describe '.new_alert_issue' do
    let(:alert) { build(:alert_management_alert, :with_issue) }

    it 'calls AlertManagementService' do
      expect_next_instance_of(SystemNotes::AlertManagementService) do |service|
        expect(service).to receive(:new_alert_issue).with(alert.issue)
      end

      described_class.new_alert_issue(alert, alert.issue, author)
    end
  end

  describe '.create_new_alert' do
    let(:alert) { build(:alert_management_alert) }
    let(:monitoring_tool) { 'Prometheus' }

    it 'calls AlertManagementService' do
      expect_next_instance_of(SystemNotes::AlertManagementService) do |service|
        expect(service).to receive(:create_new_alert).with(monitoring_tool)
      end

      described_class.create_new_alert(alert, monitoring_tool)
    end
  end

  describe '.change_incident_severity' do
    let(:incident) { build(:incident) }

    it 'calls IncidentService' do
      expect_next_instance_of(SystemNotes::IncidentService) do |service|
        expect(service).to receive(:change_incident_severity)
      end

      described_class.change_incident_severity(incident, author)
    end
  end

  describe '.log_resolving_alert' do
    let(:alert) { build(:alert_management_alert) }
    let(:monitoring_tool) { 'Prometheus' }

    it 'calls AlertManagementService' do
      expect_next_instance_of(SystemNotes::AlertManagementService) do |service|
        expect(service).to receive(:log_resolving_alert).with(monitoring_tool)
      end

      described_class.log_resolving_alert(alert, monitoring_tool)
    end
  end
end
