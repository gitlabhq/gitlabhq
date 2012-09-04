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
end
