require 'spec_helper'

describe RepositoryForkWorker do
  describe 'modules' do
    it 'includes ProjectImportOptions' do
      expect(described_class).to include_module(ProjectImportOptions)
    end
  end

  describe "#perform" do
    let(:project) { create(:project, :repository) }
    let(:fork_project) { create(:project, :repository, :import_scheduled, forked_from_project: project) }
    let(:shell) { Gitlab::Shell.new }

    before do
      allow(subject).to receive(:gitlab_shell).and_return(shell)
    end

    def perform!
      subject.perform(fork_project.id, '/test/path', project.disk_path)
    end

    def expect_fork_repository
      expect(shell).to receive(:fork_repository).with(
        '/test/path',
        project.disk_path,
        fork_project.repository_storage_path,
        fork_project.disk_path
      )
    end

    describe 'when a worker was reset without cleanup' do
      let(:jid) { '12345678' }

      it 'creates a new repository from a fork' do
        allow(subject).to receive(:jid).and_return(jid)

        expect_fork_repository.and_return(true)

        perform!
      end
    end

    it "creates a new repository from a fork" do
      expect_fork_repository.and_return(true)

      perform!
    end

    it 'protects the default branch' do
      expect_fork_repository.and_return(true)

      perform!

      expect(fork_project.protected_branches.first.name).to eq(fork_project.default_branch)
    end

    it 'flushes various caches' do
      expect_fork_repository.and_return(true)

      expect_any_instance_of(Repository).to receive(:expire_emptiness_caches)
        .and_call_original

      expect_any_instance_of(Repository).to receive(:expire_exists_cache)
        .and_call_original

      perform!
    end

    it "handles bad fork" do
      error_message = "Unable to fork project #{fork_project.id} for repository #{project.disk_path} -> #{fork_project.disk_path}"

      expect_fork_repository.and_return(false)

      expect { perform! }.to raise_error(StandardError, error_message)
    end
  end
end
