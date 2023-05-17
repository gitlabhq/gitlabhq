# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AfterRenameService, feature_category: :projects do
  let(:legacy_storage) { Storage::LegacyProject.new(project) }
  let(:hashed_storage) { Storage::Hashed.new(project) }
  let!(:path_before_rename) { project.path }
  let!(:full_path_before_rename) { project.full_path }
  let!(:path_after_rename) { "#{project.path}-renamed" }
  let!(:full_path_after_rename) { "#{project.full_path}-renamed" }
  let!(:repo_before_rename) { project.repository.raw }
  let!(:wiki_repo_before_rename) { project.wiki.repository.raw }

  let(:repo_after_rename) do
    Gitlab::Git::Repository.new(project.repository_storage, "#{full_path_after_rename}.git", nil, nil)
  end

  let(:wiki_repo_after_rename) do
    Gitlab::Git::Repository.new(project.repository_storage, "#{full_path_after_rename}.wiki.git", nil, nil)
  end

  describe '#execute' do
    context 'using legacy storage' do
      let(:project) { create(:project, :repository, :wiki_repo, :legacy_storage) }
      let(:project_storage) { project.send(:storage) }
      let(:gitlab_shell) { Gitlab::Shell.new }

      before do
        # Project#gitlab_shell returns a new instance of Gitlab::Shell on every
        # call. This makes testing a bit easier.
        allow(project).to receive(:gitlab_shell).and_return(gitlab_shell)

        stub_application_setting(hashed_storage_enabled: false)
      end

      it 'renames a repository' do
        stub_container_registry_config(enabled: false)

        expect_any_instance_of(SystemHooksService)
          .to receive(:execute_hooks_for)
          .with(project, :rename)

        expect_any_instance_of(Gitlab::UploadsTransfer)
          .to receive(:rename_project)
          .with(path_before_rename, path_after_rename, project.namespace.full_path)

        expect(repo_before_rename).to exist
        expect(wiki_repo_before_rename).to exist

        service_execute

        expect(repo_before_rename).not_to exist
        expect(wiki_repo_before_rename).not_to exist
        expect(repo_after_rename).to exist
        expect(wiki_repo_after_rename).to exist
      end

      context 'container registry with images' do
        let(:container_repository) { create(:container_repository) }

        before do
          stub_container_registry_config(enabled: true)
          stub_container_registry_tags(repository: :any, tags: ['tag'])
          project.container_repositories << container_repository
        end

        it 'raises a RenameFailedError' do
          expect { service_execute }.to raise_error(described_class::RenameFailedError)
        end
      end

      context 'attachments' do
        before do
          expect(project_storage).to receive(:rename_repo) { true }
        end

        it 'moves uploads folder to new location' do
          expect_any_instance_of(Gitlab::UploadsTransfer).to receive(:rename_project)

          service_execute
        end
      end

      it 'updates project full path in gitaly' do
        service_execute

        expect(project.repository.full_path).to eq(project.full_path)
      end

      it 'updates storage location' do
        allow(project_storage).to receive(:rename_repo).and_return(true)

        service_execute

        expect(project.project_repository).to have_attributes(
          disk_path: project.disk_path,
          shard_name: project.repository_storage
        )
      end

      context 'with hashed storage upgrade when renaming enabled' do
        it 'calls HashedStorage::MigrationService with correct options' do
          stub_application_setting(hashed_storage_enabled: true)

          expect_next_instance_of(::Projects::HashedStorage::MigrationService) do |service|
            expect(service).to receive(:execute).and_return(true)
          end

          service_execute
        end
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

        stub_application_setting(hashed_storage_enabled: true)
      end

      it 'renames a repository' do
        stub_container_registry_config(enabled: false)

        expect(gitlab_shell).not_to receive(:mv_repository)

        expect_any_instance_of(SystemHooksService)
          .to receive(:execute_hooks_for)
          .with(project, :rename)

        expect(project).to receive(:expire_caches_before_rename)

        service_execute
      end

      context 'container registry with images' do
        let(:container_repository) { create(:container_repository) }

        before do
          stub_container_registry_config(enabled: true)
          stub_container_registry_tags(repository: :any, tags: ['tag'])
          project.container_repositories << container_repository
        end

        it 'raises a RenameFailedError' do
          expect { service_execute }
            .to raise_error(described_class::RenameFailedError)
        end
      end

      context 'attachments' do
        let(:uploader) { create(:upload, :issuable_upload, :with_file, model: project) }
        let(:file_uploader) { build(:file_uploader, project: project) }
        let(:legacy_storage_path) { File.join(file_uploader.root, legacy_storage.disk_path) }
        let(:hashed_storage_path) { File.join(file_uploader.root, hashed_storage.disk_path) }

        it 'keeps uploads folder location unchanged' do
          expect_any_instance_of(Gitlab::UploadsTransfer).not_to receive(:rename_project)

          service_execute
        end

        context 'when not rolled out' do
          let(:project) { create(:project, :repository, storage_version: 1, skip_disk_validation: true) }

          it 'moves attachments folder to hashed storage' do
            expect(File.directory?(legacy_storage_path)).to be_truthy
            expect(File.directory?(hashed_storage_path)).to be_falsey

            service_execute
            expect(project.reload.hashed_storage?(:attachments)).to be_truthy

            expect(File.directory?(legacy_storage_path)).to be_falsey
            expect(File.directory?(hashed_storage_path)).to be_truthy
          end
        end
      end

      it 'updates project full path in gitaly' do
        service_execute

        expect(project.repository.full_path).to eq(project.full_path)
      end

      it 'updates storage location' do
        service_execute

        expect(project.project_repository).to have_attributes(
          disk_path: project.disk_path,
          shard_name: project.repository_storage
        )
      end
    end

    context 'EventStore' do
      let(:project) { create(:project, :repository, skip_disk_validation: true) }

      it 'publishes a ProjectPathChangedEvent' do
        expect { service_execute }
          .to publish_event(Projects::ProjectPathChangedEvent)
          .with(
            project_id: project.id,
            namespace_id: project.namespace_id,
            root_namespace_id: project.root_namespace.id,
            old_path: full_path_before_rename,
            new_path: full_path_after_rename
          )
      end
    end
  end

  def service_execute
    # AfterRenameService is called by UpdateService after a successful model.update
    # the initialization will include before and after paths values
    project.update!(path: path_after_rename)

    described_class.new(project, path_before: path_before_rename, full_path_before: full_path_before_rename).execute
  end
end
