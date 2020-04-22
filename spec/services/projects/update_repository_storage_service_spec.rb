# frozen_string_literal: true

require 'spec_helper'

describe Projects::UpdateRepositoryStorageService do
  include Gitlab::ShellAdapter

  subject { described_class.new(project) }

  describe "#execute" do
    let(:time) { Time.now }

    before do
      allow(Time).to receive(:now).and_return(time)
      allow(Gitlab.config.repositories.storages).to receive(:keys).and_return(%w[default test_second_storage])
    end

    context 'without wiki and design repository' do
      let(:project) { create(:project, :repository, repository_read_only: true, wiki_enabled: false) }
      let!(:checksum) { project.repository.checksum }
      let(:project_repository_double) { double(:repository) }

      before do
        allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
        allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('test_second_storage').and_return(SecureRandom.uuid)
        allow(Gitlab::Git::Repository).to receive(:new).and_call_original
        allow(Gitlab::Git::Repository).to receive(:new)
          .with('test_second_storage', project.repository.raw.relative_path, project.repository.gl_repository, project.repository.full_path)
          .and_return(project_repository_double)
      end

      context 'when the move succeeds' do
        it 'moves the repository to the new storage and unmarks the repository as read only' do
          old_path = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
            project.repository.path_to_repo
          end

          expect(project_repository_double).to receive(:create_repository)
            .and_return(true)
          expect(project_repository_double).to receive(:replicate)
            .with(project.repository.raw)
          expect(project_repository_double).to receive(:checksum)
            .and_return(checksum)

          result = subject.execute('test_second_storage')

          expect(result[:status]).to eq(:success)
          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('test_second_storage')
          expect(gitlab_shell.repository_exists?('default', old_path)).to be(false)
          expect(project.project_repository.shard_name).to eq('test_second_storage')
        end
      end

      context 'when the filesystems are the same' do
        it 'bails out and does nothing' do
          result = subject.execute(project.repository_storage)

          expect(result[:status]).to eq(:error)
          expect(result[:message]).to match(/SameFilesystemError/)
        end
      end

      context 'when the move fails' do
        it 'unmarks the repository as read-only without updating the repository storage' do
          allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
          allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('test_second_storage').and_return(SecureRandom.uuid)

          expect(project_repository_double).to receive(:create_repository)
            .and_return(true)
          expect(project_repository_double).to receive(:replicate)
            .with(project.repository.raw)
            .and_raise(Gitlab::Git::CommandError)
          expect(GitlabShellWorker).not_to receive(:perform_async)

          result = subject.execute('test_second_storage')

          expect(result[:status]).to eq(:error)
          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('default')
        end
      end

      context 'when the checksum does not match' do
        it 'unmarks the repository as read-only without updating the repository storage' do
          allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
          allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('test_second_storage').and_return(SecureRandom.uuid)

          expect(project_repository_double).to receive(:create_repository)
            .and_return(true)
          expect(project_repository_double).to receive(:replicate)
            .with(project.repository.raw)
          expect(project_repository_double).to receive(:checksum)
            .and_return('not matching checksum')
          expect(GitlabShellWorker).not_to receive(:perform_async)

          result = subject.execute('test_second_storage')

          expect(result[:status]).to eq(:error)
          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('default')
        end
      end

      context 'when a object pool was joined' do
        let!(:pool) { create(:pool_repository, :ready, source_project: project) }

        it 'leaves the pool' do
          allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
          allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('test_second_storage').and_return(SecureRandom.uuid)

          expect(project_repository_double).to receive(:create_repository)
            .and_return(true)
          expect(project_repository_double).to receive(:replicate)
            .with(project.repository.raw)
          expect(project_repository_double).to receive(:checksum)
            .and_return(checksum)

          result = subject.execute('test_second_storage')

          expect(result[:status]).to eq(:success)
          expect(project.repository_storage).to eq('test_second_storage')
          expect(project.reload_pool_repository).to be_nil
        end
      end
    end

    context 'with wiki repository' do
      include_examples 'moves repository to another storage', 'wiki' do
        let(:project) { create(:project, :repository, repository_read_only: true, wiki_enabled: true) }
        let(:repository) { project.wiki.repository }

        before do
          project.create_wiki
        end
      end
    end
  end
end
