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
      Project.should_receive(:find_with_namespace).with(project.path_with_namespace).and_return(project)
      PostReceive.perform(pwd(project), 'sha-old', 'sha-new', 'refs/heads/master', key_id)
    end

    it "does not run if the author is not in the project" do
      Key.stub(find_by_identifier: nil)

      project.should_not_receive(:observe_push)
      project.should_not_receive(:execute_hooks)

      PostReceive.perform(pwd(project), 'sha-old', 'sha-new', 'refs/heads/master', key_id).should be_false
    end

    it "asks the project to trigger all hooks" do
      Project.stub(find_with_namespace: project)
      project.should_receive(:execute_hooks)
      project.should_receive(:execute_services)
      project.should_receive(:update_merge_requests)
      project.should_receive(:observe_push)

      PostReceive.perform(pwd(project), 'sha-old', 'sha-new', 'refs/heads/master', key_id)
    end
  end

  def pwd(project)
    File.join(Gitlab.config.gitolite.repos_path, project.path_with_namespace)
  end
end
