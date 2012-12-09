require 'spec_helper'

describe PostReceive do

  context "as a resque worker" do
    it "reponds to #perform" do
      PostReceive.should respond_to(:perform)
    end
  end

  context "web hook" do
    let(:project) { create(:project) }
    let(:key) { create(:key, user: project.owner) }
    let(:key_id) { key.identifier }

    it "fetches the correct project" do
      Project.should_receive(:find_with_namespace).with(project.to_param).and_return(project)

      PostReceive.perform(project.to_param, 'sha-old', 'sha-new', 'refs/heads/master', key_id)
    end

    it "does trigger hooks" do
      Project.any_instance.should_receive(:trigger_post_receive)

      PostReceive.perform(project.to_param, 'sha-old', 'sha-new', 'refs/heads/master', key_id)
    end

    it "does not run if the author is not in the project" do
      Key.stub(find_by_identifier: nil)

      Project.any_instance.should_not_receive(:trigger_post_receive)

      PostReceive.perform(project.to_param, 'sha-old', 'sha-new', 'refs/heads/master', key_id).should be_false
    end

    it "asks the project to trigger all hooks" do
      Project.any_instance.should_receive(:observe_push)
      Project.any_instance.should_receive(:update_merge_requests)
      Project.any_instance.should_receive(:execute_hooks)
      Project.any_instance.should_receive(:execute_services)

      PostReceive.perform(project.to_param, 'sha-old', 'sha-new', 'refs/heads/master', key_id)
    end
  end
end
