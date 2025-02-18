# frozen_string_literal: true

RSpec.shared_examples 'moves repository to another storage' do |repository_type|
  let(:project_repository_double_destination) { double(:repository) }
  let(:project_repository_double_source) { double(:repository) }
  let!(:project_repository_checksum) { project.repository.checksum }

  let(:repository_double) { double(:repository) }
  let(:original_repository_double) { double(:repository) }
  let(:repository_checksum) { repository.checksum }

  before do
    # Default stub for non-specified params
    allow(Gitlab::Git::Repository).to receive(:new).and_call_original

    allow(Gitlab::Git::Repository).to receive(:new)
      .with('test_second_storage', project.repository.raw.relative_path, project.repository.gl_repository, project.repository.full_path)
      .and_return(project_repository_double_destination)
    allow(Gitlab::Git::Repository).to receive(:new)
      .with('default', project.repository.raw.relative_path, nil, nil)
      .and_return(project_repository_double_source)

    allow(Gitlab::Git::Repository).to receive(:new)
      .with('test_second_storage', repository.raw.relative_path, repository.gl_repository, repository.full_path)
      .and_return(repository_double)
    allow(Gitlab::Git::Repository).to receive(:new)
      .with('default', repository.raw.relative_path, nil, nil)
      .and_return(original_repository_double)
  end

  context 'when the move succeeds', :clean_gitlab_redis_shared_state do
    before do
      allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
      allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('test_second_storage').and_return(SecureRandom.uuid)

      allow(project_repository_double_destination).to receive(:replicate)
        .with(project.repository.raw, partition_hint: "")
      allow(project_repository_double_destination).to receive(:checksum)
        .and_return(project_repository_checksum)

      allow(repository_double).to receive(:replicate)
        .with(repository.raw, partition_hint: "")
      allow(repository_double).to receive(:checksum)
        .and_return(repository_checksum)

      expect(project_repository_double_source).to receive(:remove)
      expect(original_repository_double).to receive(:remove)
    end

    it "moves the project and its #{repository_type} repository to the new storage and unmarks the repository as read-only" do
      result = subject.execute
      project.reload

      expect(result).to be_success
      expect(project).not_to be_repository_read_only
      expect(project.repository_storage).to eq('test_second_storage')
    end
  end

  context 'when the filesystems are the same' do
    before do
      expect(Gitlab::GitalyClient).to receive(:filesystem_id).twice.and_return(SecureRandom.uuid)
    end

    it 'updates the database without trying to move the repository', :aggregate_failures do
      result = subject.execute
      project.reload

      expect(result).to be_success
      expect(project).not_to be_repository_read_only
      expect(project.repository_storage).to eq('test_second_storage')
      expect(project.project_repository.shard_name).to eq('test_second_storage')
    end
  end

  context "when the move of the #{repository_type} repository fails" do
    it 'unmarks the repository as read-only without updating the repository storage' do
      allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
      allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('test_second_storage').and_return(SecureRandom.uuid)
      expect(project_repository_double_destination).to receive(:replicate)
        .with(project.repository.raw, partition_hint: "")
      expect(project_repository_double_destination).to receive(:checksum)
        .and_return(project_repository_checksum)

      expect(repository_double).to receive(:replicate)
        .with(repository.raw, partition_hint: "")
        .and_raise(Gitlab::Git::CommandError)
      expect(repository_double).to receive(:remove)

      expect do
        subject.execute
      end.to raise_error(Gitlab::Git::CommandError)

      expect(project).not_to be_repository_read_only
      expect(project.repository_storage).to eq('default')
      expect(repository_storage_move).to be_failed
    end
  end

  context "when the cleanup of the #{repository_type} repository fails" do
    it 'sets the correct state' do
      allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
      allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('test_second_storage').and_return(SecureRandom.uuid)
      allow(project_repository_double_destination).to receive(:replicate)
        .with(project.repository.raw, partition_hint: "")
      allow(project_repository_double_destination).to receive(:checksum)
        .and_return(project_repository_checksum)
      allow(project_repository_double_source).to receive(:remove)
      allow(repository_double).to receive(:replicate)
        .with(repository.raw, partition_hint: "")
      allow(repository_double).to receive(:checksum)
        .and_return(repository_checksum)

      expect(original_repository_double).to receive(:remove)
        .and_raise(Gitlab::Git::CommandError)

      expect do
        subject.execute
      end.to raise_error(Gitlab::Git::CommandError)

      expect(repository_storage_move).to be_cleanup_failed
    end
  end

  context "when the checksum of the #{repository_type} repository does not match" do
    it 'unmarks the repository as read-only without updating the repository storage' do
      allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
      allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('test_second_storage').and_return(SecureRandom.uuid)
      allow(project_repository_double_destination).to receive(:replicate)
        .with(project.repository.raw, partition_hint: "")
      allow(project_repository_double_destination).to receive(:checksum)
        .and_return(project_repository_checksum)

      expect(repository_double).to receive(:replicate)
        .with(repository.raw, partition_hint: "")
      expect(repository_double).to receive(:checksum)
        .and_return('not matching checksum')
      expect(repository_double).to receive(:remove)

      expect do
        subject.execute
      end.to raise_error(::Repositories::ReplicateService::Error, /Failed to verify \w+ repository checksum from \w+ to not matching checksum/)

      expect(project).not_to be_repository_read_only
      expect(project.repository_storage).to eq('default')
    end
  end
end
