# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UpdateRepositoryStorageService, feature_category: :source_code_management do
  include Gitlab::ShellAdapter

  subject { described_class.new(repository_storage_move) }

  describe "#execute" do
    let(:time) { Time.current }

    let(:storage_source) { 'default' }
    let(:storage_destination) { 'test_second_storage' }

    before do
      allow(Time).to receive(:now).and_return(time)

      stub_storage_settings(storage_destination => {})
    end

    context 'without wiki and design repository' do
      let!(:shard_source) { create(:shard, name: storage_source) }
      let!(:shard_destination) { create(:shard, name: storage_destination) }

      let(:project) { create(:project, :repository, wiki_enabled: false) }
      let!(:checksum) { project.repository.checksum }

      let(:pool_repository) { create(:pool_repository, source_project: project) }

      let(:repository_storage_move) { create(:project_repository_storage_move, :scheduled, container: project, destination_storage_name: storage_destination) }

      let(:project_repository_double_source) { double(:repository) }
      let(:project_repository_double_destination) { double(:repository) }

      before do
        allow(Gitlab::GitalyClient).to receive(:filesystem_id).with(storage_source).and_call_original
        allow(Gitlab::GitalyClient).to receive(:filesystem_id).with(storage_destination).and_return(SecureRandom.uuid)

        allow(Gitlab::Git::Repository).to receive(:new).and_call_original
      end

      context 'when the move succeeds' do
        it 'moves the repository to the new storage and unmarks the repository as read-only' do
          expect(project.repository_storage).to eq(storage_source)
          expect(project.project_repository.shard_name).to eq(storage_source)

          result = subject.execute
          project.reload

          expect(result).to be_success
          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq(storage_destination)
          expect(project.project_repository.shard_name).to eq(storage_destination)
          expect(repository_storage_move.reload).to be_finished
          expect(repository_storage_move.error_message).to be_nil
        end
      end

      context 'when touch raises an exception' do
        let(:exception) { RuntimeError.new('Boom') }

        before do
          allow(Gitlab::Git::Repository).to receive(:new)
            .with(storage_destination, project.repository.raw.relative_path, project.repository.gl_repository, project.repository.full_path)
            .and_return(project_repository_double_destination)
        end

        it 'marks the storage move as failed and restores read-write access' do
          allow(repository_storage_move).to receive(:container).and_return(project)

          allow(project).to receive(:touch).and_wrap_original do
            project.assign_attributes(updated_at: 1.second.ago)
            raise exception
          end

          expect(project_repository_double_destination).to receive(:replicate)
            .with(project.repository.raw, partition_hint: "")
          expect(project_repository_double_destination).to receive(:checksum)
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

        it 'updates the database without trying to move the repository', :aggregate_failures do
          result = subject.execute
          project.reload

          expect(result).to be_success
          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq(storage_destination)
          expect(project.project_repository.shard_name).to eq(storage_destination)
        end
      end

      context 'when the move fails' do
        before do
          allow(Gitlab::Git::Repository).to receive(:new)
            .with(storage_destination, project.repository.raw.relative_path, project.repository.gl_repository, project.repository.full_path)
            .and_return(project_repository_double_destination)
        end

        it 'unmarks the repository as read-only without updating the repository storage' do
          expect(project_repository_double_destination).to receive(:replicate)
            .with(project.repository.raw, partition_hint: "")
            .and_raise(Gitlab::Git::CommandError, 'Boom')
          expect(project_repository_double_destination).to receive(:remove)

          expect do
            subject.execute
          end.to raise_error(Gitlab::Git::CommandError)

          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq(storage_source)
          expect(repository_storage_move).to be_failed
          expect(repository_storage_move.error_message).to eq('Boom')
        end
      end

      context 'when the cleanup fails' do
        before do
          allow(Gitlab::Git::Repository).to receive(:new)
            .with(storage_destination, project.repository.raw.relative_path, project.repository.gl_repository, project.repository.full_path)
            .and_return(project_repository_double_destination)
          allow(Gitlab::Git::Repository).to receive(:new)
            .with(storage_source, project.repository.raw.relative_path, nil, nil)
            .and_return(project_repository_double_source)
        end

        it 'sets the correct state' do
          expect(project_repository_double_destination).to receive(:replicate)
            .with(project.repository.raw, partition_hint: "")
          expect(project_repository_double_destination).to receive(:checksum)
            .and_return(checksum)
          expect(project_repository_double_source).to receive(:remove)
            .and_raise(Gitlab::Git::CommandError)

          expect do
            subject.execute
          end.to raise_error(Gitlab::Git::CommandError)

          expect(repository_storage_move).to be_cleanup_failed
        end
      end

      context 'when the checksum does not match' do
        before do
          allow(Gitlab::Git::Repository).to receive(:new)
            .with(storage_destination, project.repository.raw.relative_path, project.repository.gl_repository, project.repository.full_path)
            .and_return(project_repository_double_destination)
        end

        it 'unmarks the repository as read-only without updating the repository storage' do
          expect(project_repository_double_destination).to receive(:replicate)
            .with(project.repository.raw, partition_hint: "")
          expect(project_repository_double_destination).to receive(:checksum)
            .and_return('not matching checksum')
          expect(project_repository_double_destination).to receive(:remove)

          expect do
            subject.execute
          end.to raise_error(::Repositories::ReplicateService::Error, /Failed to verify project repository checksum/)

          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq(storage_source)
        end
      end

      context 'with repository pool' do
        let(:object_pool_double_source) { double(:object_pool, repository: object_pool_repository_double_source) }
        let(:object_pool_repository_double_source) { double(:repository) }

        let(:object_pool_double_destination) { double(:object_pool, repository: object_pool_repository_double_destination) }
        let(:object_pool_repository_double_destination) { double(:repository) }

        let(:old_object_pool_checksum) { 'abcd' }
        let(:new_object_pool_checksum) { old_object_pool_checksum }

        before do
          allow(Gitlab::Git::ObjectPool).to receive(:new).and_call_original
        end

        context 'when project had a repository pool' do
          let!(:pool_repository) { create(:pool_repository, :ready, shard: shard_source, source_project: project) }
          let!(:repository_storage_move) { create(:project_repository_storage_move, :scheduled, container: project, destination_storage_name: storage_destination) }

          it 'creates a new repository pool and connects project to it' do
            result = subject.execute
            expect(result).to be_success

            project.reload.cleanup

            new_pool_repository = project.pool_repository

            expect(new_pool_repository).not_to eq(pool_repository)
            expect(new_pool_repository.shard).to eq(shard_destination)
            expect(new_pool_repository.state).to eq('ready')
            expect(new_pool_repository.disk_path).to eq(pool_repository.disk_path)
            expect(new_pool_repository.source_project).to eq(project)
          end

          context 'when the object pool exists in the new shard but is disconnected' do
            before do
              # Mock the object pool in the destination storage, because we can't create a PoolRepository
              # instance if the associated project is on a different storage.
              allow(Gitlab::Git::ObjectPool).to receive(:new)
                .with(storage_destination, anything, anything, anything)
                .and_return(object_pool_double)
              allow(object_pool_double).to receive(:create)
              allow(object_pool_double).to receive(:relative_path).and_return(project.repository.raw.relative_path)
              allow(object_pool_double).to receive(:link) do |repository|
                expect(repository.storage).to eq storage_destination
              end

              # Mock the new repository object created in the destination storage. This is what the repository in the
              # source destination will be replicated into.
              allow(Gitlab::Git::Repository).to receive(:new)
                .with(storage_destination, project.repository.raw.relative_path, project.repository.gl_repository, project.repository.full_path)
                .and_return(project_repository_double_destination)
              allow(project_repository_double_destination).to receive(:replicate).with(project.repository.raw, partition_hint: project.repository.raw.relative_path)
              allow(project_repository_double_destination).to receive(:checksum).and_return(checksum)
            end

            let!(:disconnected_pool_repository) { create(:pool_repository, :ready, shard: shard_destination, source_project: project) }
            let(:object_pool_double) { double(:object_pool, repository: object_pool_repository_double) }
            let(:object_pool_repository_double) { double(:repository) }
            let(:project_repository_double) { double(:repository) }

            context 'with the root project' do
              it 'connects project to it' do
                expect(project.repository_storage).to eq(storage_source)

                result = subject.execute
                expect(result).to be_success

                project.reload.cleanup

                expect(project.repository_storage).to eq(storage_destination)

                project_pool_repository = project.pool_repository
                expect(project_pool_repository).to eq(disconnected_pool_repository)
                expect(object_pool_double).to have_received(:link).with(project.repository.raw)
              end
            end

            context 'without the root project' do
              before do
                disconnected_pool_repository.update!(source_project: nil)
              end

              it 'connects project to it' do
                expect(project.repository_storage).to eq(storage_source)

                result = subject.execute
                expect(result).to be_success

                project.reload.cleanup

                expect(project.repository_storage).to eq(storage_destination)

                project_pool_repository = project.pool_repository
                expect(project_pool_repository).to eq(disconnected_pool_repository)
                expect(object_pool_double).to have_received(:link).with(project.repository.raw)
              end
            end
          end

          context 'when repository does not exist' do
            let!(:project) { create(:project, :repository, wiki_enabled: false) }

            before do
              project.repository.remove
            end

            it 'does not mirror object pool' do
              expect(project.pool_repository.shard).to eq(shard_source)

              subject.execute

              expect(project.pool_repository.shard).to eq(shard_source)
            end
          end

          context 'when project belongs to repository pool, but not as a root project' do
            let!(:project) { create(:project, :repository) }

            before do
              project.update!(pool_repository: pool_repository)
            end

            it 'creates a new repository pool and connects project to it' do
              result = subject.execute
              expect(result).to be_success

              project.reload.cleanup

              new_pool_repository = project.pool_repository

              expect(new_pool_repository).not_to eq(pool_repository)
              expect(new_pool_repository.shard).to eq(shard_destination)
              expect(new_pool_repository.state).to eq('ready')
              expect(new_pool_repository.source_project).to eq(project)
            end
          end

          context 'when project belongs to the repository pool without a root project' do
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
              expect(new_pool_repository.shard).to eq(shard_destination)
              expect(new_pool_repository.state).to eq('ready')
              expect(new_pool_repository.source_project).to eq(nil)
              expect(new_pool_repository.disk_path).to eq(pool_repository.disk_path)
            end
          end

          context 'when object pool checksum does not match' do
            let(:new_object_pool_checksum) { 'not_match' }

            before do
              allow(Gitlab::Git::ObjectPool).to receive(:new)
                .with(storage_source, anything, anything, anything)
                .and_return(object_pool_double_source)
              allow(Gitlab::Git::ObjectPool).to receive(:new)
                .with(storage_destination, anything, anything, anything)
                .and_return(object_pool_double_destination)
              allow(object_pool_repository_double_destination).to receive(:replicate).with(object_pool_repository_double_source, partition_hint: "")
              allow(object_pool_repository_double_destination).to receive(:checksum).and_return(new_object_pool_checksum)
              allow(object_pool_repository_double_source).to receive(:checksum).and_return(old_object_pool_checksum)
            end

            it 'raises an error and removes the new object pool repository' do
              expect(object_pool_repository_double_destination).to receive(:remove)
              expect_next_instance_of(PoolRepository) do |instance|
                expect(instance).to receive(:destroy!).and_call_original
              end

              original_count = PoolRepository.count

              expect do
                subject.execute
              end.to raise_error(::Repositories::ReplicateService::Error, /Failed to verify object_pool repository/)

              project.reload

              expect(PoolRepository.count).to eq(original_count)

              expect(project.pool_repository).to eq(pool_repository)
              expect(project.repository.shard).to eq(shard_source.name)
            end
          end
        end
      end

      context 'when the repository move is finished' do
        let(:repository_storage_move) { create(:project_repository_storage_move, :finished, container: project, destination_storage_name: storage_destination) }

        it 'is idempotent' do
          expect do
            result = subject.execute

            expect(result).to be_success
          end.not_to change(repository_storage_move, :state)
        end
      end

      context 'when the repository move is failed' do
        let(:repository_storage_move) { create(:project_repository_storage_move, :failed, container: project, destination_storage_name: storage_destination) }

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
      let(:repository_storage_move) { create(:project_repository_storage_move, :scheduled, container: project, destination_storage_name: storage_destination) }

      it 'updates the database' do
        result = subject.execute
        project.reload

        expect(result).to be_success
        expect(project).not_to be_repository_read_only
        expect(project.repository_storage).to eq(storage_destination)
        expect(project.project_repository.shard_name).to eq(storage_destination)
      end
    end

    context 'with wiki repository' do
      include_examples 'moves repository to another storage', 'wiki' do
        let(:project) { create(:project, :repository, wiki_enabled: true) }
        let(:repository) { project.wiki.repository }
        let(:destination) { storage_destination }
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
        let(:destination) { storage_destination }
        let(:repository_storage_move) { create(:project_repository_storage_move, :scheduled, container: project, destination_storage_name: destination) }

        before do
          project.design_repository.create_if_not_exists
        end
      end
    end
  end
end
