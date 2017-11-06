require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20171103140253_track_untracked_uploads')

describe TrackUntrackedUploads, :migration, :sidekiq do
  matcher :be_scheduled_migration do
    match do |migration|
      BackgroundMigrationWorker.jobs.any? do |job|
        job['args'] == [migration]
      end
    end

    failure_message do |migration|
      "Migration `#{migration}` with args `#{expected.inspect}` not scheduled!"
    end
  end

  it 'correctly schedules the follow-up background migration' do
    Sidekiq::Testing.fake! do
      migrate!

      expect(described_class::MIGRATION).to be_scheduled_migration
      expect(BackgroundMigrationWorker.jobs.size).to eq(1)
    end
  end

  it 'ensures the unhashed_upload_files table exists' do
    expect do
      migrate!
    end.to change { table_exists?(:unhashed_upload_files) }.from(false).to(true)
  end

  it 'has a path field long enough for really long paths' do
    class UnhashedUploadFile < ActiveRecord::Base
      self.table_name = 'unhashed_upload_files'
    end

    migrate!

    max_length_namespace_path = max_length_project_path = max_length_filename = 'a' * 255
    long_path = "./uploads#{("/#{max_length_namespace_path}") * Namespace::NUMBER_OF_ANCESTORS_ALLOWED}/#{max_length_project_path}/#{max_length_filename}"
    unhashed_upload_file = UnhashedUploadFile.new(path: long_path)
    unhashed_upload_file.save!
    expect(UnhashedUploadFile.first.path.size).to eq(5641)
  end

  context 'with tracked and untracked uploads' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:project1) { create(:project) }
    let(:project2) { create(:project) }
    let(:appearance) { create(:appearance) }

    before do
      fixture = Rails.root.join('spec', 'fixtures', 'rails_sample.jpg')

      # Tracked, by doing normal file upload
      uploaded_file = fixture_file_upload(fixture)
      user1.update(avatar: uploaded_file)
      project1.update(avatar: uploaded_file)
      UploadService.new(project1, uploaded_file, FileUploader).execute # Markdown upload
      appearance.update(logo: uploaded_file)

      # Untracked, by doing normal file upload then deleting records from DB
      uploaded_file = fixture_file_upload(fixture)
      user2.update(avatar: uploaded_file)
      user2.uploads.delete_all
      project2.update(avatar: uploaded_file)
      UploadService.new(project2, uploaded_file, FileUploader).execute # Markdown upload
      project2.uploads.delete_all
      appearance.update(header_logo: uploaded_file)
      appearance.uploads.last.destroy
    end

    it 'schedules background migrations' do
      Sidekiq::Testing.inline! do
        migrate!

        # Tracked uploads still exist
        expect(user1.uploads.first.attributes).to include({
          "path" => "uploads/-/system/user/avatar/1/rails_sample.jpg",
          "uploader" => "AvatarUploader"
        })
        expect(project1.uploads.first.attributes).to include({
          "path" => "uploads/-/system/project/avatar/1/rails_sample.jpg",
          "uploader" => "AvatarUploader"
        })
        expect(appearance.uploads.first.attributes).to include({
          "path" => "uploads/-/system/appearance/logo/1/rails_sample.jpg",
          "uploader" => "AttachmentUploader"
        })
        expect(project1.uploads.last.path).to match(/\w+\/rails_sample\.jpg/)
        expect(project1.uploads.last.uploader).to eq('FileUploader')

        # Untracked uploads are now tracked
        expect(user2.uploads.first.attributes).to include({
          "path" => "uploads/-/system/user/avatar/2/rails_sample.jpg",
          "uploader" => "AvatarUploader"
        })
        expect(project2.uploads.first.attributes).to include({
          "path" => "uploads/-/system/project/avatar/2/rails_sample.jpg",
          "uploader" => "AvatarUploader"
        })
        expect(appearance.uploads.count).to eq(2)
        expect(appearance.uploads.last.attributes).to include({
          "path" => "uploads/-/system/appearance/header_logo/1/rails_sample.jpg",
          "uploader" => "AttachmentUploader"
        })
        expect(project2.uploads.last.path).to match(/\w+\/rails_sample\.jpg/)
        expect(project2.uploads.last.uploader).to eq('FileUploader')
      end
    end
  end
end
