require 'spec_helper'

describe Mentionable do
  include Mentionable

  describe :references do
    let(:project) { create(:project) }

    it 'excludes JIRA references' do
      project.stub(jira_tracker?: true)
      references(project, 'JIRA-123').should be_empty
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

  describe '#create_cross_references!' do
    let(:project) { create(:project) }
    let(:author)  { double('author') }
    let(:commit)  { project.commit }
    let(:commit2) { project.commit }

    let!(:issue) do
      create(:issue, project: project, description: commit.to_reference)
    end

    it 'correctly removes already-mentioned Commits' do
      expect(Note).not_to receive(:create_cross_reference_note)

      issue.create_cross_references!(project, author, [commit2])
    end
  end
end
