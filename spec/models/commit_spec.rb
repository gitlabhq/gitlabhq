require 'spec_helper'

describe Commit do
  let(:project) { create :project }
  let(:commit) { project.repository.commit }

  describe '#title' do
    it "returns no_commit_message when safe_message is blank" do
      allow(commit).to receive(:safe_message).and_return('')
      expect(commit.title).to eq("--no commit message")
    end

    it "truncates a message without a newline at 80 characters" do
      message = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sodales id felis id blandit. Vivamus egestas lacinia lacus, sed rutrum mauris.'

      allow(commit).to receive(:safe_message).and_return(message)
      expect(commit.title).to eq("#{message[0..79]}&hellip;")
    end

    it "truncates a message with a newline before 80 characters at the newline" do
      message = commit.safe_message.split(" ").first

      allow(commit).to receive(:safe_message).and_return(message + "\n" + message)
      expect(commit.title).to eq(message)
    end

    it "does not truncates a message with a newline after 80 but less 100 characters" do
      message =<<eos
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sodales id felis id blandit.
Vivamus egestas lacinia lacus, sed rutrum mauris.
eos

      allow(commit).to receive(:safe_message).and_return(message)
      expect(commit.title).to eq(message.split("\n").first)
    end
  end

  describe "delegation" do
    subject { commit }

    it { is_expected.to respond_to(:message) }
    it { is_expected.to respond_to(:authored_date) }
    it { is_expected.to respond_to(:committed_date) }
    it { is_expected.to respond_to(:committer_email) }
    it { is_expected.to respond_to(:author_email) }
    it { is_expected.to respond_to(:parents) }
    it { is_expected.to respond_to(:date) }
    it { is_expected.to respond_to(:diffs) }
    it { is_expected.to respond_to(:tree) }
    it { is_expected.to respond_to(:id) }
    it { is_expected.to respond_to(:to_patch) }
  end

  describe '#closes_issues' do
    let(:issue) { create :issue, project: project }
    let(:other_project) { create :project, :public }
    let(:other_issue) { create :issue, project: other_project }

    it 'detects issues that this commit is marked as closing' do
      commit.stub(safe_message: "Fixes ##{issue.iid}")
      expect(commit.closes_issues(project)).to eq([issue])
    end

    it 'does not detect issues from other projects' do
      ext_ref = "#{other_project.path_with_namespace}##{other_issue.iid}"
      commit.stub(safe_message: "Fixes #{ext_ref}")
      expect(commit.closes_issues(project)).to be_empty
    end
  end

  it_behaves_like 'a mentionable' do
    let(:subject) { commit }
    let(:mauthor) { create :user, email: commit.author_email }
    let(:backref_text) { "commit #{subject.id}" }
    let(:set_mentionable_text) { ->(txt){ subject.stub(safe_message: txt) } }

    # Include the subject in the repository stub.
    let(:extra_commits) { [subject] }
  end
end
