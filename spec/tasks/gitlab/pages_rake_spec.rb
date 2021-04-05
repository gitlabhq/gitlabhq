# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:pages' do
  before(:context) do
    Rake.application.rake_require 'tasks/gitlab/pages'
  end

  describe 'migrate_legacy_storage task' do
    subject { run_rake_task('gitlab:pages:migrate_legacy_storage') }

    it 'calls migration service' do
      expect_next_instance_of(::Pages::MigrateFromLegacyStorageService, anything,
                              migration_threads: 3,
                              batch_size: 10,
                              ignore_invalid_entries: false,
                              mark_projects_as_not_deployed: false) do |service|
        expect(service).to receive(:execute).and_call_original
      end

      subject
    end

    it 'uses PAGES_MIGRATION_THREADS environment variable' do
      stub_env('PAGES_MIGRATION_THREADS', '5')

      expect_next_instance_of(::Pages::MigrateFromLegacyStorageService, anything,
                              migration_threads: 5,
                              batch_size: 10,
                              ignore_invalid_entries: false,
                              mark_projects_as_not_deployed: false) do |service|
        expect(service).to receive(:execute).and_call_original
      end

      subject
    end

    it 'uses PAGES_MIGRATION_BATCH_SIZE environment variable' do
      stub_env('PAGES_MIGRATION_BATCH_SIZE', '100')

      expect_next_instance_of(::Pages::MigrateFromLegacyStorageService, anything,
                              migration_threads: 3,
                              batch_size: 100,
                              ignore_invalid_entries: false,
                              mark_projects_as_not_deployed: false) do |service|
        expect(service).to receive(:execute).and_call_original
      end

      subject
    end

    it 'uses PAGES_MIGRATION_IGNORE_INVALID_ENTRIES environment variable' do
      stub_env('PAGES_MIGRATION_IGNORE_INVALID_ENTRIES', 'true')

      expect_next_instance_of(::Pages::MigrateFromLegacyStorageService, anything,
                              migration_threads: 3,
                              batch_size: 10,
                              ignore_invalid_entries: true,
                              mark_projects_as_not_deployed: false) do |service|
        expect(service).to receive(:execute).and_call_original
      end

      subject
    end

    it 'uses PAGES_MIGRATION_MARK_PROJECTS_AS_NOT_DEPLOYED environment variable' do
      stub_env('PAGES_MIGRATION_MARK_PROJECTS_AS_NOT_DEPLOYED', 'true')

      expect_next_instance_of(::Pages::MigrateFromLegacyStorageService, anything,
                              migration_threads: 3,
                              batch_size: 10,
                              ignore_invalid_entries: false,
                              mark_projects_as_not_deployed: true) do |service|
        expect(service).to receive(:execute).and_call_original
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
end
