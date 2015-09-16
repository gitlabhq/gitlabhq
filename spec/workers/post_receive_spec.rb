require 'spec_helper'

describe PostReceive do
  let(:changes) { "123456 789012 refs/heads/tést\n654321 210987 refs/tags/tag" }
  let(:wrongly_encoded_changes) { changes.encode("ISO-8859-1").force_encoding("UTF-8") }
  let(:base64_changes) { Base64.encode64(wrongly_encoded_changes) }

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
      PostReceive.new.perform(pwd(project), key_id, base64_changes)
    end

    it "does not run if the author is not in the project" do
      allow(Key).to receive(:find_by).with(hash_including(id: anything())) { nil }

      expect(project).not_to receive(:execute_hooks)

      expect(PostReceive.new.perform(pwd(project), key_id, base64_changes)).to be_falsey
    end

    it "asks the project to trigger all hooks" do
      allow(Project).to receive(:find_with_namespace).and_return(project)
      expect(project).to receive(:execute_hooks).twice
      expect(project).to receive(:execute_services).twice
      expect(project).to receive(:update_merge_requests)

      PostReceive.new.perform(pwd(project), key_id, base64_changes)
    end
  end

  def pwd(project)
    File.join(Gitlab.config.gitlab_shell.repos_path, project.path_with_namespace)
  end
end
