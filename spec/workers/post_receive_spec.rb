require 'spec_helper'

describe PostReceive do
  let(:changes) { "123456 789012 refs/heads/tést\n654321 210987 refs/tags/tag" }
  let(:wrongly_encoded_changes) { changes.encode("ISO-8859-1").force_encoding("UTF-8") }
  let(:base64_changes) { Base64.encode64(wrongly_encoded_changes) }
  let(:project) { create(:project, :repository) }
  let(:project_identifier) { "project-#{project.id}" }
  let(:key) { create(:key, user: project.owner) }
  let(:key_id) { key.shell_id }

  context "as a sidekiq worker" do
    it "reponds to #perform" do
      expect(described_class.new).to respond_to(:perform)
    end
  end

  context 'with a non-existing project' do
    let(:project_identifier) { "project-123456789" }
    let(:error_message) do
      "Triggered hook for non-existing project with identifier \"#{project_identifier}\""
    end

    it "returns false and logs an error" do
      expect(Gitlab::GitLogger).to receive(:error).with("POST-RECEIVE: #{error_message}")
      expect(described_class.new.perform(project_identifier, key_id, base64_changes)).to be(false)
    end
  end

  context "with an absolute path as the project identifier" do
    it "searches the project by full path" do
      expect(Project).to receive(:find_by_full_path).with(project.full_path).and_call_original

      described_class.new.perform(pwd(project), key_id, base64_changes)
    end
  end

  describe "#process_project_changes" do
    before do
      allow_any_instance_of(Gitlab::GitPostReceive).to receive(:identify).and_return(project.owner)
    end

    context "branches" do
      let(:changes) { "123456 789012 refs/heads/tést" }

      it "calls GitTagPushService" do
        expect_any_instance_of(GitPushService).to receive(:execute).and_return(true)
        expect_any_instance_of(GitTagPushService).not_to receive(:execute)
        described_class.new.perform(project_identifier, key_id, base64_changes)
      end
    end

    context "tags" do
      let(:changes) { "123456 789012 refs/tags/tag" }

      it "calls GitTagPushService" do
        expect_any_instance_of(GitPushService).not_to receive(:execute)
        expect_any_instance_of(GitTagPushService).to receive(:execute).and_return(true)
        described_class.new.perform(project_identifier, key_id, base64_changes)
      end
    end

    context "merge-requests" do
      let(:changes) { "123456 789012 refs/merge-requests/123" }

      it "does not call any of the services" do
        expect_any_instance_of(GitPushService).not_to receive(:execute)
        expect_any_instance_of(GitTagPushService).not_to receive(:execute)
        described_class.new.perform(project_identifier, key_id, base64_changes)
      end
    end

    context "gitlab-ci.yml" do
      subject { described_class.new.perform(project_identifier, key_id, base64_changes) }

      context "creates a Ci::Pipeline for every change" do
        before do
          allow_any_instance_of(Ci::CreatePipelineService).to receive(:commit) do
            OpenStruct.new(id: '123456')
          end
          allow_any_instance_of(Ci::CreatePipelineService).to receive(:branch?).and_return(true)
          stub_ci_pipeline_to_return_yaml_file
        end

        it { expect{ subject }.to change{ Ci::Pipeline.count }.by(2) }
      end

      context "does not create a Ci::Pipeline" do
        before { stub_ci_pipeline_yaml_file(nil) }

        it { expect{ subject }.not_to change{ Ci::Pipeline.count } }
      end
    end
  end

  describe '#process_repository_update' do
    let(:changes) {'123456 789012 refs/heads/tést'}
    let(:fake_hook_data) do
      { event_name: 'repository_update' }
    end

    before do
      allow_any_instance_of(Gitlab::GitPostReceive).to receive(:identify).and_return(project.owner)
      allow_any_instance_of(Gitlab::DataBuilder::Repository).to receive(:update).and_return(fake_hook_data)
      # silence hooks so we can isolate
      allow_any_instance_of(Key).to receive(:post_create_hook).and_return(true)
      allow(subject).to receive(:process_project_changes).and_return(true)
    end

    it 'calls SystemHooksService' do
      expect_any_instance_of(SystemHooksService).to receive(:execute_hooks).with(fake_hook_data, :repository_update_hooks).and_return(true)

      subject.perform(pwd(project), key_id, base64_changes)
    end
  end

  context "webhook" do
    it "fetches the correct project" do
      expect(Project).to receive(:find_by).with(id: project.id.to_s)
      described_class.new.perform(project_identifier, key_id, base64_changes)
    end

    it "triggers wiki index update" do
      expect(Project).to receive(:find_by_full_path).with("#{project.full_path}.wiki").and_return(nil)
      expect(Project).to receive(:find_by_full_path).with(project.full_path).and_return(project)
      stub_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
      expect_any_instance_of(ProjectWiki).to receive(:index_blobs)

      repo_path = "#{pwd(project)}.wiki"

      described_class.new.perform(repo_path, key_id, base64_changes)
    end

    it "does not run if the author is not in the project" do
      allow_any_instance_of(Gitlab::GitPostReceive).
        to receive(:identify_using_ssh_key).
        and_return(nil)

      expect(project).not_to receive(:execute_hooks)

      expect(described_class.new.perform(project_identifier, key_id, base64_changes)).to be_falsey
    end

    it "asks the project to trigger all hooks" do
      allow(Project).to receive(:find_by).and_return(project)
      expect(project).to receive(:execute_hooks).twice
      expect(project).to receive(:execute_services).twice

      described_class.new.perform(project_identifier, key_id, base64_changes)
    end

    it "enqueues a UpdateMergeRequestsWorker job" do
      allow(Project).to receive(:find_by).and_return(project)
      expect(UpdateMergeRequestsWorker).to receive(:perform_async).with(project.id, project.owner.id, any_args)

      described_class.new.perform(project_identifier, key_id, base64_changes)
    end
  end

  def pwd(project)
    File.join(Gitlab.config.repositories.storages.default['path'], project.path_with_namespace)
  end
end
