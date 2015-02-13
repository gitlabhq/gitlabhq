require 'spec_helper'

describe PostReceive do
  context "as a resque worker" do
    it "reponds to #perform" do
      expect(PostReceive.new).to respond_to(:perform)
    end
  end

  context "web hook" do
    let(:project) { create(:project) }
    let(:key) { create(:key, user: project.owner) }
    let(:key_id) { key.shell_id }

    it "fetches the correct project" do
      expect(Project).to receive(:find_with_namespace).with(project.path_with_namespace).and_return(project)
      PostReceive.new.perform(pwd(project), key_id, changes)
    end

    it "does not run if the author is not in the project" do
      allow(Key).to receive(:find_by).with(hash_including(id: anything())) { nil }

      expect(project).not_to receive(:execute_hooks)

      expect(PostReceive.new.perform(pwd(project), key_id, changes)).to be_falsey
    end

    it "asks the project to trigger all hooks" do
      Project.stub(find_with_namespace: project)
      expect(project).to receive(:execute_hooks)
      expect(project).to receive(:execute_services)
      expect(project).to receive(:update_merge_requests)

      PostReceive.new.perform(pwd(project), key_id, changes)
    end
  end

  def pwd(project)
    File.join(Gitlab.config.gitlab_shell.repos_path, project.path_with_namespace)
  end

  def changes
    'd14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/master'
  end
end
