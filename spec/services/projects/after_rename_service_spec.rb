# frozen_string_literal: true

require 'spec_helper'

describe Projects::AfterRenameService do
  let(:rugged_config) { rugged_repo(project.repository).config }

  describe '#execute' do
    context 'using legacy storage' do
      let(:project) { create(:project, :repository, :legacy_storage) }
      let(:gitlab_shell) { Gitlab::Shell.new }
      let(:project_storage) { project.send(:storage) }

      before do
        # Project#gitlab_shell returns a new instance of Gitlab::Shell on every
        # call. This makes testing a bit easier.
        allow(project).to receive(:gitlab_shell).and_return(gitlab_shell)

        allow(project)
          .to receive(:previous_changes)
          .and_return('path' => ['foo'])

        allow(project)
          .to receive(:path_was)
          .and_return('foo')

        stub_feature_flags(skip_hashed_storage_upgrade: false)
      end

      it 'renames a repository' do
        stub_container_registry_config(enabled: false)

        expect(gitlab_shell).to receive(:mv_repository)
          .ordered
          .with(project.repository_storage, "#{project.namespace.full_path}/foo", "#{project.full_path}")
          .and_return(true)

        expect(gitlab_shell).to receive(:mv_repository)
          .ordered
          .with(project.repository_storage, "#{project.namespace.full_path}/foo.wiki", "#{project.full_path}.wiki")
          .and_return(true)

        expect_any_instance_of(SystemHooksService)
          .to receive(:execute_hooks_for)
          .with(project, :rename)

        expect_any_instance_of(Gitlab::UploadsTransfer)
          .to receive(:rename_project)
          .with('foo', project.path, project.namespace.full_path)

        expect(project).to receive(:expire_caches_before_rename)

        described_class.new(project).execute
      end

      context 'container registry with images' do
        let(:container_repository) { create(:container_repository) }

        before do
          stub_container_registry_config(enabled: true)
          stub_container_registry_tags(repository: :any, tags: ['tag'])
          project.container_repositories << container_repository
        end

        it 'raises a RenameFailedError' do
          expect { described_class.new(project).execute }
            .to raise_error(described_class::RenameFailedError)
        end
      end

      context 'gitlab pages' do
        before do
          expect(project_storage).to receive(:rename_repo) { true }
        end

        it 'moves pages folder to new location' do
          expect_any_instance_of(Gitlab::PagesTransfer).to receive(:rename_project)

          described_class.new(project).execute
        end
      end

      context 'attachments' do
        before do
          expect(project_storage).to receive(:rename_repo) { true }
        end

        it 'moves uploads folder to new location' do
          expect_any_instance_of(Gitlab::UploadsTransfer).to receive(:rename_project)

          described_class.new(project).execute
        end
      end

      it 'updates project full path in .git/config' do
        allow(project_storage).to receive(:rename_repo).and_return(true)

        described_class.new(project).execute

        expect(rugged_config['gitlab.fullpath']).to eq(project.full_path)
      end

      it 'updates storage location' do
        allow(project_storage).to receive(:rename_repo).and_return(true)

        described_class.new(project).execute

        expect(project.project_repository).to have_attributes(
          disk_path: project.disk_path,
          shard_name: project.repository_storage
        )
      end
    end

    context 'using hashed storage' do
      let(:project) { create(:project, :repository, skip_disk_validation: true) }
      let(:gitlab_shell) { Gitlab::Shell.new }
      let(:hash) { Digest::SHA2.hexdigest(project.id.to_s) }
      let(:hashed_prefix) { File.join('@hashed', hash[0..1], hash[2..3]) }
      let(:hashed_path) { File.join(hashed_prefix, hash) }

      before do
        # Project#gitlab_shell returns a new instance of Gitlab::Shell on every
        # call. This makes testing a bit easier.
        allow(project).to receive(:gitlab_shell).and_return(gitlab_shell)
        allow(project).to receive(:previous_changes).and_return('path' => ['foo'])

        stub_feature_flags(skip_hashed_storage_upgrade: false)
        stub_application_setting(hashed_storage_enabled: true)
      end

      context 'migration to hashed storage' do
        it 'calls HashedStorageMigrationService with correct options' do
          project = create(:project, :repository, :legacy_storage)
          allow(project).to receive(:previous_changes).and_return('path' => ['foo'])

          expect_next_instance_of(::Projects::HashedStorageMigrationService) do |service|
            expect(service).to receive(:execute).and_return(true)
          end

          described_class.new(project).execute
        end
      end

      it 'renames a repository' do
        stub_container_registry_config(enabled: false)

        expect(gitlab_shell).not_to receive(:mv_repository)

        expect_any_instance_of(SystemHooksService)
          .to receive(:execute_hooks_for)
          .with(project, :rename)

        expect(project).to receive(:expire_caches_before_rename)

        described_class.new(project).execute
      end

      context 'container registry with images' do
        let(:container_repository) { create(:container_repository) }

        before do
          stub_container_registry_config(enabled: true)
          stub_container_registry_tags(repository: :any, tags: ['tag'])
          project.container_repositories << container_repository
        end

        it 'raises a RenameFailedError' do
          expect { described_class.new(project).execute }
            .to raise_error(described_class::RenameFailedError)
        end
      end

      context 'gitlab pages' do
        it 'moves pages folder to new location' do
          expect_any_instance_of(Gitlab::PagesTransfer).to receive(:rename_project)

          described_class.new(project).execute
        end
      end

      context 'attachments' do
        it 'keeps uploads folder location unchanged' do
          expect_any_instance_of(Gitlab::UploadsTransfer).not_to receive(:rename_project)

          described_class.new(project).execute
        end

        context 'when not rolled out' do
          let(:project) { create(:project, :repository, storage_version: 1, skip_disk_validation: true) }

          it 'moves pages folder to hashed storage' do
            expect_next_instance_of(Projects::HashedStorage::MigrateAttachmentsService) do |service|
              expect(service).to receive(:execute)
            end

            described_class.new(project).execute
          end
        end
      end

      it 'updates project full path in .git/config' do
        described_class.new(project).execute

        expect(rugged_config['gitlab.fullpath']).to eq(project.full_path)
      end

      it 'updates storage location' do
        described_class.new(project).execute

        expect(project.project_repository).to have_attributes(
          disk_path: project.disk_path,
          shard_name: project.repository_storage
        )
      end
    end
  end
end
