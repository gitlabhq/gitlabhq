# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UpdateRepositoryStorageService, feature_category: :source_code_management do
  include Gitlab::ShellAdapter

  subject { described_class.new(repository_storage_move) }

  describe "#execute" do
    let(:time) { Time.current }

    before do
      allow(Time).to receive(:now).and_return(time)

      stub_storage_settings('test_second_storage' => {})
    end

    context 'without wiki and design repository' do
      let!(:shard_default) { create(:shard, name: 'default') }
      let!(:shard_second_storage) { create(:shard, name: 'test_second_storage') }

      let(:project) { create(:project, :repository, wiki_enabled: false) }
      let(:destination) { 'test_second_storage' }
      let(:repository_storage_move) { create(:project_repository_storage_move, :scheduled, container: project, destination_storage_name: destination) }
      let!(:checksum) { project.repository.checksum }
      let(:project_repository_double) { double(:repository) }
      let(:original_project_repository_double) { double(:repository) }

      let(:object_pool_double) { double(:object_pool, repository: object_pool_repository_double) }
      let(:object_pool_repository_double) { double(:repository) }

      let(:original_object_pool_double) { double(:object_pool, repository: original_object_pool_repository_double) }
      let(:original_object_pool_repository_double) { double(:repository) }

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

        allow(Gitlab::Git::ObjectPool).to receive(:new).and_call_original
        allow(Gitlab::Git::ObjectPool).to receive(:new)
          .with('test_second_storage', anything, anything, anything)
          .and_return(object_pool_double)
        allow(Gitlab::Git::ObjectPool).to receive(:new)
          .with('default', anything, anything, anything)
          .and_return(original_object_pool_double)

        allow(original_object_pool_double).to receive(:create)
        allow(object_pool_double).to receive(:create)
      end

      context 'when the move succeeds' do
        it 'moves the repository to the new storage and unmarks the repository as read-only' do
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
          expect(project.project_repository.shard_name).to eq('test_second_storage')
          expect(repository_storage_move.reload).to be_finished
          expect(repository_storage_move.error_message).to be_nil
        end
      end

      context 'when touch raises an exception' do
        let(:exception) { RuntimeError.new('Boom') }

        it 'marks the storage move as failed and restores read-write access' do
          allow(repository_storage_move).to receive(:container).and_return(project)

          allow(project).to receive(:touch).and_wrap_original do
            project.assign_attributes(updated_at: 1.second.ago)
            raise exception
          end

          expect(project_repository_double).to receive(:replicate)
            .with(project.repository.raw)
          expect(project_repository_double).to receive(:checksum)
            .and_return(checksum)

          expect { subject.execute }.to raise_error(exception)
          project.reload

          expect(project).not_to be_repository_read_only
          expect(repository_storage_move.reload).to be_failed
          expect(repository_storage_move.error_message).to eq('Boom')
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
            .and_raise(Gitlab::Git::CommandError, 'Boom')
          expect(project_repository_double).to receive(:remove)

          expect do
            subject.execute
          end.to raise_error(Gitlab::Git::CommandError)

          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('default')
          expect(repository_storage_move).to be_failed
          expect(repository_storage_move.error_message).to eq('Boom')
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
          expect(project_repository_double).to receive(:remove)

          expect do
            subject.execute
          end.to raise_error(Repositories::ReplicateService::Error, /Failed to verify project repository checksum/)

          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('default')
        end
      end

      context 'with repository pool' do
        let(:shard_from) { shard_default }
        let(:shard_to) { shard_second_storage }
        let(:old_object_pool_checksum) { 'abcd' }
        let(:new_object_pool_checksum) { old_object_pool_checksum }

        before do
          allow(project_repository_double).to receive(:replicate).with(project.repository.raw)
          allow(project_repository_double).to receive(:checksum).and_return(checksum)
          allow(original_project_repository_double).to receive(:remove)

          allow(object_pool_repository_double).to receive(:replicate).with(original_object_pool_repository_double)
          allow(object_pool_repository_double).to receive(:checksum).and_return(new_object_pool_checksum)
          allow(original_object_pool_repository_double).to receive(:checksum).and_return(old_object_pool_checksum)

          allow(object_pool_double).to receive(:link) do |repository|
            expect(repository.storage).to eq 'test_second_storage'
          end
        end

        context 'when project had a repository pool' do
          let!(:pool_repository) { create(:pool_repository, :ready, shard: shard_from, source_project: project) }

          it 'creates a new repository pool and connects project to it' do
            result = subject.execute
            expect(result).to be_success

            project.reload.cleanup

            new_pool_repository = project.pool_repository

            expect(new_pool_repository).not_to eq(pool_repository)
            expect(new_pool_repository.shard).to eq(shard_second_storage)
            expect(new_pool_repository.state).to eq('ready')
            expect(new_pool_repository.disk_path).to eq(pool_repository.disk_path)
            expect(new_pool_repository.source_project).to eq(project)

            expect(object_pool_double).to have_received(:link).with(project.repository.raw)
          end

          context 'when new shard has a repository pool' do
            let!(:new_pool_repository) { create(:pool_repository, :ready, shard: shard_to, source_project: project) }

            it 'connects project to it' do
              result = subject.execute
              expect(result).to be_success

              project.reload.cleanup

              project_pool_repository = project.pool_repository

              expect(project_pool_repository).to eq(new_pool_repository)
              expect(object_pool_double).to have_received(:link).with(project.repository.raw)
            end
          end

          context 'when new shard has a repository pool without the root project' do
            let!(:new_pool_repository) { create(:pool_repository, :ready, shard: shard_to, disk_path: pool_repository.disk_path) }

            before do
              pool_repository.update!(source_project: nil)
              new_pool_repository.update!(source_project: nil)
            end

            it 'connects project to it' do
              result = subject.execute
              expect(result).to be_success

              project.reload.cleanup

              project_pool_repository = project.pool_repository

              expect(project_pool_repository).to eq(new_pool_repository)
              expect(object_pool_double).to have_received(:link).with(project.repository.raw)
            end
          end

          context 'when repository does not exist' do
            let(:project) { create(:project) }
            let(:checksum) { nil }

            it 'does not mirror object pool' do
              result = subject.execute
              expect(result).to be_success

              expect(object_pool_repository_double).not_to have_received(:replicate)
            end
          end

          context 'when project belongs to repository pool, but not as a root project' do
            let!(:another_project) { create(:project, :repository) }
            let!(:pool_repository) { create(:pool_repository, :ready, shard: shard_from, source_project: another_project) }

            before do
              project.update!(pool_repository: pool_repository)
            end

            it 'creates a new repository pool and connects project to it' do
              result = subject.execute
              expect(result).to be_success

              project.reload.cleanup

              new_pool_repository = project.pool_repository

              expect(new_pool_repository).not_to eq(pool_repository)
              expect(new_pool_repository.shard).to eq(shard_second_storage)
              expect(new_pool_repository.state).to eq('ready')
              expect(new_pool_repository.source_project).to eq(another_project)

              expect(object_pool_double).to have_received(:link).with(project.repository.raw)
            end
          end

          context 'when project belongs to the repository pool without a root project' do
            let!(:pool_repository) { create(:pool_repository, :ready, shard: shard_from) }

            before do
              pool_repository.update!(source_project: nil)
              project.update!(pool_repository: pool_repository)
            end

            it 'creates a new repository pool without a root project and connects project to it' do
              result = subject.execute
              expect(result).to be_success

              project.reload.cleanup

              new_pool_repository = project.pool_repository

              expect(new_pool_repository).not_to eq(pool_repository)
              expect(new_pool_repository.shard).to eq(shard_second_storage)
              expect(new_pool_repository.state).to eq('ready')
              expect(new_pool_repository.source_project).to eq(nil)
              expect(new_pool_repository.disk_path).to eq(pool_repository.disk_path)

              expect(object_pool_double).to have_received(:link).with(project.repository.raw)
            end
          end

          context 'when object pool checksum does not match' do
            let(:new_object_pool_checksum) { 'not_match' }

            it 'raises an error and removes the new object pool repository' do
              expect(object_pool_repository_double).to receive(:remove)
              expect_next_instance_of(PoolRepository) do |instance|
                expect(instance).to receive(:destroy!).and_call_original
              end

              original_count = PoolRepository.count

              expect do
                subject.execute
              end.to raise_error(Repositories::ReplicateService::Error, /Failed to verify object_pool repository/)

              project.reload

              expect(PoolRepository.count).to eq(original_count)

              expect(project.pool_repository).to eq(pool_repository)
              expect(project.repository.shard).to eq('default')
            end
          end
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
