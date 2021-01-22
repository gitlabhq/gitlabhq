# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:pages:migrate_legacy_storagerake task' do
  before(:context) do
    Rake.application.rake_require 'tasks/gitlab/pages'
  end

  subject { run_rake_task('gitlab:pages:migrate_legacy_storage') }

  it 'calls migration service' do
    expect_next_instance_of(::Pages::MigrateFromLegacyStorageService, anything, 3, 10) do |service|
      expect(service).to receive(:execute).and_call_original
    end

    subject
  end

  it 'uses PAGES_MIGRATION_THREADS environment variable' do
    stub_env('PAGES_MIGRATION_THREADS', '5')

    expect_next_instance_of(::Pages::MigrateFromLegacyStorageService, anything, 5, 10) do |service|
      expect(service).to receive(:execute).and_call_original
    end

    subject
  end

  it 'uses PAGES_MIGRATION_BATCH_SIZE environment variable' do
    stub_env('PAGES_MIGRATION_BATCH_SIZE', '100')

    expect_next_instance_of(::Pages::MigrateFromLegacyStorageService, anything, 3, 100) do |service|
      expect(service).to receive(:execute).and_call_original
    end

    subject
  end
end
