# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mentionable, feature_category: :shared do
  before do
    stub_const('Example', Class.new)
    Example.class_eval do
      include Mentionable

      attr_accessor :project, :message

      attr_mentionable :message

      def author
        nil
      end
    end
  end

  describe 'references' do
    let(:project) { create(:project) }
    let(:mentionable) { Example.new }

    it 'excludes Jira references' do
      allow(project).to receive_messages(jira_tracker?: true)

      mentionable.project = project
      mentionable.message = 'JIRA-123'
      expect(mentionable.referenced_mentionables).to be_empty
    end
  end
end

RSpec.describe Issue, "Mentionable", feature_category: :team_planning do
  describe '#mentioned_users' do
    let!(:user) { create(:user, username: 'stranger') }
    let!(:user2) { create(:user, username: 'john') }
    let!(:user3) { create(:user, username: 'jim') }
    let(:issue) { create(:issue, description: "#{user.to_reference} mentioned") }

    subject { issue.mentioned_users }

    it { expect(subject).to contain_exactly(user) }

    context 'when a note on personal snippet' do
      let!(:note) { create(:note_on_personal_snippet, note: "#{user.to_reference} mentioned #{user3.to_reference}") }

      subject { note.mentioned_users }

      it { expect(subject).to contain_exactly(user, user3) }
    end
  end

  describe '#referenced_mentionables' do
    context 'with an issue on a private project' do
      let(:project) { create(:project, :public) }
      let(:issue) { create(:issue, project: project) }
      let(:public_issue) { create(:issue, project: project) }
      let(:private_project) { create(:project, :private) }
      let(:private_issue) { create(:issue, project: private_project) }
      let(:user) { create(:user) }

      def referenced_issues(current_user)
        issue.title = "#{private_issue.to_reference(project)} and #{public_issue.to_reference}"
        issue.referenced_mentionables(current_user)
      end

      context 'when the current user can see the issue' do
        before do
          private_project.add_developer(user)
        end

        it 'includes the reference' do
          expect(referenced_issues(user)).to contain_exactly(private_issue, public_issue)
        end
      end

      context 'when the current user cannot see the issue' do
        it 'does not include the reference' do
          expect(referenced_issues(user)).to contain_exactly(public_issue)
        end
      end

      context 'when there is no current user' do
        it 'does not include the reference' do
          expect(referenced_issues(nil)).to contain_exactly(public_issue)
        end
      end
    end
  end

  describe '#create_cross_references!' do
    let(:project) { create(:project, :repository) }
    let(:author)  { build(:user) }
    let(:commit)  { project.commit }
    let(:commit2) { project.commit }

    let!(:issue) do
      create(:issue, project: project, description: "See #{commit.to_reference}")
    end

    it 'correctly removes already-mentioned Commits' do
      expect(SystemNoteService).not_to receive(:cross_reference)

      issue.create_cross_references!(author, [commit2])
    end
  end

  describe '#create_new_cross_references!' do
    let(:project) { create(:project) }
    let(:author)  { create(:author) }
    let(:issues)  { create_list(:issue, 2, project: project, author: author) }

    before do
      project.add_developer(author)
    end

    context 'before changes are persisted' do
      it 'ignores pre-existing references' do
        issue = create_issue(description: issues[0].to_reference)

        expect(SystemNoteService).not_to receive(:cross_reference)

        issue.description = 'New description'
        issue.create_new_cross_references!
      end

      it 'notifies new references' do
        issue = create_issue(description: issues[0].to_reference)

        expect(SystemNoteService).to receive(:cross_reference).with(issues[1], any_args)

        issue.description = issues[1].to_reference
        issue.create_new_cross_references!
      end
    end

    context 'after changes are persisted' do
      it 'ignores pre-existing references' do
        issue = create_issue(description: issues[0].to_reference)

        expect(SystemNoteService).not_to receive(:cross_reference)

        issue.update!(description: 'New description')
        issue.create_new_cross_references!
      end

      it 'notifies new references' do
        issue = create_issue(description: issues[0].to_reference)

        expect(SystemNoteService).to receive(:cross_reference).with(issues[1], any_args)

        issue.update!(description: issues[1].to_reference)
        issue.create_new_cross_references!
      end

      it 'notifies new references from project snippet note' do
        snippet = create(:project_snippet, project: project)
        note = create(:note, note: issues[0].to_reference, noteable: snippet, project: project, author: author)

        expect(SystemNoteService).to receive(:cross_reference).with(issues[1], any_args)

        note.update!(note: issues[1].to_reference)
        note.create_new_cross_references!
      end
    end

    def create_issue(description:)
      create(:issue, project: project, description: description, author: author)
    end
  end

  describe '#store_mentions!' do
    it_behaves_like 'mentions in description', :issue
    it_behaves_like 'mentions in notes', :issue do
      let(:note) { create(:note_on_issue) }
      let(:mentionable) { note.noteable }
    end
  end

  describe 'load mentions' do
    it_behaves_like 'load mentions from DB', :issue do
      let(:note) { create(:note_on_issue) }
      let(:mentionable) { note.noteable }
    end
  end
end

RSpec.describe Commit, 'Mentionable', feature_category: :source_code_management do
  let(:project) { create(:project, :public, :repository) }
  let(:commit)  { project.commit }

  describe '#matches_cross_reference_regex?' do
    it "is false when message doesn't reference anything" do
      allow(commit.raw).to receive(:message).and_return "WIP: Do something"

      expect(commit.matches_cross_reference_regex?).to be_falsey
    end

    it 'is true if issue #number mentioned in title' do
      allow(commit.raw).to receive(:message).and_return "#1"

      expect(commit.matches_cross_reference_regex?).to be_truthy
    end

    it 'is true if references an MR' do
      allow(commit.raw).to receive(:message).and_return "See merge request !12"

      expect(commit.matches_cross_reference_regex?).to be_truthy
    end

    it 'is true if references a commit' do
      allow(commit.raw).to receive(:message).and_return "a1b2c3d4"

      expect(commit.matches_cross_reference_regex?).to be_truthy
    end

    it 'is true if issue referenced by url' do
      issue = create(:issue, project: project)

      allow(commit.raw).to receive(:message).and_return Gitlab::UrlBuilder.build(issue)

      expect(commit.matches_cross_reference_regex?).to be_truthy
    end

    context 'with external issue tracker' do
      let_it_be(:project) { create(:project, :with_jira_integration, :repository) }

      it 'is true if external issues referenced' do
        allow(commit.raw).to receive(:message).and_return 'JIRA-123'

        expect(commit.matches_cross_reference_regex?).to be_truthy
      end

      it 'is true if internal issues referenced' do
        allow(commit.raw).to receive(:message).and_return '#123'

        expect(commit.matches_cross_reference_regex?).to be_truthy
      end
    end
  end

  describe '#store_mentions!' do
    it_behaves_like 'mentions in notes', :commit do
      let(:note) { create(:note_on_commit) }
      let(:mentionable) { note.noteable }
    end
  end

  describe 'load mentions' do
    it_behaves_like 'load mentions from DB', :commit do
      let(:note) { create(:note_on_commit) }
      let(:mentionable) { note.noteable }
    end
  end
end

RSpec.describe MergeRequest, 'Mentionable', feature_category: :code_review_workflow do
  describe '#store_mentions!' do
    it_behaves_like 'mentions in description', :merge_request
    it_behaves_like 'mentions in notes', :merge_request do
      let(:project) { create(:project) }
      let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
      let(:note) { create(:note_on_merge_request, noteable: merge_request, project: merge_request.project) }
      let(:mentionable) { note.noteable }
    end
  end

  describe 'load mentions' do
    it_behaves_like 'load mentions from DB', :merge_request do
      let(:project) { create(:project) }
      let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
      let(:note) { create(:note_on_merge_request, noteable: merge_request, project: merge_request.project) }
      let(:mentionable) { note.noteable }
    end
  end
end

RSpec.describe Snippet, 'Mentionable', feature_category: :source_code_management do
  describe '#store_mentions!' do
    it_behaves_like 'mentions in description', :project_snippet
    it_behaves_like 'mentions in notes', :project_snippet do
      let(:note) { create(:note_on_project_snippet) }
      let(:mentionable) { note.noteable }
    end
  end

  describe 'load mentions' do
    it_behaves_like 'load mentions from DB', :project_snippet do
      let(:note) { create(:note_on_project_snippet) }
      let(:mentionable) { note.noteable }
    end
  end
end

RSpec.describe PersonalSnippet, 'Mentionable', feature_category: :source_code_management do
  describe '#store_mentions!' do
    it_behaves_like 'mentions in description', :personal_snippet
    it_behaves_like 'mentions in notes', :personal_snippet do
      let(:note) { create(:note_on_personal_snippet) }
      let(:mentionable) { note.noteable }
    end
  end

  describe 'load mentions' do
    it_behaves_like 'load mentions from DB', :personal_snippet do
      let(:note) { create(:note_on_personal_snippet) }
      let(:mentionable) { note.noteable }
    end
  end
end

RSpec.describe DesignManagement::Design, feature_category: :team_planning do
  describe '#store_mentions!' do
    it_behaves_like 'mentions in notes', :design do
      let(:note) { create(:diff_note_on_design) }
      let(:mentionable) { note.noteable }
    end
  end

  describe 'load mentions' do
    it_behaves_like 'load mentions from DB', :design do
      let(:note) { create(:diff_note_on_design) }
      let(:mentionable) { note.noteable }
    end
  end
end
