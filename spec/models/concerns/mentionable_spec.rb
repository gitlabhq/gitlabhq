require 'spec_helper'

describe Mentionable do
  include Mentionable

  def author
    nil
  end

  describe 'references' do
    let(:project) { create(:project) }

    it 'excludes JIRA references' do
      allow(project).to receive_messages(jira_tracker?: true)
      expect(referenced_mentionables(project, 'JIRA-123')).to be_empty
    end
  end
end

describe Issue, "Mentionable" do
  describe '#mentioned_users' do
    let!(:user) { create(:user, username: 'stranger') }
    let!(:user2) { create(:user, username: 'john') }
    let!(:issue) { create(:issue, description: "#{user.to_reference} mentioned") }

    subject { issue.mentioned_users }

    it { is_expected.to include(user) }
    it { is_expected.not_to include(user2) }
  end

  describe '#referenced_mentionables' do
    context 'with an issue on a private project' do
      let(:project) { create(:empty_project, :public) }
      let(:issue) { create(:issue, project: project) }
      let(:public_issue) { create(:issue, project: project) }
      let(:private_project) { create(:empty_project, :private) }
      let(:private_issue) { create(:issue, project: private_project) }
      let(:user) { create(:user) }

      def referenced_issues(current_user)
        text = "#{private_issue.to_reference(project)} and #{public_issue.to_reference}"

        issue.referenced_mentionables(current_user, text)
      end

      context 'when the current user can see the issue' do
        before { private_project.team << [user, Gitlab::Access::DEVELOPER] }

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
    let(:project) { create(:project) }
    let(:author)  { double('author') }
    let(:commit)  { project.commit }
    let(:commit2) { project.commit }

    let!(:issue) do
      create(:issue, project: project, description: commit.to_reference)
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
    end

    def create_issue(description:)
      create(:issue, project: project, description: description, author: author)
    end
  end
end
