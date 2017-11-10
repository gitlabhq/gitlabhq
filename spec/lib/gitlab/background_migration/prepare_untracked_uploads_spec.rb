require 'spec_helper'

describe Gitlab::BackgroundMigration::PrepareUntrackedUploads, :migration, :sidekiq, schema: 20171103140253 do
  let!(:untracked_files_for_uploads) { table(:untracked_files_for_uploads) }

  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:project1) { create(:project) }
  let(:project2) { create(:project) }
  let(:appearance) { create(:appearance) }

  matcher :be_scheduled_migration do |*expected|
    match do |migration|
      BackgroundMigrationWorker.jobs.any? do |job|
        job['args'] == [migration, expected]
      end
    end

    failure_message do |migration|
      "Migration `#{migration}` with args `#{expected.inspect}` not scheduled!"
    end
  end

  context 'when files were uploaded before and after hashed storage was enabled' do
    before do
      fixture = Rails.root.join('spec', 'fixtures', 'rails_sample.jpg')
      uploaded_file = fixture_file_upload(fixture)

      user1.update(avatar: uploaded_file)
      project1.update(avatar: uploaded_file)
      appearance.update(logo: uploaded_file, header_logo: uploaded_file)
      uploaded_file = fixture_file_upload(fixture)
      UploadService.new(project1, uploaded_file, FileUploader).execute # Markdown upload

      stub_application_setting(hashed_storage_enabled: true)

      # Hashed files
      uploaded_file = fixture_file_upload(fixture)
      UploadService.new(project2, uploaded_file, FileUploader).execute
    end

    it 'adds unhashed files to the untracked_files_for_uploads table' do
      Sidekiq::Testing.fake! do
        expect do
          described_class.new.perform
        end.to change { untracked_files_for_uploads.count }.from(0).to(5)
      end
    end

    it 'does not add hashed files to the untracked_files_for_uploads table' do
      Sidekiq::Testing.fake! do
        described_class.new.perform

        hashed_file_path = project2.uploads.where(uploader: 'FileUploader').first.path
        expect(untracked_files_for_uploads.where("path like '%#{hashed_file_path}%'").exists?).to be_falsey
      end
    end

    it 'correctly schedules the follow-up background migration jobs' do
      Sidekiq::Testing.fake! do
        described_class.new.perform

        expect(described_class::FOLLOW_UP_MIGRATION).to be_scheduled_migration(1, 5)
        expect(BackgroundMigrationWorker.jobs.size).to eq(1)
      end
    end

    # E.g. from a previous failed run of this background migration
    context 'when there is existing data in untracked_files_for_uploads' do
      before do
        untracked_files_for_uploads.create(path: '/foo/bar.jpg')
      end

      it 'clears existing data before adding new data' do
        Sidekiq::Testing.fake! do
          expect do
            described_class.new.perform
          end.to change { untracked_files_for_uploads.count }.from(1).to(5)
        end
      end
    end

    # E.g. The installation is in use at the time of migration, and someone has
    # just uploaded a file
    context 'when there are files in /uploads/tmp' do
      before do
        FileUtils.touch(Rails.root.join(described_class::UPLOAD_DIR, 'tmp', 'some_file.jpg'))
      end

      it 'does not add files from /uploads/tmp' do
        Sidekiq::Testing.fake! do
          expect do
            described_class.new.perform
          end.to change { untracked_files_for_uploads.count }.from(0).to(5)
        end
      end
    end
  end

  # Very new or lightly-used installations that are running this migration
  # may not have an upload directory because they have no uploads.
  context 'when no files were ever uploaded' do
    it 'does not add to the untracked_files_for_uploads table (and does not raise error)' do
      Sidekiq::Testing.fake! do
        expect do
          described_class.new.perform
        end.not_to change { untracked_files_for_uploads.count }.from(0)
      end
    end
  end
end
