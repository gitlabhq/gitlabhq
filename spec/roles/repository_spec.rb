require 'spec_helper'

describe Project, "Repository" do
  let(:project) { build(:project) }

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
end
