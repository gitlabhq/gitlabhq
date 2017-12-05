require 'spec_helper'

describe RepositoryForkWorker do
  describe 'modules' do
    it 'includes ProjectImportOptions' do
      expect(described_class).to include_module(ProjectImportOptions)
    end
  end

  shared_examples '#perform' do
    let(:project) { create(:project, :repository) }
    let(:fork_project) { create(:project, :repository, :import_scheduled, forked_from_project: project) }
    let(:shell) { Gitlab::Shell.new }

    before do
      allow(subject).to receive(:gitlab_shell).and_return(shell)

      subject.job_version = job_version
    end

    it 'supports the version' do
      expect(subject.support_job_version?).to be_truthy
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

        subject.perform(*args)
      end
    end

    it "creates a new repository from a fork" do
      expect_fork_repository.and_return(true)

      subject.perform(*args)
    end

    it 'flushes various caches' do
      expect_fork_repository.and_return(true)

      expect_any_instance_of(Repository).to receive(:expire_emptiness_caches)
        .and_call_original

      expect_any_instance_of(Repository).to receive(:expire_exists_cache)
        .and_call_original

      subject.perform(*args)
    end

    it "handles bad fork" do
      error_message = "Unable to fork project #{fork_project.id} for repository #{project.full_path} -> #{fork_project.full_path}"

      expect_fork_repository.and_return(false)

      expect { subject.perform(*args) }.to raise_error(StandardError, error_message)
    end
  end

  context 'job with version 0' do
    let(:job_version) { 0 }
    let(:args) { [fork_project.id, '/test/path', project.disk_path, project.namespace.full_path] }

    it_behaves_like '#perform'
  end

  context 'job with version 1' do
    let(:job_version) { 1 }
    let(:args) { [fork_project.id, '/test/path', project.disk_path] }

    it_behaves_like '#perform'
  end
end
