require 'spec_helper'

describe SystemNoteService, services: true do
  include Gitlab::Routing.url_helpers

  let(:project)  { create(:project) }
  let(:author)   { create(:user) }
  let(:noteable) { create(:issue, project: project) }

  shared_examples_for 'a system note' do
    it 'is valid' do
      expect(subject).to be_valid
    end

    it 'sets the noteable model' do
      expect(subject.noteable).to eq noteable
    end

    it 'sets the project' do
      expect(subject.project).to eq project
    end

    it 'sets the author' do
      expect(subject.author).to eq author
    end

    it 'is a system note' do
      expect(subject).to be_system
    end
  end

  describe '.add_commits' do
    subject { described_class.add_commits(noteable, project, author, new_commits, old_commits, oldrev) }

    let(:noteable)    { create(:merge_request, source_project: project) }
    let(:new_commits) { noteable.commits }
    let(:old_commits) { [] }
    let(:oldrev)      { nil }

    it_behaves_like 'a system note'

    describe 'note body' do
      let(:note_lines) { subject.note.split("\n").reject(&:blank?) }

      describe 'comparison diff link line' do
        it 'adds the comparison text' do
          expect(note_lines[2]).to match "[Compare with previous version]"
        end
      end

      context 'without existing commits' do
        it 'adds a message header' do
          expect(note_lines[0]).to eq "added #{new_commits.size} commits"
        end

        it 'adds a message line for each commit' do
          new_commits.each_with_index do |commit, i|
            # Skip the header
            expect(HTMLEntities.new.decode(note_lines[i + 1])).to eq "* #{commit.short_id} - #{commit.title}"
          end
        end
      end

      describe 'summary line for existing commits' do
        let(:summary_line) { note_lines[1] }

        context 'with one existing commit' do
          let(:old_commits) { [noteable.commits.last] }

          it 'includes the existing commit' do
            expect(summary_line).to eq "* #{old_commits.first.short_id} - 1 commit from branch `feature`"
          end
        end

        context 'with multiple existing commits' do
          let(:old_commits) { noteable.commits[3..-1] }

          context 'with oldrev' do
            let(:oldrev) { noteable.commits[2].id }

            it 'includes a commit range' do
              expect(summary_line).to start_with "* #{Commit.truncate_sha(oldrev)}...#{old_commits.last.short_id}"
            end

            it 'includes a commit count' do
              expect(summary_line).to end_with " - 26 commits from branch `feature`"
            end
          end

          context 'without oldrev' do
            it 'includes a commit range' do
              expect(summary_line).to start_with "* #{old_commits[0].short_id}..#{old_commits[-1].short_id}"
            end

            it 'includes a commit count' do
              expect(summary_line).to end_with " - 26 commits from branch `feature`"
            end
          end

          context 'on a fork' do
            before do
              expect(noteable).to receive(:for_fork?).and_return(true)
            end

            it 'includes the project namespace' do
              expect(summary_line).to end_with "`#{noteable.target_project_namespace}:feature`"
            end
          end
        end
      end
    end
  end

  describe '.change_assignee' do
    subject { described_class.change_assignee(noteable, project, author, assignee) }

    let(:assignee) { create(:user) }

    it_behaves_like 'a system note'

    context 'when assignee added' do
      it 'sets the note text' do
        expect(subject.note).to eq "assigned to @#{assignee.username}"
      end
    end

    context 'when assignee removed' do
      let(:assignee) { nil }

      it 'sets the note text' do
        expect(subject.note).to eq 'removed assignee'
      end
    end
  end

  describe '.change_label' do
    subject { described_class.change_label(noteable, project, author, added, removed) }

    let(:labels)  { create_list(:label, 2) }
    let(:added)   { [] }
    let(:removed) { [] }

    it_behaves_like 'a system note'

    context 'with added labels' do
      let(:added)   { labels }
      let(:removed) { [] }

      it 'sets the note text' do
        expect(subject.note).to eq "added ~#{labels[0].id} ~#{labels[1].id} labels"
      end
    end

    context 'with removed labels' do
      let(:added)   { [] }
      let(:removed) { labels }

      it 'sets the note text' do
        expect(subject.note).to eq "removed ~#{labels[0].id} ~#{labels[1].id} labels"
      end
    end

    context 'with added and removed labels' do
      let(:added)   { [labels[0]] }
      let(:removed) { [labels[1]] }

      it 'sets the note text' do
        expect(subject.note).to eq "added ~#{labels[0].id} and removed ~#{labels[1].id} labels"
      end
    end
  end

  describe '.change_milestone' do
    subject { described_class.change_milestone(noteable, project, author, milestone) }

    let(:milestone) { create(:milestone, project: project) }

    it_behaves_like 'a system note'

    context 'when milestone added' do
      it 'sets the note text' do
        expect(subject.note).to eq "changed milestone to #{milestone.to_reference}"
      end
    end

    context 'when milestone removed' do
      let(:milestone) { nil }

      it 'sets the note text' do
        expect(subject.note).to eq 'removed milestone'
      end
    end
  end

  describe '.change_status' do
    subject { described_class.change_status(noteable, project, author, status, source) }

    let(:status) { 'new_status' }
    let(:source) { nil }

    it_behaves_like 'a system note'

    context 'with a source' do
      let(:source) { double('commit', gfm_reference: 'commit 123456') }

      it 'sets the note text' do
        expect(subject.note).to eq "#{status} via commit 123456"
      end
    end

    context 'without a source' do
      it 'sets the note text' do
        expect(subject.note).to eq status
      end
    end
  end

  describe '.merge_when_build_succeeds' do
    let(:pipeline) { build(:ci_pipeline_without_jobs )}
    let(:noteable) do
      create(:merge_request, source_project: project, target_project: project)
    end

    subject { described_class.merge_when_build_succeeds(noteable, project, author, noteable.diff_head_commit) }

    it_behaves_like 'a system note'

    it "posts the Merge When Build Succeeds system note" do
      expect(subject.note).to match  /enabled an automatic merge when the build for (\w+\/\w+@)?\h{40} succeeds/
    end
  end

  describe '.cancel_merge_when_build_succeeds' do
    let(:noteable) do
      create(:merge_request, source_project: project, target_project: project)
    end

    subject { described_class.cancel_merge_when_build_succeeds(noteable, project, author) }

    it_behaves_like 'a system note'

    it "posts the Merge When Build Succeeds system note" do
      expect(subject.note).to eq  "canceled the automatic merge"
    end
  end

  describe '.change_title' do
    subject { described_class.change_title(noteable, project, author, 'Old title') }

    context 'when noteable responds to `title`' do
      it_behaves_like 'a system note'

      it 'sets the note text' do
        expect(subject.note).
          to eq "changed title from **{-Old title-}** to **{+#{noteable.title}+}**"
      end
    end
  end

  describe '.change_issue_confidentiality' do
    subject { described_class.change_issue_confidentiality(noteable, project, author) }

    context 'when noteable responds to `confidential`' do
      it_behaves_like 'a system note'

      it 'sets the note text' do
        expect(subject.note).to eq 'made the issue visible to everyone'
      end
    end
  end

  describe '.change_branch' do
    subject { described_class.change_branch(noteable, project, author, 'target', old_branch, new_branch) }
    let(:old_branch) { 'old_branch'}
    let(:new_branch) { 'new_branch'}

    it_behaves_like 'a system note'

    context 'when target branch name changed' do
      it 'sets the note text' do
        expect(subject.note).to eq "changed target branch from `#{old_branch}` to `#{new_branch}`"
      end
    end
  end

  describe '.change_branch_presence' do
    subject { described_class.change_branch_presence(noteable, project, author, :source, 'feature', :delete) }

    it_behaves_like 'a system note'

    context 'when source branch deleted' do
      it 'sets the note text' do
        expect(subject.note).to eq "deleted source branch `feature`"
      end
    end
  end

  describe '.new_issue_branch' do
    subject { described_class.new_issue_branch(noteable, project, author, "1-mepmep") }

    it_behaves_like 'a system note'

    context 'when a branch is created from the new branch button' do
      it 'sets the note text' do
        expect(subject.note).to match /\Acreated branch [`1-mepmep`]/
      end
    end
  end

  describe '.cross_reference' do
    subject { described_class.cross_reference(noteable, mentioner, author) }

    let(:mentioner) { create(:issue, project: project) }

    it_behaves_like 'a system note'

    context 'when cross-reference disallowed' do
      before do
        expect(described_class).to receive(:cross_reference_disallowed?).and_return(true)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when cross-reference allowed' do
      before do
        expect(described_class).to receive(:cross_reference_disallowed?).and_return(false)
      end

      describe 'note_body' do
        context 'cross-project' do
          let(:project2)  { create(:project) }
          let(:mentioner) { create(:issue, project: project2) }

          context 'from Commit' do
            let(:mentioner) { project2.repository.commit }

            it 'references the mentioning commit' do
              expect(subject.note).to eq "mentioned in commit #{mentioner.to_reference(project)}"
            end
          end

          context 'from non-Commit' do
            it 'references the mentioning object' do
              expect(subject.note).to eq "mentioned in issue #{mentioner.to_reference(project)}"
            end
          end
        end

        context 'within the same project' do
          context 'from Commit' do
            let(:mentioner) { project.repository.commit }

            it 'references the mentioning commit' do
              expect(subject.note).to eq "mentioned in commit #{mentioner.to_reference}"
            end
          end

          context 'from non-Commit' do
            it 'references the mentioning object' do
              expect(subject.note).to eq "mentioned in issue #{mentioner.to_reference}"
            end
          end
        end
      end
    end
  end

  describe '.cross_reference?' do
    it 'is truthy when text begins with expected text' do
      expect(described_class.cross_reference?('mentioned in something')).to be_truthy
    end

    it 'is truthy when text begins with legacy capitalized expected text' do
      expect(described_class.cross_reference?('mentioned in something')).to be_truthy
    end

    it 'is falsey when text does not begin with expected text' do
      expect(described_class.cross_reference?('this is a note')).to be_falsey
    end
  end

  describe '.cross_reference_disallowed?' do
    context 'when mentioner is not a MergeRequest' do
      it 'is falsey' do
        mentioner = noteable.dup
        expect(described_class.cross_reference_disallowed?(noteable, mentioner)).
          to be_falsey
      end
    end

    context 'when mentioner is a MergeRequest' do
      let(:mentioner) { create(:merge_request, :simple, source_project: project) }
      let(:noteable)  { project.commit }

      it 'is truthy when noteable is in commits' do
        expect(mentioner).to receive(:commits).and_return([noteable])
        expect(described_class.cross_reference_disallowed?(noteable, mentioner)).
          to be_truthy
      end

      it 'is falsey when noteable is not in commits' do
        expect(mentioner).to receive(:commits).and_return([])
        expect(described_class.cross_reference_disallowed?(noteable, mentioner)).
          to be_falsey
      end
    end

    context 'when notable is an ExternalIssue' do
      let(:noteable) { ExternalIssue.new('EXT-1234', project) }
      it 'is truthy' do
        mentioner = noteable.dup
        expect(described_class.cross_reference_disallowed?(noteable, mentioner)).
          to be_truthy
      end
    end
  end

  describe '.cross_reference_exists?' do
    let(:commit0) { project.commit }
    let(:commit1) { project.commit('HEAD~2') }

    context 'issue from commit' do
      before do
        # Mention issue (noteable) from commit0
        described_class.cross_reference(noteable, commit0, author)
      end

      it 'is truthy when already mentioned' do
        expect(described_class.cross_reference_exists?(noteable, commit0)).
          to be_truthy
      end

      it 'is falsey when not already mentioned' do
        expect(described_class.cross_reference_exists?(noteable, commit1)).
          to be_falsey
      end

      context 'legacy capitalized cross reference' do
        before do
          # Mention issue (noteable) from commit0
          system_note = described_class.cross_reference(noteable, commit0, author)
          system_note.update(note: system_note.note.capitalize)
        end

        it 'is truthy when already mentioned' do
          expect(described_class.cross_reference_exists?(noteable, commit0)).
            to be_truthy
        end
      end
    end

    context 'commit from commit' do
      before do
        # Mention commit1 from commit0
        described_class.cross_reference(commit0, commit1, author)
      end

      it 'is truthy when already mentioned' do
        expect(described_class.cross_reference_exists?(commit0, commit1)).
          to be_truthy
      end

      it 'is falsey when not already mentioned' do
        expect(described_class.cross_reference_exists?(commit1, commit0)).
          to be_falsey
      end

      context 'legacy capitalized cross reference' do
        before do
          # Mention commit1 from commit0
          system_note = described_class.cross_reference(commit0, commit1, author)
          system_note.update(note: system_note.note.capitalize)
        end

        it 'is truthy when already mentioned' do
          expect(described_class.cross_reference_exists?(commit0, commit1)).
            to be_truthy
        end
      end
    end

    context 'commit with cross-reference from fork' do
      let(:author2) { create(:project_member, :reporter, user: create(:user), project: project).user }
      let(:forked_project) { Projects::ForkService.new(project, author2).execute }
      let(:commit2) { forked_project.commit }

      before do
        described_class.cross_reference(noteable, commit0, author2)
      end

      it 'is true when a fork mentions an external issue' do
        expect(described_class.cross_reference_exists?(noteable, commit2)).
            to be true
      end

      context 'legacy capitalized cross reference' do
        before do
          system_note = described_class.cross_reference(noteable, commit0, author2)
          system_note.update(note: system_note.note.capitalize)
        end

        it 'is true when a fork mentions an external issue' do
          expect(described_class.cross_reference_exists?(noteable, commit2)).
              to be true
        end
      end
    end
  end

  describe '.noteable_moved' do
    let(:new_project) { create(:project) }
    let(:new_noteable) { create(:issue, project: new_project) }

    subject do
      described_class.noteable_moved(noteable, project, new_noteable, author, direction: direction)
    end

    shared_examples 'cross project mentionable' do
      include GitlabMarkdownHelper

      it 'contains cross reference to new noteable' do
        expect(subject.note).to include cross_project_reference(new_project, new_noteable)
      end

      it 'mentions referenced noteable' do
        expect(subject.note).to include new_noteable.to_reference
      end

      it 'mentions referenced project' do
        expect(subject.note).to include new_project.to_reference
      end
    end

    context 'moved to' do
      let(:direction) { :to }

      it_behaves_like 'cross project mentionable'

      it 'notifies about noteable being moved to' do
        expect(subject.note).to match /moved to/
      end
    end

    context 'moved from' do
      let(:direction) { :from }

      it_behaves_like 'cross project mentionable'

      it 'notifies about noteable being moved from' do
        expect(subject.note).to match /moved from/
      end
    end

    context 'invalid direction' do
      let(:direction) { :invalid }

      it 'raises error' do
        expect { subject }.to raise_error StandardError, /Invalid direction/
      end
    end
  end

  describe '.new_commit_summary' do
    it 'escapes HTML titles' do
      commit = double(title: '<pre>This is a test</pre>', short_id: '12345678')
      escaped = '* 12345678 - &lt;pre&gt;This is a test&lt;&#x2F;pre&gt;'

      expect(described_class.new_commit_summary([commit])).to eq([escaped])
    end
  end

  include JiraServiceHelper

  describe 'JIRA integration' do
    let(:project)         { create(:jira_project) }
    let(:author)          { create(:user) }
    let(:issue)           { create(:issue, project: project) }
    let(:merge_request)        { create(:merge_request, :simple, target_project: project, source_project: project) }
    let(:jira_issue)      { ExternalIssue.new("JIRA-1", project)}
    let(:jira_tracker)    { project.jira_service }
    let(:commit)          { project.commit }
    let(:comment_url)     { jira_api_comment_url(jira_issue.id) }
    let(:success_message) { "JiraService SUCCESS: Successfully posted to http://jira.example.net." }

    before do
      stub_jira_urls(jira_issue.id)
      jira_service_settings
    end

    noteable_types = ["merge_requests", "commit"]

    noteable_types.each do |type|
      context "when noteable is a #{type}" do
        it "blocks cross reference when #{type.underscore}_events is false" do
          jira_tracker.update("#{type}_events" => false)

          noteable = type == "commit" ? commit : merge_request
          result = described_class.cross_reference(jira_issue, noteable, author)

          expect(result).to eq("Events for #{noteable.class.to_s.underscore.humanize.pluralize.downcase} are disabled.")
        end

        it "blocks cross reference when #{type.underscore}_events is true" do
          jira_tracker.update("#{type}_events" => true)

          noteable = type == "commit" ? commit : merge_request
          result = described_class.cross_reference(jira_issue, noteable, author)

          expect(result).to eq(success_message)
        end
      end
    end

    describe "new reference" do
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
              object: {
                url: namespace_project_commit_url(project.namespace, project, commit),
                title: "GitLab: Mentioned on commit - #{commit.title}",
                icon: { title: "GitLab", url16x16: "https://gitlab.com/favicon.ico" },
                status: { resolved: false }
              }
            )
          ).once
        end
      end

      context 'for issues' do
        let(:issue)           { create(:issue, project: project) }

        it "creates comment" do
          result = described_class.cross_reference(jira_issue, issue, author)

          expect(result).to eq(success_message)
        end

        it "creates remote link" do
          described_class.cross_reference(jira_issue, issue, author)

          expect(WebMock).to have_requested(:post, jira_api_remote_link_url(jira_issue)).with(
            body: hash_including(
              GlobalID: "GitLab",
              object: {
                url: namespace_project_issue_url(project.namespace, project, issue),
                title: "GitLab: Mentioned on issue - #{issue.title}",
                icon: { title: "GitLab", url16x16: "https://gitlab.com/favicon.ico" },
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
              object: {
                url: namespace_project_snippet_url(project.namespace, project, snippet),
                title: "GitLab: Mentioned on snippet - #{snippet.title}",
                icon: { title: "GitLab", url16x16: "https://gitlab.com/favicon.ico" },
                status: { resolved: false }
              }
            )
          ).once
        end
      end
    end

    describe "existing reference" do
      before do
        message = "[#{author.name}|http://localhost/#{author.username}] mentioned this issue in [a commit of #{project.path_with_namespace}|http://localhost/#{project.path_with_namespace}/commit/#{commit.id}]:\n'#{commit.title}'"
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
end
