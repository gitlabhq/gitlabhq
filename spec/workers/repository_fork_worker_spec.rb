# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RepositoryForkWorker, feature_category: :source_code_management do
  include ProjectForksHelper

  describe 'modules' do
    it 'includes ProjectImportOptions' do
      expect(described_class).to include_module(ProjectImportOptions)
    end
  end

  describe "#perform" do
    let(:project) { create(:project, :public, :repository) }
    let(:forked_project) { create(:project, :repository, :import_scheduled) }

    before do
      fork_project(project, forked_project.creator, target_project: forked_project, repository: true)
    end

    shared_examples 'RepositoryForkWorker performing' do |branch|
      def expect_fork_repository(success:, branch:)
        allow(::Gitlab::GitalyClient::RepositoryService).to receive(:new).and_call_original
        expect_next_instance_of(::Gitlab::GitalyClient::RepositoryService, forked_project.repository.raw) do |svc|
          exp = expect(svc).to receive(:fork_repository).with(project.repository.raw, branch)

          if success
            exp.and_return(true)
          else
            exp.and_raise(GRPC::BadStatus, 'Fork failed in tests')
          end
        end
      end

      describe 'when a worker was reset without cleanup' do
        let(:jid) { '12345678' }

        it 'creates a new repository from a fork' do
          allow(subject).to receive(:jid).and_return(jid)

          expect_fork_repository(success: true, branch: branch)

          perform!
        end
      end

      it "creates a new repository from a fork" do
        expect_fork_repository(success: true, branch: branch)

        perform!
      end

      it 'protects the default branch' do
        expect_fork_repository(success: true, branch: branch)

        perform!

        expect(forked_project.protected_branches.first.name).to eq(forked_project.default_branch)
      end

      it 'flushes various caches' do
        expect_fork_repository(success: true, branch: branch)

        # Works around https://github.com/rspec/rspec-mocks/issues/910
        expect(Project).to receive(:find).with(forked_project.id).and_return(forked_project)
        expect(forked_project.repository).to receive(:expire_emptiness_caches)
          .and_call_original
        expect(forked_project.repository).to receive(:expire_exists_cache)
          .and_call_original
        expect(forked_project.wiki.repository).to receive(:expire_emptiness_caches)
          .and_call_original
        expect(forked_project.wiki.repository).to receive(:expire_exists_cache)
          .and_call_original

        perform!
      end

      it 'handles bad fork' do
        error_message = "Unable to fork project #{forked_project.id} for repository #{project.disk_path} -> #{forked_project.disk_path}: Failed to create fork repository"

        expect_fork_repository(success: false, branch: branch)

        expect { perform! }.to raise_error(StandardError, error_message)
      end

      it 'calls Projects::LfsPointers::LfsLinkService#execute with OIDs of source project LFS objects' do
        expect_fork_repository(success: true, branch: branch)
        expect_next_instance_of(Projects::LfsPointers::LfsLinkService) do |service|
          expect(service).to receive(:execute).with(project.lfs_objects_oids)
        end

        perform!
      end

      it "handles LFS objects link failure" do
        error_message = "Unable to fork project #{forked_project.id} for repository #{project.disk_path} -> #{forked_project.disk_path}: Source project has too many LFS objects"

        expect_fork_repository(success: true, branch: branch)
        expect_next_instance_of(Projects::LfsPointers::LfsLinkService) do |service|
          expect(service).to receive(:execute).and_raise(Projects::LfsPointers::LfsLinkService::TooManyOidsError)
        end

        expect { perform! }.to raise_error(StandardError, error_message)
      end
    end

    context 'only project ID passed' do
      def perform!
        subject.perform(forked_project.id)
      end

      it_behaves_like 'RepositoryForkWorker performing'
    end

    context 'when a specific branch is requested' do
      def perform!
        forked_project.create_import_data(data: { fork_branch: 'wip' })

        subject.perform(forked_project.id)
      end

      it_behaves_like 'RepositoryForkWorker performing', 'wip'
    end

    context 'project ID, storage and repo paths passed' do
      def perform!
        subject.perform(forked_project.id, 'repos/path', project.disk_path)
      end

      it_behaves_like 'RepositoryForkWorker performing'
    end
  end
end
