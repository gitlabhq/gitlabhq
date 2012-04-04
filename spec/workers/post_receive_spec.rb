require 'spec_helper'

describe PostReceive do

  context "as a resque worker" do
    it "reponds to #perform" do
      PostReceive.should respond_to(:perform)
    end
  end

  context "web hook" do
    let(:project) { Factory.create(:project) }
    let(:key) { Factory.create(:key, :user => project.owner) }
    let(:key_id) { key.identifier }

    it "fetches the correct project" do
      Project.should_receive(:find_by_path).with(project.path).and_return(project)
      PostReceive.perform(project.path, 'sha-old', 'sha-new', 'refs/heads/master', key_id)
    end

    it "does not run if the author is not in the project" do
      Key.stub(find_by_identifier: nil)

      project.should_not_receive(:observe_push)
      project.should_not_receive(:execute_web_hooks)

      PostReceive.perform(project.path, 'sha-old', 'sha-new', 'refs/heads/master', key_id).should be_false
    end

    it "asks the project to execute web hooks" do
      Project.stub(find_by_path: project)
      project.should_receive(:execute_web_hooks).with('sha-old', 'sha-new', 'refs/heads/master', project.owner)

      PostReceive.perform(project.path, 'sha-old', 'sha-new', 'refs/heads/master', key_id)
    end

    it "asks the project to observe push/create event data" do
      Project.stub(find_by_path: project)
      project.should_receive(:observe_push).with('sha-old', 'sha-new', 'refs/heads/master', project.owner)

      PostReceive.perform(project.path, 'sha-old', 'sha-new', 'refs/heads/master', key_id)
    end
  end
end
