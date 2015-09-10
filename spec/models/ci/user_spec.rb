require 'spec_helper'

describe Ci::User do

  describe "authorized_projects" do
    let (:user) { User.new({}) }

    before do
      FactoryGirl.create :ci_project, gitlab_id: 1
      FactoryGirl.create :ci_project, gitlab_id: 2
      gitlab_project = OpenStruct.new({id: 1})
      gitlab_project1 = OpenStruct.new({id: 2})
      User.any_instance.stub(:gitlab_projects).and_return([gitlab_project, gitlab_project1])
    end

    it "returns projects" do
      User.any_instance.stub(:can_manage_project?).and_return(true)

      user.authorized_projects.count.should == 2
    end

    it "empty list if user miss manage permission" do
      User.any_instance.stub(:can_manage_project?).and_return(false)

      user.authorized_projects.count.should == 0
    end
  end

  describe "authorized_runners" do
    it "returns authorized runners" do
      project = FactoryGirl.create :ci_project, gitlab_id: 1
      project1 = FactoryGirl.create :ci_project, gitlab_id: 2
      gitlab_project = OpenStruct.new({id: 1})
      gitlab_project1 = OpenStruct.new({id: 2})
      User.any_instance.stub(:gitlab_projects).and_return([gitlab_project, gitlab_project1])
      User.any_instance.stub(:can_manage_project?).and_return(true)
      user = User.new({})

      runner = FactoryGirl.create :ci_specific_runner
      runner1 = FactoryGirl.create :ci_specific_runner
      runner2 = FactoryGirl.create :ci_specific_runner

      project.runners << runner
      project1.runners << runner1

      user.authorized_runners.should include(runner, runner1)
      user.authorized_runners.should_not include(runner2)
    end
  end
end
