require 'spec_helper'

describe Ci::User do

  describe "authorized_projects" do
    let (:user) { User.new({}) }

    before do
      FactoryGirl.create :ci_project, gitlab_id: 1
      FactoryGirl.create :ci_project, gitlab_id: 2
      gitlab_project = OpenStruct.new({id: 1})
      gitlab_project1 = OpenStruct.new({id: 2})
      allow_any_instance_of(User).to receive(:gitlab_projects).and_return([gitlab_project, gitlab_project1])
    end

    it "returns projects" do
      allow_any_instance_of(User).to receive(:can_manage_project?).and_return(true)

      expect(user.authorized_projects.count).to eq(2)
    end

    it "empty list if user miss manage permission" do
      allow_any_instance_of(User).to receive(:can_manage_project?).and_return(false)

      expect(user.authorized_projects.count).to eq(0)
    end
  end

  describe "authorized_runners" do
    it "returns authorized runners" do
      project = FactoryGirl.create :ci_project, gitlab_id: 1
      project1 = FactoryGirl.create :ci_project, gitlab_id: 2
      gitlab_project = OpenStruct.new({id: 1})
      gitlab_project1 = OpenStruct.new({id: 2})
      allow_any_instance_of(User).to receive(:gitlab_projects).and_return([gitlab_project, gitlab_project1])
      allow_any_instance_of(User).to receive(:can_manage_project?).and_return(true)
      user = User.new({})

      runner = FactoryGirl.create :ci_specific_runner
      runner1 = FactoryGirl.create :ci_specific_runner
      runner2 = FactoryGirl.create :ci_specific_runner

      project.runners << runner
      project1.runners << runner1

      expect(user.authorized_runners).to include(runner, runner1)
      expect(user.authorized_runners).not_to include(runner2)
    end
  end
end
