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
      message = commit.safe_message * 10

      allow(commit).to receive(:safe_message).and_return(message)
      expect(commit.title).to eq("#{message[0..79]}&hellip;")
    end

    it "truncates a message with a newline before 80 characters at the newline" do
      message = commit.safe_message.split(" ").first

      allow(commit).to receive(:safe_message).and_return(message + "\n" + message)
      expect(commit.title).to eq(message)
    end

    it "truncates a message with a newline after 80 characters at 70 characters" do
      message = (commit.safe_message * 10) + "\n"

      allow(commit).to receive(:safe_message).and_return(message)
      expect(commit.title).to eq("#{message[0..79]}&hellip;")
    end
  end

  describe "delegation" do
    subject { commit }

    it { should respond_to(:message) }
    it { should respond_to(:authored_date) }
    it { should respond_to(:committed_date) }
    it { should respond_to(:committer_email) }
    it { should respond_to(:author_email) }
    it { should respond_to(:parents) }
    it { should respond_to(:date) }
    it { should respond_to(:diffs) }
    it { should respond_to(:tree) }
    it { should respond_to(:id) }
    it { should respond_to(:to_patch) }
  end

  describe '#closes_issues' do
    let(:issue) { create :issue, project: project }

    it 'detects issues that this commit is marked as closing' do
      commit.stub(issue_closing_regex: /^([Cc]loses|[Ff]ixes) #\d+/, safe_message: "Fixes ##{issue.iid}")
      expect(commit.closes_issues(project)).to eq([issue])
    end
  end

  it_behaves_like 'a mentionable' do
    let(:subject) { commit }
    let(:mauthor) { create :user, email: commit.author_email }
    let(:backref_text) { "commit #{subject.sha[0..5]}" }
    let(:set_mentionable_text) { ->(txt){ subject.stub(safe_message: txt) } }

    # Include the subject in the repository stub.
    let(:extra_commits) { [subject] }
  end
end
