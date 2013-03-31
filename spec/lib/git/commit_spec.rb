require "spec_helper"

describe Gitlab::Git::Commit do
  let(:commit) { create(:project).repository.commit }

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

      @commit = Gitlab::Git::Commit.new(@raw_commit)
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
    subject { Gitlab::Git::Commit }

    it { should respond_to(:find_or_first) }
    it { should respond_to(:fresh_commits) }
    it { should respond_to(:commits_with_refs) }
    it { should respond_to(:commits_since) }
    it { should respond_to(:commits_between) }
    it { should respond_to(:commits) }
    it { should respond_to(:compare) }
  end
end
