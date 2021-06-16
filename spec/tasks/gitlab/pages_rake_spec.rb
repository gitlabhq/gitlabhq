# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:pages', :silence_stdout do
  before(:context) do
    Rake.application.rake_require 'tasks/gitlab/pages'
  end

  describe 'migrate_legacy_storage task' do
    subject { run_rake_task('gitlab:pages:migrate_legacy_storage') }

    it 'calls migration service' do
      expect_next_instance_of(::Pages::MigrateFromLegacyStorageService, anything,
                              ignore_invalid_entries: false,
                              mark_projects_as_not_deployed: false) do |service|
        expect(service).to receive(:execute_with_threads).with(threads: 3, batch_size: 10).and_call_original
      end

      subject
    end

    it 'uses PAGES_MIGRATION_THREADS environment variable' do
      stub_env('PAGES_MIGRATION_THREADS', '5')

      expect_next_instance_of(::Pages::MigrateFromLegacyStorageService, anything,
                              ignore_invalid_entries: false,
                              mark_projects_as_not_deployed: false) do |service|
        expect(service).to receive(:execute_with_threads).with(threads: 5, batch_size: 10).and_call_original
      end

      subject
    end

    it 'uses PAGES_MIGRATION_BATCH_SIZE environment variable' do
      stub_env('PAGES_MIGRATION_BATCH_SIZE', '100')

      expect_next_instance_of(::Pages::MigrateFromLegacyStorageService, anything,
                              ignore_invalid_entries: false,
                              mark_projects_as_not_deployed: false) do |service|
        expect(service).to receive(:execute_with_threads).with(threads: 3, batch_size: 100).and_call_original
      end

      subject
    end

    it 'uses PAGES_MIGRATION_IGNORE_INVALID_ENTRIES environment variable' do
      stub_env('PAGES_MIGRATION_IGNORE_INVALID_ENTRIES', 'true')

      expect_next_instance_of(::Pages::MigrateFromLegacyStorageService, anything,
                              ignore_invalid_entries: true,
                              mark_projects_as_not_deployed: false) do |service|
        expect(service).to receive(:execute_with_threads).with(threads: 3, batch_size: 10).and_call_original
      end

      subject
    end

    it 'uses PAGES_MIGRATION_MARK_PROJECTS_AS_NOT_DEPLOYED environment variable' do
      stub_env('PAGES_MIGRATION_MARK_PROJECTS_AS_NOT_DEPLOYED', 'true')

      expect_next_instance_of(::Pages::MigrateFromLegacyStorageService, anything,
                              ignore_invalid_entries: false,
                              mark_projects_as_not_deployed: true) do |service|
        expect(service).to receive(:execute_with_threads).with(threads: 3, batch_size: 10).and_call_original
      end

      subject
    end
  end

  describe 'clean_migrated_zip_storage task' do
    it 'removes only migrated deployments' do
      regular_deployment = create(:pages_deployment)
      migrated_deployment = create(:pages_deployment, :migrated)

      regular_deployment.project.update_pages_deployment!(regular_deployment)
      migrated_deployment.project.update_pages_deployment!(migrated_deployment)

      expect(PagesDeployment.all).to contain_exactly(regular_deployment, migrated_deployment)

      run_rake_task('gitlab:pages:clean_migrated_zip_storage')

      expect(PagesDeployment.all).to contain_exactly(regular_deployment)
      expect(PagesDeployment.find_by_id(regular_deployment.id)).not_to be_nil
      expect(PagesDeployment.find_by_id(migrated_deployment.id)).to be_nil
    end
  end

  describe 'gitlab:pages:deployments:migrate_to_object_storage' do
    subject { run_rake_task('gitlab:pages:deployments:migrate_to_object_storage') }

    before do
      stub_pages_object_storage(::Pages::DeploymentUploader, enabled: object_storage_enabled)
    end

    let!(:deployment) { create(:pages_deployment, file_store: store) }
    let(:object_storage_enabled) { true }

    context 'when local storage is used' do
      let(:store) { ObjectStorage::Store::LOCAL }

      context 'and remote storage is defined' do
        it 'migrates file to remote storage' do
          subject

          expect(deployment.reload.file_store).to eq(ObjectStorage::Store::REMOTE)
        end
      end

      context 'and remote storage is not defined' do
        let(:object_storage_enabled) { false }

        it 'fails to migrate to remote storage' do
          subject

          expect(deployment.reload.file_store).to eq(ObjectStorage::Store::LOCAL)
        end
      end
    end

    context 'when remote storage is used' do
      let(:store) { ObjectStorage::Store::REMOTE }

      it 'file stays on remote storage' do
        subject

        expect(deployment.reload.file_store).to eq(ObjectStorage::Store::REMOTE)
      end
    end
  end

  describe 'gitlab:pages:deployments:migrate_to_local' do
    subject { run_rake_task('gitlab:pages:deployments:migrate_to_local') }

    before do
      stub_pages_object_storage(::Pages::DeploymentUploader, enabled: object_storage_enabled)
    end

    let!(:deployment) { create(:pages_deployment, file_store: store) }
    let(:object_storage_enabled) { true }

    context 'when remote storage is used' do
      let(:store) { ObjectStorage::Store::REMOTE }

      context 'and job has remote file store defined' do
        it 'migrates file to local storage' do
          subject

          expect(deployment.reload.file_store).to eq(ObjectStorage::Store::LOCAL)
        end
      end
    end

    context 'when local storage is used' do
      let(:store) { ObjectStorage::Store::LOCAL }

      it 'file stays on local storage' do
        subject

        expect(deployment.reload.file_store).to eq(ObjectStorage::Store::LOCAL)
      end
    end
  end
end
