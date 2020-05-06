# frozen_string_literal: true

RSpec.shared_examples 'moves repository to another storage' do |repository_type|
  let(:project_repository_double) { double(:repository) }
  let!(:project_repository_checksum) { project.repository.checksum }

  let(:repository_double) { double(:repository) }
  let(:repository_checksum) { repository.checksum }

  before do
    # Default stub for non-specified params
    allow(Gitlab::Git::Repository).to receive(:new).and_call_original

    allow(Gitlab::Git::Repository).to receive(:new)
      .with('test_second_storage', project.repository.raw.relative_path, project.repository.gl_repository, project.repository.full_path)
      .and_return(project_repository_double)

    allow(Gitlab::Git::Repository).to receive(:new)
      .with('test_second_storage', repository.raw.relative_path, repository.gl_repository, repository.full_path)
      .and_return(repository_double)
  end

  context 'when the move succeeds', :clean_gitlab_redis_shared_state do
    before do
      allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
      allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('test_second_storage').and_return(SecureRandom.uuid)

      allow(project_repository_double).to receive(:create_repository)
        .and_return(true)
      allow(project_repository_double).to receive(:replicate)
        .with(project.repository.raw)
      allow(project_repository_double).to receive(:checksum)
        .and_return(project_repository_checksum)

      allow(repository_double).to receive(:create_repository)
        .and_return(true)
      allow(repository_double).to receive(:replicate)
        .with(repository.raw)
      allow(repository_double).to receive(:checksum)
        .and_return(repository_checksum)
    end

    it "moves the project and its #{repository_type} repository to the new storage and unmarks the repository as read only" do
      old_project_repository_path = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
        project.repository.path_to_repo
      end

      old_repository_path = repository.full_path

      result = subject.execute

      expect(result).to be_success
      expect(project).not_to be_repository_read_only
      expect(project.repository_storage).to eq('test_second_storage')
      expect(gitlab_shell.repository_exists?('default', old_project_repository_path)).to be(false)
      expect(gitlab_shell.repository_exists?('default', old_repository_path)).to be(false)
    end

    context ':repack_after_shard_migration feature flag disabled' do
      before do
        stub_feature_flags(repack_after_shard_migration: false)
      end

      it 'does not enqueue a GC run' do
        expect { subject.execute }
          .not_to change(GitGarbageCollectWorker.jobs, :count)
      end
    end

    context ':repack_after_shard_migration feature flag enabled' do
      before do
        stub_feature_flags(repack_after_shard_migration: true)
      end

      it 'does not enqueue a GC run if housekeeping is disabled' do
        stub_application_setting(housekeeping_enabled: false)

        expect { subject.execute }
          .not_to change(GitGarbageCollectWorker.jobs, :count)
      end

      it 'enqueues a GC run' do
        expect { subject.execute }
          .to change(GitGarbageCollectWorker.jobs, :count).by(1)
      end
    end
  end

  context 'when the filesystems are the same' do
    let(:destination) { project.repository_storage }

    it 'bails out and does nothing' do
      result = subject.execute

      expect(result).to be_error
      expect(result.message).to match(/SameFilesystemError/)
    end
  end

  context "when the move of the #{repository_type} repository fails" do
    it 'unmarks the repository as read-only without updating the repository storage' do
      allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
      allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('test_second_storage').and_return(SecureRandom.uuid)
      allow(project_repository_double).to receive(:create_repository)
        .and_return(true)
      allow(project_repository_double).to receive(:replicate)
        .with(project.repository.raw)
      allow(project_repository_double).to receive(:checksum)
        .and_return(project_repository_checksum)

      allow(repository_double).to receive(:create_repository)
        .and_return(true)
      allow(repository_double).to receive(:replicate)
        .with(repository.raw)
        .and_raise(Gitlab::Git::CommandError)

      expect(GitlabShellWorker).not_to receive(:perform_async)

      result = subject.execute

      expect(result).to be_error
      expect(project).not_to be_repository_read_only
      expect(project.repository_storage).to eq('default')
    end
  end

  context "when the checksum of the #{repository_type} repository does not match" do
    it 'unmarks the repository as read-only without updating the repository storage' do
      allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
      allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('test_second_storage').and_return(SecureRandom.uuid)
      allow(project_repository_double).to receive(:create_repository)
        .and_return(true)
      allow(project_repository_double).to receive(:replicate)
        .with(project.repository.raw)
      allow(project_repository_double).to receive(:checksum)
        .and_return(project_repository_checksum)

      allow(repository_double).to receive(:create_repository)
        .and_return(true)
      allow(repository_double).to receive(:replicate)
        .with(repository.raw)
      allow(repository_double).to receive(:checksum)
        .and_return('not matching checksum')

      expect(GitlabShellWorker).not_to receive(:perform_async)

      result = subject.execute

      expect(result).to be_error
      expect(project).not_to be_repository_read_only
      expect(project.repository_storage).to eq('default')
    end
  end
end
