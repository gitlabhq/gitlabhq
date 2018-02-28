require 'spec_helper'

describe RepositoryForkWorker do
  let(:project) { create(:project, :repository) }
  let(:fork_project) { create(:project, :repository, :import_scheduled, forked_from_project: project) }
  let(:shell) { Gitlab::Shell.new }

  subject { described_class.new }

  before do
    allow(subject).to receive(:gitlab_shell).and_return(shell)
  end

  describe "#perform" do
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

    it 'flushes various caches' do
      expect_fork_repository.and_return(true)

      expect_any_instance_of(Repository).to receive(:expire_emptiness_caches)
        .and_call_original

      expect_any_instance_of(Repository).to receive(:expire_exists_cache)
        .and_call_original

      perform!
    end

    it "handles bad fork" do
      error_message = "Unable to fork project #{fork_project.id} for repository #{project.full_path} -> #{fork_project.full_path}"

      expect_fork_repository.and_return(false)

      expect { perform! }.to raise_error(RepositoryForkWorker::ForkError, error_message)
    end

    it 'handles unexpected error' do
      expect_fork_repository.and_raise(RuntimeError)

      expect { perform! }.to raise_error(RepositoryForkWorker::ForkError)
      expect(fork_project.reload.import_status).to eq('failed')
    end
  end
end
