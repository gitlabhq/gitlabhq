require 'spec_helper'

describe Commit do
  let(:commit) { create(:project).repository.commit }

  describe CommitDecorator do
    let(:decorator) { CommitDecorator.new(commit) }

    describe '#title' do
      it "returns no_commit_message when safe_message is blank" do
        decorator.stub(:safe_message).and_return('')
        decorator.title.should == "--no commit message"
      end

      it "truncates a message without a newline at 70 characters" do
        message = commit.safe_message * 10

        decorator.stub(:safe_message).and_return(message)
        decorator.title.should == "#{message[0..69]}&hellip;"
      end

      it "truncates a message with a newline before 80 characters at the newline" do
        message = commit.safe_message.split(" ").first

        decorator.stub(:safe_message).and_return(message + "\n" + message)
        decorator.title.should == message
      end

      it "truncates a message with a newline after 80 characters at 70 characters" do
        message = (commit.safe_message * 10) + "\n"

        decorator.stub(:safe_message).and_return(message)
        decorator.title.should == "#{message[0..69]}&hellip;"
      end
    end
  end

  describe "Commit info" do
    before do
      @committer = double(
        email: 'mike@smith.com',
        name: 'Mike Smith'
      )

      @author = double(
        email: 'john@smith.com',
        name: 'John Smith'
      )

      @raw_commit = double(
        id: "bcf03b5de6abcf03b5de6c",
        author: @author,
        committer: @committer,
        committed_date: Date.yesterday,
        message: 'Refactoring specs'
      )

      @commit = Commit.new(@raw_commit)
    end

    it { @commit.short_id.should == "bcf03b5de6a" }
    it { @commit.safe_message.should == @raw_commit.message }
    it { @commit.created_at.should == @raw_commit.committed_date }
    it { @commit.author_email.should == @author.email }
    it { @commit.author_name.should == @author.name }
    it { @commit.committer_name.should == @committer.name }
    it { @commit.committer_email.should == @committer.email }
    it { @commit.different_committer?.should be_true }
  end

  describe "Class methods" do
    subject { Commit }

    it { should respond_to(:find_or_first) }
    it { should respond_to(:fresh_commits) }
    it { should respond_to(:commits_with_refs) }
    it { should respond_to(:commits_since) }
    it { should respond_to(:commits_between) }
    it { should respond_to(:commits) }
    it { should respond_to(:compare) }
  end

  describe "delegation" do
    subject { commit }

    it { should respond_to(:message) }
    it { should respond_to(:authored_date) }
    it { should respond_to(:committed_date) }
    it { should respond_to(:parents) }
    it { should respond_to(:date) }
    it { should respond_to(:committer) }
    it { should respond_to(:author) }
    it { should respond_to(:diffs) }
    it { should respond_to(:tree) }
    it { should respond_to(:id) }
    it { should respond_to(:to_patch) }
  end
end
