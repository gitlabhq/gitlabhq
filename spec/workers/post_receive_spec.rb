require 'spec_helper'

describe PostReceive do

  context "as a resque worker" do
    it "reponds to #perform" do
      PostReceive.should respond_to(:perform)
    end
  end

  context "web hooks" do
    let(:project) { Factory :project }

    it "it retrieves the correct project" do
      Project.should_receive(:find_by_path).with(project.path)
      PostReceive.perform(project.path, 'sha-old', 'sha-new', 'refs/heads/master')
    end

    it "asks the project to execute web hooks" do
      Project.stub(find_by_path: project)
      project.should_receive(:execute_web_hooks).with('sha-old', 'sha-new', 'refs/heads/master')

      PostReceive.perform(project.path, 'sha-old', 'sha-new', 'refs/heads/master')
    end
  end
end
