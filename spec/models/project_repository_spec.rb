require 'spec_helper'

describe Project, "Repository" do
  let(:project) { create(:project) }

  describe "#empty_repo?" do
    it "should return true if the repo doesn't exist" do
      project.stub(repo_exists?: false, has_commits?: true)
      project.should be_empty_repo
    end

    it "should return true if the repo has commits" do
      project.stub(repo_exists?: true, has_commits?: false)
      project.should be_empty_repo
    end

    it "should return false if the repo exists and has commits" do
      project.stub(repo_exists?: true, has_commits?: true)
      project.should_not be_empty_repo
    end
  end

  describe "#discover_default_branch" do
    let(:master) { 'master' }
    let(:stable) { 'stable' }

    it "returns 'master' when master exists" do
      project.should_receive(:branch_names).at_least(:once).and_return([stable, master])
      project.discover_default_branch.should == 'master'
    end

    it "returns non-master when master exists but default branch is set to something else" do
      project.default_branch = 'stable'
      project.should_receive(:branch_names).at_least(:once).and_return([stable, master])
      project.discover_default_branch.should == 'stable'
    end

    it "returns a non-master branch when only one exists" do
      project.should_receive(:branch_names).at_least(:once).and_return([stable])
      project.discover_default_branch.should == 'stable'
    end

    it "returns nil when no branch exists" do
      project.should_receive(:branch_names).at_least(:once).and_return([])
      project.discover_default_branch.should be_nil
    end
  end

  describe "#root_ref" do
    it "returns default_branch when set" do
      project.default_branch = 'stable'
      project.root_ref.should == 'stable'
    end

    it "returns 'master' when default_branch is nil" do
      project.default_branch = nil
      project.root_ref.should == 'master'
    end
  end

  describe "#root_ref?" do
    it "returns true when branch is root_ref" do
      project.default_branch = 'stable'
      project.root_ref?('stable').should be_true
    end

    it "returns false when branch is not root_ref" do
      project.default_branch = nil
      project.root_ref?('stable').should be_false
    end
  end

  describe :repo do
    it "should return valid repo" do
      project.repo.should be_kind_of(Grit::Repo)
    end

    it "should return nil" do
      lambda { Project.new(path: "invalid").repo }.should raise_error(Grit::NoSuchPathError)
    end

    it "should return nil" do
      lambda { Project.new.repo }.should raise_error(TypeError)
    end
  end

  describe :commit do
    it "should return first head commit if without params" do
      project.commit.id.should == project.repo.commits.first.id
    end

    it "should return valid commit" do
      project.commit(ValidCommit::ID).should be_valid_commit
    end

    it "should return nil" do
      project.commit("+123_4532530XYZ").should be_nil
    end
  end

  describe :tree do
    before do
      @commit = project.commit(ValidCommit::ID)
    end

    it "should raise error w/o arguments" do
      lambda { project.tree }.should raise_error
    end

    it "should return root tree for commit" do
      tree = project.tree(@commit)
      tree.contents.size.should == ValidCommit::FILES_COUNT
      tree.contents.map(&:name).should == ValidCommit::FILES
    end

    it "should return root tree for commit with correct path" do
      tree = project.tree(@commit, ValidCommit::C_FILE_PATH)
      tree.contents.map(&:name).should == ValidCommit::C_FILES
    end

    it "should return root tree for commit with incorrect path" do
      project.tree(@commit, "invalid_path").should be_nil
    end
  end

  describe "fresh commits" do
    let(:project) { create(:project) }

    it { project.fresh_commits(3).count.should == 3 }
    it { project.fresh_commits.first.id.should == "bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a" }
    it { project.fresh_commits.last.id.should == "f403da73f5e62794a0447aca879360494b08f678" }
  end

  describe "commits_between" do
    let(:project) { create(:project) }

    subject do
      commits = project.commits_between("3a4b4fb4cde7809f033822a171b9feae19d41fff",
                                        "8470d70da67355c9c009e4401746b1d5410af2e3")
      commits.map { |c| c.id }
    end

    it { should have(3).elements }
    it { should include("f0f14c8eaba69ebddd766498a9d0b0e79becd633") }
    it { should_not include("bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a") }
  end

  describe :valid_repo? do
    it "should be valid repo" do
      project = create(:project)
      project.valid_repo?.should be_true
    end

    it "should be invalid repo" do
      project = Project.new(name: "ok_name", path: "/INVALID_PATH/", path: "NEOK")
      project.valid_repo?.should be_false
    end
  end
end
