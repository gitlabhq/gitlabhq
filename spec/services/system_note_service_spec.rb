# frozen_string_literal: true

require 'spec_helper'

describe SystemNoteService do
  include Gitlab::Routing
  include RepoHelpers
  include AssetsHelpers

  set(:group)    { create(:group) }
  set(:project)  { create(:project, :repository, group: group) }
  set(:author)   { create(:user) }
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

  describe '.change_milestone' do
    let(:milestone) { double }

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:change_milestone).with(milestone)
      end

      described_class.change_milestone(noteable, project, author, milestone)
    end
  end

  describe '.change_due_date' do
    subject { described_class.change_due_date(noteable, project, author, due_date) }

    let(:due_date) { Date.today }

    it_behaves_like 'a note with overridable created_at'

    it_behaves_like 'a system note' do
      let(:action) { 'due_date' }
    end

    context 'when due date added' do
      it 'sets the note text' do
        expect(subject.note).to eq "changed due date to #{Date.today.to_s(:long)}"
      end
    end

    context 'when due date removed' do
      let(:due_date) { nil }

      it 'sets the note text' do
        expect(subject.note).to eq 'removed due date'
      end
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
    let(:pipeline) { build(:ci_pipeline_without_jobs )}
    let(:noteable) do
      create(:merge_request, source_project: project, target_project: project)
    end

    subject { described_class.merge_when_pipeline_succeeds(noteable, project, author, pipeline.sha) }

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it "posts the 'merge when pipeline succeeds' system note" do
      expect(subject.note).to match(%r{enabled an automatic merge when the pipeline for (\w+/\w+@)?\h{40} succeeds})
    end
  end

  describe '.cancel_merge_when_pipeline_succeeds' do
    let(:noteable) do
      create(:merge_request, source_project: project, target_project: project)
    end

    subject { described_class.cancel_merge_when_pipeline_succeeds(noteable, project, author) }

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it "posts the 'merge when pipeline succeeds' system note" do
      expect(subject.note).to eq "canceled the automatic merge"
    end
  end

  describe '.abort_merge_when_pipeline_succeeds' do
    let(:noteable) do
      create(:merge_request, source_project: project, target_project: project)
    end

    subject { described_class.abort_merge_when_pipeline_succeeds(noteable, project, author, 'merge request was closed') }

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it "posts the 'merge when pipeline succeeds' system note" do
      expect(subject.note).to eq "aborted the automatic merge because merge request was closed"
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
    subject { described_class.change_branch(noteable, project, author, 'target', old_branch, new_branch) }

    let(:old_branch) { 'old_branch'}
    let(:new_branch) { 'new_branch'}

    it_behaves_like 'a system note' do
      let(:action) { 'branch' }
    end

    context 'when target branch name changed' do
      it 'sets the note text' do
        expect(subject.note).to eq "changed target branch from `#{old_branch}` to `#{new_branch}`"
      end
    end
  end

  describe '.change_branch_presence' do
    subject { described_class.change_branch_presence(noteable, project, author, :source, 'feature', :delete) }

    it_behaves_like 'a system note' do
      let(:action) { 'branch' }
    end

    context 'when source branch deleted' do
      it 'sets the note text' do
        expect(subject.note).to eq "deleted source branch `feature`"
      end
    end
  end

  describe '.new_issue_branch' do
    let(:branch) { '1-mepmep' }

    subject { described_class.new_issue_branch(noteable, project, author, branch, branch_project: branch_project) }

    shared_examples_for 'a system note for new issue branch' do
      it_behaves_like 'a system note' do
        let(:action) { 'branch' }
      end

      context 'when a branch is created from the new branch button' do
        it 'sets the note text' do
          expect(subject.note).to start_with("created branch [`#{branch}`]")
        end
      end
    end

    context 'branch_project is set' do
      let(:branch_project) { create(:project, :repository) }

      it_behaves_like 'a system note for new issue branch'
    end

    context 'branch_project is not set' do
      let(:branch_project) { nil }

      it_behaves_like 'a system note for new issue branch'
    end
  end

  describe '.new_merge_request' do
    subject { described_class.new_merge_request(noteable, project, author, merge_request) }

    let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it 'sets the new merge request note text' do
      expect(subject.note).to eq("created merge request #{merge_request.to_reference(project)} to address this issue")
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

  describe 'Jira integration' do
    include JiraServiceHelper

    let(:project)         { create(:jira_project, :repository) }
    let(:author)          { create(:user) }
    let(:issue)           { create(:issue, project: project) }
    let(:merge_request)   { create(:merge_request, :simple, target_project: project, source_project: project) }
    let(:jira_issue)      { ExternalIssue.new("JIRA-1", project)}
    let(:jira_tracker)    { project.jira_service }
    let(:commit)          { project.commit }
    let(:comment_url)     { jira_api_comment_url(jira_issue.id) }
    let(:success_message) { "SUCCESS: Successfully posted to http://jira.example.net." }

    before do
      stub_jira_urls(jira_issue.id)
      jira_service_settings
    end

    def cross_reference(type, link_exists = false)
      noteable = type == 'commit' ? commit : merge_request

      links = []
      if link_exists
        url = if type == 'commit'
                "#{Settings.gitlab.base_url}/#{project.namespace.path}/#{project.path}/commit/#{commit.id}"
              else
                "#{Settings.gitlab.base_url}/#{project.namespace.path}/#{project.path}/merge_requests/#{merge_request.iid}"
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
          jira_tracker.update("#{type}_events" => false)

          expect(cross_reference(type)).to eq("Events for #{type.pluralize.humanize.downcase} are disabled.")
        end

        it "creates cross reference when #{type.underscore}_events is true" do
          jira_tracker.update("#{type}_events" => true)

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
        message = "[#{author.name}|http://localhost/#{author.username}] mentioned this issue in [a commit of #{project.full_path}|http://localhost/#{project.full_path}/commit/#{commit.id}]:\n'#{commit.title.chomp}'"
        allow_any_instance_of(JIRA::Resource::Issue).to receive(:comments).and_return([OpenStruct.new(body: message)])
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
    subject { described_class.change_time_estimate(noteable, project, author) }

    it_behaves_like 'a system note' do
      let(:action) { 'time_tracking' }
    end

    context 'with a time estimate' do
      it 'sets the note text' do
        noteable.update_attribute(:time_estimate, 277200)

        expect(subject.note).to eq "changed time estimate to 1w 4d 5h"
      end

      context 'when time_tracking_limit_to_hours setting is true' do
        before do
          stub_application_setting(time_tracking_limit_to_hours: true)
        end

        it 'sets the note text' do
          noteable.update_attribute(:time_estimate, 277200)

          expect(subject.note).to eq "changed time estimate to 77h"
        end
      end
    end

    context 'without a time estimate' do
      it 'sets the note text' do
        expect(subject.note).to eq "removed time estimate"
      end
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
    # We need a custom noteable in order to the shared examples to be green.
    let(:noteable) do
      mr = create(:merge_request, source_project: project)
      mr.spend_time(duration: 360000, user_id: author.id)
      mr.save!
      mr
    end

    subject do
      described_class.change_time_spent(noteable, project, author)
    end

    it_behaves_like 'a system note' do
      let(:action) { 'time_tracking' }
    end

    context 'when time was added' do
      it 'sets the note text' do
        spend_time!(277200)

        expect(subject.note).to eq "added 1w 4d 5h of time spent"
      end
    end

    context 'when time was subtracted' do
      it 'sets the note text' do
        spend_time!(-277200)

        expect(subject.note).to eq "subtracted 1w 4d 5h of time spent"
      end
    end

    context 'when time was removed' do
      it 'sets the note text' do
        spend_time!(:reset)

        expect(subject.note).to eq "removed time spent"
      end
    end

    context 'when time_tracking_limit_to_hours setting is true' do
      before do
        stub_application_setting(time_tracking_limit_to_hours: true)
      end

      it 'sets the note text' do
        spend_time!(277200)

        expect(subject.note).to eq "added 77h of time spent"
      end
    end

    def spend_time!(seconds)
      noteable.spend_time(duration: seconds, user_id: author.id)
      noteable.save!
    end
  end

  describe '.handle_merge_request_wip' do
    context 'adding wip note' do
      let(:noteable) { create(:merge_request, source_project: project, title: 'WIP Lorem ipsum') }

      subject { described_class.handle_merge_request_wip(noteable, project, author) }

      it_behaves_like 'a system note' do
        let(:action) { 'title' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq 'marked as a **Work In Progress**'
      end
    end

    context 'removing wip note' do
      let(:noteable) { create(:merge_request, source_project: project, title: 'Lorem ipsum') }

      subject { described_class.handle_merge_request_wip(noteable, project, author) }

      it_behaves_like 'a system note' do
        let(:action) { 'title' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq 'unmarked as a **Work In Progress**'
      end
    end
  end

  describe '.add_merge_request_wip_from_commit' do
    let(:noteable) do
      create(:merge_request, source_project: project, target_project: project)
    end

    subject do
      described_class.add_merge_request_wip_from_commit(
        noteable,
        project,
        author,
        noteable.diff_head_commit
      )
    end

    it_behaves_like 'a system note' do
      let(:action) { 'title' }
    end

    it "posts the 'marked as a Work In Progress from commit' system note" do
      expect(subject.note).to match(
        /marked as a \*\*Work In Progress\*\* from #{Commit.reference_pattern}/
      )
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
    let(:noteable) { create(:merge_request, source_project: project, target_project: project) }

    subject { described_class.resolve_all_discussions(noteable, project, author) }

    it_behaves_like 'a system note' do
      let(:action) { 'discussion' }
    end

    it 'sets the note text' do
      expect(subject.note).to eq 'resolved all threads'
    end
  end

  describe '.diff_discussion_outdated' do
    let(:discussion) { create(:diff_note_on_merge_request, project: project).to_discussion }
    let(:merge_request) { discussion.noteable }
    let(:change_position) { discussion.position }

    def reloaded_merge_request
      MergeRequest.find(merge_request.id)
    end

    subject { described_class.diff_discussion_outdated(discussion, project, author, change_position) }

    it_behaves_like 'a system note' do
      let(:expected_noteable) { discussion.first_note.noteable }
      let(:action)            { 'outdated' }
    end

    context 'when the change_position is valid for the discussion' do
      it 'creates a new note in the discussion' do
        # we need to completely rebuild the merge request object, or the `@discussions` on the merge request are not reloaded.
        expect { subject }.to change { reloaded_merge_request.discussions.first.notes.size }.by(1)
      end

      it 'links to the diff in the system note' do
        diff_id = merge_request.merge_request_diff.id
        line_code = change_position.line_code(project.repository)
        link = diffs_project_merge_request_path(project, merge_request, diff_id: diff_id, anchor: line_code)

        expect(subject.note).to eq("changed this line in [version 1 of the diff](#{link})")
      end

      context 'discussion is on an image' do
        let(:discussion) { create(:image_diff_note_on_merge_request, project: project).to_discussion }

        it 'links to the diff in the system note' do
          diff_id = merge_request.merge_request_diff.id
          file_hash = change_position.file_hash
          link = diffs_project_merge_request_path(project, merge_request, diff_id: diff_id, anchor: file_hash)

          expect(subject.note).to eq("changed this file in [version 1 of the diff](#{link})")
        end
      end
    end

    context 'when the change_position does not point to a valid version' do
      before do
        allow(merge_request).to receive(:version_params_for).and_return(nil)
      end

      it 'creates a new note in the discussion' do
        # we need to completely rebuild the merge request object, or the `@discussions` on the merge request are not reloaded.
        expect { subject }.to change { reloaded_merge_request.discussions.first.notes.size }.by(1)
      end

      it 'does not create a link' do
        expect(subject.note).to eq('changed this line in version 1 of the diff')
      end
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
end
