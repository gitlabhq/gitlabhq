require 'spec_helper'

describe PostReceive do
  let(:changes) { "123456 789012 refs/heads/tést\n654321 210987 refs/tags/tag" }
  let(:wrongly_encoded_changes) { changes.encode("ISO-8859-1").force_encoding("UTF-8") }
  let(:base64_changes) { Base64.encode64(wrongly_encoded_changes) }
  let(:gl_repository) { "project-#{project.id}" }
  let(:key) { create(:key, user: project.owner) }
  let(:key_id) { key.shell_id }

  let(:project) do
    create(:project, :repository, auto_cancel_pending_pipelines: 'disabled')
  end

  before do
    allow_any_instance_of(Gitlab::GitPostReceive).to receive(:identify).and_return(project.owner)
  end

  subject { described_class.new.perform(gl_repository, key_id, base64_changes) }

  context "as a sidekiq worker" do
    it "responds to #perform" do
      expect(described_class.new).to respond_to(:perform)
    end
  end

  context 'with a non-existing project' do
    let(:gl_repository) { "project-123456789" }
    let(:error_message) do
      "Triggered hook for non-existing project with gl_repository \"#{gl_repository}\""
    end

    it "returns false and logs an error" do
      expect(Gitlab::GitLogger).to receive(:error).with("POST-RECEIVE: #{error_message}")
      expect(subject).to be(false)
    end
  end

  describe "#process_project_changes" do
    let(:push_data) do
      [
        [push_service, project.id, project.owner.id, '123456', '789012', ref]
      ]
    end

    context "branches" do
      let(:changes) { "123456 789012 refs/heads/tést" }
      let(:push_service) { 'GitPushService' }
      let(:ref) { 'refs/heads/tést' }

      it "calls GitTagPushService" do
        expect(PostReceivePushWorker).to receive(:bulk_perform_and_wait).with(push_data, anything).and_call_original
        expect_any_instance_of(GitPushService).to receive(:execute).and_return(true)
        expect_any_instance_of(GitTagPushService).not_to receive(:execute)

        subject
      end
    end

    context "tags" do
      let(:changes) { "123456 789012 refs/tags/tag" }
      let(:push_service) { 'GitTagPushService' }
      let(:ref) { 'refs/tags/tag' }

      it "calls GitTagPushService" do
        expect(PostReceivePushWorker).to receive(:bulk_perform_and_wait).with(push_data, anything).and_call_original
        expect_any_instance_of(GitPushService).not_to receive(:execute)
        expect_any_instance_of(GitTagPushService).to receive(:execute).and_return(true)

        subject
      end
    end

    context "merge-requests" do
      let(:changes) { "123456 789012 refs/merge-requests/123" }

      it "does not call any of the services" do
        expect(PostReceivePushWorker).not_to receive(:bulk_perform_and_wait)
        expect_any_instance_of(GitPushService).not_to receive(:execute)
        expect_any_instance_of(GitTagPushService).not_to receive(:execute)

        subject
      end
    end

    context 'sets the timeout based on the number of push jobs' do
      let(:changes) { "123456 789012 refs/heads/feature\n654321 210987 refs/tags/tag\n654322 310987 refs/tags/tag1" }

      it do
        expect(PostReceivePushWorker)
          .to receive(:bulk_perform_and_wait)
                .with(anything, timeout: 3 * PostReceivePushWorker::DEFAULT_TIMEOUT)

        subject
      end
    end

    context "gitlab-ci.yml" do
      let(:changes) { "123456 789012 refs/heads/feature\n654321 210987 refs/tags/tag" }

      context "creates a Ci::Pipeline for every change" do
        before do
          stub_ci_pipeline_to_return_yaml_file

          allow_any_instance_of(Project)
            .to receive(:commit)
            .and_return(project.commit)

          allow_any_instance_of(Repository)
            .to receive(:branch_exists?)
            .and_return(true)
        end

        it { expect { subject }.to change { Ci::Pipeline.count }.by(2) }
      end

      context "does not create a Ci::Pipeline" do
        before do
          stub_ci_pipeline_yaml_file(nil)
        end

        it { expect { subject }.not_to change { Ci::Pipeline.count } }
      end
    end

    context 'after project changes hooks' do
      let(:changes) { '123456 789012 refs/heads/tést' }
      let(:fake_hook_data) { Hash.new(event_name: 'repository_update') }

      before do
        allow_any_instance_of(Gitlab::DataBuilder::Repository).to receive(:update).and_return(fake_hook_data)
        # silence hooks so we can isolate
        allow_any_instance_of(Key).to receive(:post_create_hook).and_return(true)
        allow_any_instance_of(GitPushService).to receive(:execute).and_return(true)
      end

      it 'calls SystemHooksService' do
        expect_any_instance_of(SystemHooksService).to receive(:execute_hooks).with(fake_hook_data, :repository_update_hooks).and_return(true)

        subject
      end
    end
  end

  describe '#process_wiki_changes' do
    let(:gl_repository) { "wiki-#{project.id}" }

    it 'updates project activity' do
      subject

      expect { project.reload }
        .to change(project, :last_activity_at)
        .and change(project, :last_repository_updated_at)
    end
  end

  context "webhook" do
    it "fetches the correct project" do
      expect(Project).to receive(:find_by).with(id: project.id.to_s)

      subject
    end

    it "does not run if the author is not in the project" do
      allow_any_instance_of(Gitlab::GitPostReceive)
        .to receive(:identify).and_return(nil)

      expect(project).not_to receive(:execute_hooks)

      expect(subject).to be_falsey
    end

    it "asks the project to trigger all hooks" do
      allow(Project).to receive(:find_by).and_return(project)

      expect(project).to receive(:execute_hooks).twice
      expect(project).to receive(:execute_services).twice

      subject
    end

    it "enqueues a UpdateMergeRequestsWorker job" do
      allow(Project).to receive(:find_by).and_return(project)

      expect(UpdateMergeRequestsWorker).to receive(:perform_async).with(project.id, project.owner.id, any_args)

      subject
    end
  end
end
