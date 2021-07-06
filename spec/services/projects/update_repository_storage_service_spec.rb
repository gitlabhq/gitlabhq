# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UpdateRepositoryStorageService do
  include Gitlab::ShellAdapter

  subject { described_class.new(repository_storage_move) }

  describe "#execute" do
    let(:time) { Time.current }

    before do
      allow(Time).to receive(:now).and_return(time)
      allow(Gitlab.config.repositories.storages).to receive(:keys).and_return(%w[default test_second_storage])
    end

    context 'without wiki and design repository' do
      let(:project) { create(:project, :repository, wiki_enabled: false) }
      let(:destination) { 'test_second_storage' }
      let(:repository_storage_move) { create(:project_repository_storage_move, :scheduled, container: project, destination_storage_name: destination) }
      let!(:checksum) { project.repository.checksum }
      let(:project_repository_double) { double(:repository) }
      let(:original_project_repository_double) { double(:repository) }

      before do
        allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
        allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('test_second_storage').and_return(SecureRandom.uuid)
        allow(Gitlab::Git::Repository).to receive(:new).and_call_original
        allow(Gitlab::Git::Repository).to receive(:new)
          .with('test_second_storage', project.repository.raw.relative_path, project.repository.gl_repository, project.repository.full_path)
          .and_return(project_repository_double)
        allow(Gitlab::Git::Repository).to receive(:new)
          .with('default', project.repository.raw.relative_path, nil, nil)
          .and_return(original_project_repository_double)
      end

      context 'when the move succeeds' do
        it 'moves the repository to the new storage and unmarks the repository as read-only' do
          old_path = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
            project.repository.path_to_repo
          end

          expect(project_repository_double).to receive(:replicate)
            .with(project.repository.raw)
          expect(project_repository_double).to receive(:checksum)
            .and_return(checksum)
          expect(original_project_repository_double).to receive(:remove)

          result = subject.execute
          project.reload

          expect(result).to be_success
          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('test_second_storage')
          expect(gitlab_shell.repository_exists?('default', old_path)).to be(false)
          expect(project.project_repository.shard_name).to eq('test_second_storage')
        end
      end

      context 'when the filesystems are the same' do
        before do
          expect(Gitlab::GitalyClient).to receive(:filesystem_id).twice.and_return(SecureRandom.uuid)
        end

        it 'updates the database without trying to move the repostory', :aggregate_failures do
          result = subject.execute
          project.reload

          expect(result).to be_success
          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('test_second_storage')
          expect(project.project_repository.shard_name).to eq('test_second_storage')
        end
      end

      context 'when the move fails' do
        it 'unmarks the repository as read-only without updating the repository storage' do
          allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
          allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('test_second_storage').and_return(SecureRandom.uuid)

          expect(project_repository_double).to receive(:replicate)
            .with(project.repository.raw)
            .and_raise(Gitlab::Git::CommandError)

          expect do
            subject.execute
          end.to raise_error(Gitlab::Git::CommandError)

          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('default')
          expect(repository_storage_move).to be_failed
        end
      end

      context 'when the cleanup fails' do
        it 'sets the correct state' do
          expect(project_repository_double).to receive(:replicate)
            .with(project.repository.raw)
          expect(project_repository_double).to receive(:checksum)
            .and_return(checksum)
          expect(original_project_repository_double).to receive(:remove)
            .and_raise(Gitlab::Git::CommandError)

          expect do
            subject.execute
          end.to raise_error(Gitlab::Git::CommandError)

          expect(repository_storage_move).to be_cleanup_failed
        end
      end

      context 'when the checksum does not match' do
        it 'unmarks the repository as read-only without updating the repository storage' do
          allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
          allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('test_second_storage').and_return(SecureRandom.uuid)

          expect(project_repository_double).to receive(:replicate)
            .with(project.repository.raw)
          expect(project_repository_double).to receive(:checksum)
            .and_return('not matching checksum')

          expect do
            subject.execute
          end.to raise_error(UpdateRepositoryStorageMethods::Error, /Failed to verify project repository checksum/)

          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('default')
        end
      end

      context 'when a object pool was joined' do
        let!(:pool) { create(:pool_repository, :ready, source_project: project) }

        it 'leaves the pool' do
          allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
          allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('test_second_storage').and_return(SecureRandom.uuid)

          expect(project_repository_double).to receive(:replicate)
            .with(project.repository.raw)
          expect(project_repository_double).to receive(:checksum)
            .and_return(checksum)
          expect(original_project_repository_double).to receive(:remove)

          result = subject.execute
          project.reload

          expect(result).to be_success
          expect(project.repository_storage).to eq('test_second_storage')
          expect(project.reload_pool_repository).to be_nil
        end
      end

      context 'when the repository move is finished' do
        let(:repository_storage_move) { create(:project_repository_storage_move, :finished, container: project, destination_storage_name: destination) }

        it 'is idempotent' do
          expect do
            result = subject.execute

            expect(result).to be_success
          end.not_to change(repository_storage_move, :state)
        end
      end

      context 'when the repository move is failed' do
        let(:repository_storage_move) { create(:project_repository_storage_move, :failed, container: project, destination_storage_name: destination) }

        it 'is idempotent' do
          expect do
            result = subject.execute

            expect(result).to be_success
          end.not_to change(repository_storage_move, :state)
        end
      end
    end

    context 'project with no repositories' do
      let(:project) { create(:project) }
      let(:repository_storage_move) { create(:project_repository_storage_move, :scheduled, container: project, destination_storage_name: 'test_second_storage') }

      it 'updates the database' do
        allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
        allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('test_second_storage').and_return(SecureRandom.uuid)

        result = subject.execute
        project.reload

        expect(result).to be_success
        expect(project).not_to be_repository_read_only
        expect(project.repository_storage).to eq('test_second_storage')
        expect(project.project_repository.shard_name).to eq('test_second_storage')
      end
    end

    context 'with wiki repository' do
      include_examples 'moves repository to another storage', 'wiki' do
        let(:project) { create(:project, :repository, wiki_enabled: true) }
        let(:repository) { project.wiki.repository }
        let(:destination) { 'test_second_storage' }
        let(:repository_storage_move) { create(:project_repository_storage_move, :scheduled, container: project, destination_storage_name: destination) }

        before do
          project.create_wiki
        end
      end
    end

    context 'with design repository' do
      include_examples 'moves repository to another storage', 'design' do
        let(:project) { create(:project, :repository) }
        let(:repository) { project.design_repository }
        let(:destination) { 'test_second_storage' }
        let(:repository_storage_move) { create(:project_repository_storage_move, :scheduled, container: project, destination_storage_name: destination) }

        before do
          project.design_repository.create_if_not_exists
        end
      end
    end
  end
end
