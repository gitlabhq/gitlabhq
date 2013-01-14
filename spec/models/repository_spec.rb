require "spec_helper"

describe Repository do
  let(:project) { create(:project) }
  let(:repository) { project.repository }

  describe "Respond to" do
    subject { repository }

    it { should respond_to(:repo) }
    it { should respond_to(:tree) }
    it { should respond_to(:root_ref) }
    it { should respond_to(:tags) }
    it { should respond_to(:commit) }
    it { should respond_to(:commits) }
    it { should respond_to(:commits_between) }
    it { should respond_to(:commits_with_refs) }
    it { should respond_to(:commits_since) }
    it { should respond_to(:commits_between) }
  end


  describe "#discover_default_branch" do
    let(:master) { 'master' }
    let(:stable) { 'stable' }

    it "returns 'master' when master exists" do
      repository.should_receive(:branch_names).at_least(:once).and_return([stable, master])
      repository.discover_default_branch.should == 'master'
    end

    it "returns non-master when master exists but default branch is set to something else" do
      repository.root_ref = 'stable'
      repository.should_receive(:branch_names).at_least(:once).and_return([stable, master])
      repository.discover_default_branch.should == 'stable'
    end

    it "returns a non-master branch when only one exists" do
      repository.should_receive(:branch_names).at_least(:once).and_return([stable])
      repository.discover_default_branch.should == 'stable'
    end

    it "returns nil when no branch exists" do
      repository.should_receive(:branch_names).at_least(:once).and_return([])
      repository.discover_default_branch.should be_nil
    end
  end

  describe :commit do
    it "should return first head commit if without params" do
      repository.commit.id.should == repository.repo.commits.first.id
    end

    it "should return valid commit" do
      repository.commit(ValidCommit::ID).should be_valid_commit
    end

    it "should return nil" do
      repository.commit("+123_4532530XYZ").should be_nil
    end
  end

  describe :tree do
    before do
      @commit = repository.commit(ValidCommit::ID)
    end

    it "should raise error w/o arguments" do
      lambda { repository.tree }.should raise_error
    end

    it "should return root tree for commit" do
      tree = repository.tree(@commit)
      tree.contents.size.should == ValidCommit::FILES_COUNT
      tree.contents.map(&:name).should == ValidCommit::FILES
    end

    it "should return root tree for commit with correct path" do
      tree = repository.tree(@commit, ValidCommit::C_FILE_PATH)
      tree.contents.map(&:name).should == ValidCommit::C_FILES
    end

    it "should return root tree for commit with incorrect path" do
      repository.tree(@commit, "invalid_path").should be_nil
    end
  end

  describe "fresh commits" do
    it { repository.fresh_commits(3).count.should == 3 }
    it { repository.fresh_commits.first.id.should == "bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a" }
    it { repository.fresh_commits.last.id.should == "f403da73f5e62794a0447aca879360494b08f678" }
  end

  describe "commits_between" do
    subject do
      commits = repository.commits_between("3a4b4fb4cde7809f033822a171b9feae19d41fff",
                                        "8470d70da67355c9c009e4401746b1d5410af2e3")
      commits.map { |c| c.id }
    end

    it { should have(3).elements }
    it { should include("f0f14c8eaba69ebddd766498a9d0b0e79becd633") }
    it { should_not include("bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a") }
  end
end
