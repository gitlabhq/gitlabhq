# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:uploads:migrate and migrate_to_local rake tasks', :sidekiq_inline, :silence_stdout do
  before do
    stub_env('MIGRATION_BATCH_SIZE', 3.to_s)
    stub_uploads_object_storage(AvatarUploader)
    stub_uploads_object_storage(FileUploader)
    Rake.application.rake_require 'tasks/gitlab/uploads/migrate'

    create_list(:project, 2, :with_avatar)
    create_list(:group, 2, :with_avatar)
    create_list(:project, 2) do |model|
      FileUploader.new(model).store!(fixture_file_upload('spec/fixtures/doc_sample.txt'))
    end
  end

  let(:total_uploads_count) { 6 }

  it 'migrates all uploads to object storage in batches' do
    expect(ObjectStorage::MigrateUploadsWorker)
      .to receive(:perform_async).twice.and_call_original

    run_rake_task('gitlab:uploads:migrate:all')

    expect(Upload.with_files_stored_locally.count).to eq(0)
    expect(Upload.with_files_stored_remotely.count).to eq(total_uploads_count)
  end

  it 'migrates all uploads to local storage in batches' do
    run_rake_task('gitlab:uploads:migrate')
    expect(Upload.with_files_stored_remotely.count).to eq(total_uploads_count)

    expect(ObjectStorage::MigrateUploadsWorker)
      .to receive(:perform_async).twice.and_call_original

    run_rake_task('gitlab:uploads:migrate_to_local:all')

    expect(Upload.with_files_stored_remotely.count).to eq(0)
    expect(Upload.with_files_stored_locally.count).to eq(total_uploads_count)
  end

  shared_examples 'migrate task with filters' do
    it 'migrates matching uploads to object storage' do
      run_rake_task('gitlab:uploads:migrate', task_arguments)

      migrated_count = matching_uploads.with_files_stored_remotely.count

      expect(migrated_count).to eq(matching_uploads.count)
      expect(Upload.with_files_stored_locally.count).to eq(total_uploads_count - migrated_count)
    end

    it 'migrates matching uploads to local storage' do
      run_rake_task('gitlab:uploads:migrate')
      expect(Upload.with_files_stored_remotely.count).to eq(total_uploads_count)

      run_rake_task('gitlab:uploads:migrate_to_local', task_arguments)

      migrated_count = matching_uploads.with_files_stored_locally.count

      expect(migrated_count).to eq(matching_uploads.count)
      expect(Upload.with_files_stored_remotely.count).to eq(total_uploads_count - migrated_count)
    end
  end

  context 'when uploader_class is given' do
    let(:task_arguments) { ['FileUploader'] }
    let(:matching_uploads) { Upload.where(uploader: 'FileUploader') }

    it_behaves_like 'migrate task with filters'
  end

  context 'when model_class is given' do
    let(:task_arguments) { [nil, 'Project'] }
    let(:matching_uploads) { Upload.where(model_type: 'Project') }

    it_behaves_like 'migrate task with filters'
  end

  context 'when mounted_as is given' do
    let(:task_arguments) { [nil, nil, :avatar] }
    let(:matching_uploads) { Upload.where(mount_point: :avatar) }

    it_behaves_like 'migrate task with filters'
  end

  context 'when multiple filters are given' do
    let(:task_arguments) { %w[AvatarUploader Project] }
    let(:matching_uploads) { Upload.where(uploader: 'AvatarUploader', model_type: 'Project') }

    it_behaves_like 'migrate task with filters'
  end
end
