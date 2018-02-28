require 'spec_helper'

describe RepositoryForkWorker do
  let(:project) { create(:project, :repository, :import_scheduled) }
  let(:fork_project) { create(:project, :repository, forked_from_project: project) }
  let(:shell) { Gitlab::Shell.new }

  subject { described_class.new }

  before do
    allow(subject).to receive(:gitlab_shell).and_return(shell)
  end

  describe "#perform" do
    describe 'when a worker was reset without cleanup' do
      let(:jid) { '12345678' }
      let(:started_project) { create(:project, :repository, :import_started) }

      it 'creates a new repository from a fork' do
        allow(subject).to receive(:jid).and_return(jid)

        expect(shell).to receive(:fork_repository).with(
          '/test/path',
          project.full_path,
          project.repository_storage_path,
          fork_project.namespace.full_path
        ).and_return(true)

        subject.perform(
          project.id,
          '/test/path',
          project.full_path,
          fork_project.namespace.full_path)
      end
    end

    it "creates a new repository from a fork" do
      expect(shell).to receive(:fork_repository).with(
        '/test/path',
        project.full_path,
        project.repository_storage_path,
        fork_project.namespace.full_path
      ).and_return(true)

      subject.perform(
        project.id,
        '/test/path',
        project.full_path,
        fork_project.namespace.full_path)
    end

    it 'flushes various caches' do
      expect(shell).to receive(:fork_repository).with(
        '/test/path',
        project.full_path,
        project.repository_storage_path,
        fork_project.namespace.full_path
      ).and_return(true)

      expect_any_instance_of(Repository).to receive(:expire_emptiness_caches)
        .and_call_original

      expect_any_instance_of(Repository).to receive(:expire_exists_cache)
        .and_call_original

      subject.perform(project.id, '/test/path', project.full_path,
                      fork_project.namespace.full_path)
    end

    it "handles bad fork" do
      source_path = project.full_path
      target_path = fork_project.namespace.full_path
      error_message = "Unable to fork project #{project.id} for repository #{source_path} -> #{target_path}"

      expect(shell).to receive(:fork_repository).and_return(false)

      expect do
        subject.perform(project.id, '/test/path', source_path, target_path)
      end.to raise_error(RepositoryForkWorker::ForkError, error_message)
    end

    it 'handles unexpected error' do
      source_path = project.full_path
      target_path = fork_project.namespace.full_path

      allow_any_instance_of(Gitlab::Shell).to receive(:fork_repository).and_raise(RuntimeError)

      expect do
        subject.perform(project.id, '/test/path', source_path, target_path)
      end.to raise_error(RepositoryForkWorker::ForkError)
      expect(project.reload.import_status).to eq('failed')
    end
  end
end
