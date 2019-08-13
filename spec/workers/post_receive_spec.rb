# frozen_string_literal: true

require 'spec_helper'

describe PostReceive do
  let(:changes) { "123456 789012 refs/heads/tést\n654321 210987 refs/tags/tag" }
  let(:wrongly_encoded_changes) { changes.encode("ISO-8859-1").force_encoding("UTF-8") }
  let(:base64_changes) { Base64.encode64(wrongly_encoded_changes) }
  let(:gl_repository) { "project-#{project.id}" }
  let(:key) { create(:key, user: project.owner) }
  let!(:key_id) { key.shell_id }

  let(:project) do
    create(:project, :repository, auto_cancel_pending_pipelines: 'disabled')
  end

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
      expect(described_class.new.perform(gl_repository, key_id, base64_changes)).to be(false)
    end
  end

  describe "#process_project_changes" do
    context 'empty changes' do
      it "does not call any PushService but runs after project hooks" do
        expect(Git::BranchPushService).not_to receive(:new)
        expect(Git::TagPushService).not_to receive(:new)
        expect_next_instance_of(SystemHooksService) { |service| expect(service).to receive(:execute_hooks) }

        described_class.new.perform(gl_repository, key_id, "")
      end
    end

    context 'unidentified user' do
      let!(:key_id) { "" }

      it 'returns false' do
        expect(Git::BranchPushService).not_to receive(:new)
        expect(Git::TagPushService).not_to receive(:new)

        expect(described_class.new.perform(gl_repository, key_id, base64_changes)).to be false
      end
    end

    context 'with changes' do
      before do
        allow_any_instance_of(Gitlab::GitPostReceive).to receive(:identify).and_return(project.owner)
        allow(Gitlab::GlRepository).to receive(:parse).and_return([project, Gitlab::GlRepository::PROJECT])
      end

      context "branches" do
        let(:changes) do
          <<~EOF
            '123456 789012 refs/heads/tést1'
            '123456 789012 refs/heads/tést2'
          EOF
        end

        it 'expires the branches cache' do
          expect(project.repository).to receive(:expire_branches_cache).once

          described_class.new.perform(gl_repository, key_id, base64_changes)
        end

        it 'calls Git::BranchPushService' do
          expect_any_instance_of(Git::BranchPushService) do |service|
            expect(service).to receive(:execute).and_return(true)
          end

          expect(Git::TagPushService).not_to receive(:new)

          described_class.new.perform(gl_repository, key_id, base64_changes)
        end
      end

      context 'tags' do
        let(:changes) { '123456 789012 refs/tags/tag' }

        it 'does not expire branches cache' do
          expect(project.repository).not_to receive(:expire_branches_cache)

          described_class.new.perform(gl_repository, key_id, base64_changes)
        end

        it 'calls Git::TagPushService' do
          expect_next_instance_of(Git::TagPushService) do |service|
            expect(service).to receive(:execute).and_return(true)
          end

          expect(Git::BranchPushService).not_to receive(:new)

          described_class.new.perform(gl_repository, key_id, base64_changes)
        end
      end

      context "merge-requests" do
        let(:changes) { "123456 789012 refs/merge-requests/123" }

        it "does not call any of the services" do
          expect(Git::BranchPushService).not_to receive(:new)
          expect(Git::TagPushService).not_to receive(:new)

          described_class.new.perform(gl_repository, key_id, base64_changes)
        end
      end

      context "gitlab-ci.yml" do
        let(:changes) do
          <<-EOF.strip_heredoc
            123456 789012 refs/heads/feature
            654321 210987 refs/tags/tag
            123456 789012 refs/heads/feature2
            123458 789013 refs/heads/feature3
            123459 789015 refs/heads/feature4
          EOF
        end

        let(:changes_count) { changes.lines.count }

        subject { described_class.new.perform(gl_repository, key_id, base64_changes) }

        context "with valid .gitlab-ci.yml" do
          before do
            stub_ci_pipeline_to_return_yaml_file

            allow_any_instance_of(Project)
              .to receive(:commit)
              .and_return(project.commit)

            allow_any_instance_of(Repository)
              .to receive(:branch_exists?)
              .and_return(true)
          end

          context 'when git_push_create_all_pipelines is disabled' do
            before do
              stub_feature_flags(git_push_create_all_pipelines: false)
            end

            it "creates pipeline for branches and tags" do
              subject

              expect(Ci::Pipeline.pluck(:ref)).to contain_exactly("feature", "tag", "feature2", "feature3")
            end

            it "creates exactly #{described_class::PIPELINE_PROCESS_LIMIT} pipelines" do
              expect(changes_count).to be > described_class::PIPELINE_PROCESS_LIMIT

              expect { subject }.to change { Ci::Pipeline.count }.by(described_class::PIPELINE_PROCESS_LIMIT)
            end
          end

          context 'when git_push_create_all_pipelines is enabled' do
            before do
              stub_feature_flags(git_push_create_all_pipelines: true)
            end

            it "creates all pipelines" do
              expect { subject }.to change { Ci::Pipeline.count }.by(changes_count)
            end
          end
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
          expect_next_instance_of(Git::BranchPushService) do |service|
            expect(service).to receive(:execute).and_return(true)
          end
        end

        it 'calls SystemHooksService' do
          expect_any_instance_of(SystemHooksService).to receive(:execute_hooks).with(fake_hook_data, :repository_update_hooks).and_return(true)

          described_class.new.perform(gl_repository, key_id, base64_changes)
        end
      end
    end
  end

  describe '#process_wiki_changes' do
    let(:gl_repository) { "wiki-#{project.id}" }

    it 'updates project activity' do
      # Force Project#set_timestamps_for_create to initialize timestamps
      project

      # MySQL drops milliseconds in the timestamps, so advance at least
      # a second to ensure we see changes.
      Timecop.freeze(1.second.from_now) do
        expect do
          described_class.new.perform(gl_repository, key_id, base64_changes)
          project.reload
        end.to change(project, :last_activity_at)
           .and change(project, :last_repository_updated_at)
      end
    end
  end

  context "webhook" do
    it "fetches the correct project" do
      expect(Project).to receive(:find_by).with(id: project.id.to_s)
      described_class.new.perform(gl_repository, key_id, base64_changes)
    end

    it "does not run if the author is not in the project" do
      allow_any_instance_of(Gitlab::GitPostReceive)
        .to receive(:identify_using_ssh_key)
        .and_return(nil)

      expect(project).not_to receive(:execute_hooks)

      expect(described_class.new.perform(gl_repository, key_id, base64_changes)).to be_falsey
    end

    it "asks the project to trigger all hooks" do
      allow(Project).to receive(:find_by).and_return(project)

      expect(project).to receive(:execute_hooks).twice
      expect(project).to receive(:execute_services).twice

      described_class.new.perform(gl_repository, key_id, base64_changes)
    end

    it "enqueues a UpdateMergeRequestsWorker job" do
      allow(Project).to receive(:find_by).and_return(project)

      expect(UpdateMergeRequestsWorker).to receive(:perform_async).with(project.id, project.owner.id, any_args)

      described_class.new.perform(gl_repository, key_id, base64_changes)
    end
  end
end
