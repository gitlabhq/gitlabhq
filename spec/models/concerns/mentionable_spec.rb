require 'spec_helper'

describe Mentionable do
  class Example
    include Mentionable

    attr_accessor :project, :message
    attr_mentionable :message

    def author
      nil
    end
  end

  describe 'references' do
    let(:project) { create(:project) }
    let(:mentionable) { Example.new }

    it 'excludes JIRA references' do
      allow(project).to receive_messages(jira_tracker?: true)

      mentionable.project = project
      mentionable.message = 'JIRA-123'
      expect(mentionable.referenced_mentionables).to be_empty
    end
  end
end

describe Issue, "Mentionable" do
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

        issue.update_attributes(description: 'New description')
        issue.create_new_cross_references!
      end

      it 'notifies new references' do
        issue = create_issue(description: issues[0].to_reference)

        expect(SystemNoteService).to receive(:cross_reference).with(issues[1], any_args)

        issue.update_attributes(description: issues[1].to_reference)
        issue.create_new_cross_references!
      end

      it 'notifies new references from project snippet note' do
        snippet = create(:snippet, project: project)
        note = create(:note, note: issues[0].to_reference, noteable: snippet, project: project, author: author)

        expect(SystemNoteService).to receive(:cross_reference).with(issues[1], any_args)

        note.update_attributes(note: issues[1].to_reference)
        note.create_new_cross_references!
      end
    end

    def create_issue(description:)
      create(:issue, project: project, description: description, author: author)
    end
  end
end

describe Commit, 'Mentionable' do
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
      let(:project) { create(:jira_project, :repository) }

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
end
