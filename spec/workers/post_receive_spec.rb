require 'spec_helper'

describe PostReceive do

  context "as a resque worker" do
    it "reponds to #perform" do
      PostReceive.should respond_to(:perform)
    end
  end

  context "web hooks" do
    let(:project) { Factory :project }
    before do 
      @key = Factory :key, :user => project.owner
      @key_id = @key.identifier
    end

    it "it retrieves the correct project" do
      Project.should_receive(:find_by_path).with(project.path)
      Key.should_receive(:find_by_identifier).with(project.path)
      PostReceive.perform(project.path, 'sha-old', 'sha-new', 'refs/heads/master', @key_id)
    end

    it "asks the project to execute web hooks" do
      Project.stub(find_by_path: project)
      project.should_receive(:execute_web_hooks).with('sha-old', 'sha-new', 'refs/heads/master', @key_id)

      PostReceive.perform(project.path, 'sha-old', 'sha-new', 'refs/heads/master', @key_id)
    end
  end
end
