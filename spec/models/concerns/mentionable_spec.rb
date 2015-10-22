require 'spec_helper'

describe Issue, "Mentionable" do
  describe '#mentioned_users' do
    let!(:user) { create(:user, username: 'stranger') }
    let!(:user2) { create(:user, username: 'john') }
    let!(:issue) { create(:issue, description: "#{user.to_reference} mentioned") }

    subject { issue.mentioned_users }

    it { is_expected.to include(user) }
    it { is_expected.not_to include(user2) }
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
    let(:issues)  { create_list(:issue, 2, project: project) }

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
      create(:issue, project: project, description: description)
    end
  end
end
