require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20171103140253_track_untracked_uploads')

describe TrackUntrackedUploads, :migration, :sidekiq do
  class UnhashedUploadFile < ActiveRecord::Base
    self.table_name = 'unhashed_upload_files'
  end

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
    migrate!

    max_length_namespace_path = max_length_project_path = max_length_filename = 'a' * 255
    long_path = "./uploads#{"/#{max_length_namespace_path}" * Namespace::NUMBER_OF_ANCESTORS_ALLOWED}/#{max_length_project_path}/#{max_length_filename}"
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
    let(:uploads) { table(:uploads) }

    before do
      fixture = Rails.root.join('spec', 'fixtures', 'rails_sample.jpg')

      # Tracked, by doing normal file upload
      uploaded_file = fixture_file_upload(fixture)
      user1.update(avatar: uploaded_file)
      project1.update(avatar: uploaded_file)
      upload_result = UploadService.new(project1, uploaded_file, FileUploader).execute # Markdown upload
      @project1_markdown_upload_path = upload_result[:url].sub(/\A\/uploads\//, '')
      appearance.update(logo: uploaded_file)

      # Untracked, by doing normal file upload then deleting records from DB
      uploaded_file = fixture_file_upload(fixture)
      user2.update(avatar: uploaded_file)
      user2.uploads.delete_all
      project2.update(avatar: uploaded_file)
      upload_result = UploadService.new(project2, uploaded_file, FileUploader).execute # Markdown upload
      @project2_markdown_upload_path = upload_result[:url].sub(/\A\/uploads\//, '')
      project2.uploads.delete_all
      appearance.update(header_logo: uploaded_file)
      appearance.uploads.last.destroy
    end

    it 'tracks untracked uploads' do
      Sidekiq::Testing.inline! do
        expect do
          migrate!
        end.to change { uploads.count }.from(4).to(8)

        expect(user2.reload.uploads.first.attributes).to include({
          "path" => "uploads/-/system/user/avatar/#{user2.id}/rails_sample.jpg",
          "uploader" => "AvatarUploader"
        }.merge(rails_sample_jpg_attrs))
        expect(project2.reload.uploads.first.attributes).to include({
          "path" => "uploads/-/system/project/avatar/#{project2.id}/rails_sample.jpg",
          "uploader" => "AvatarUploader"
        }.merge(rails_sample_jpg_attrs))
        expect(appearance.reload.uploads.count).to eq(2)
        expect(appearance.uploads.last.attributes).to include({
          "path" => "uploads/-/system/appearance/header_logo/#{appearance.id}/rails_sample.jpg",
          "uploader" => "AttachmentUploader"
        }.merge(rails_sample_jpg_attrs))
        expect(project2.uploads.last.attributes).to include({
          "path" => @project2_markdown_upload_path,
          "uploader" => "FileUploader"
        }.merge(rails_sample_jpg_attrs))
      end
    end

    it 'ignores already-tracked uploads' do
      Sidekiq::Testing.inline! do
        migrate!

        expect(user1.reload.uploads.first.attributes).to include({
          "path" => "uploads/-/system/user/avatar/#{user1.id}/rails_sample.jpg",
          "uploader" => "AvatarUploader"
        }.merge(rails_sample_jpg_attrs))
        expect(project1.reload.uploads.first.attributes).to include({
          "path" => "uploads/-/system/project/avatar/#{project1.id}/rails_sample.jpg",
          "uploader" => "AvatarUploader"
        }.merge(rails_sample_jpg_attrs))
        expect(appearance.reload.uploads.first.attributes).to include({
          "path" => "uploads/-/system/appearance/logo/#{appearance.id}/rails_sample.jpg",
          "uploader" => "AttachmentUploader"
        }.merge(rails_sample_jpg_attrs))
        expect(project1.uploads.last.attributes).to include({
          "path" => @project1_markdown_upload_path,
          "uploader" => "FileUploader"
        }.merge(rails_sample_jpg_attrs))
      end
    end

    it 'all UnhashedUploadFile records are marked as tracked' do
      Sidekiq::Testing.inline! do
        migrate!

        expect(UnhashedUploadFile.count).to eq(8)
        expect(UnhashedUploadFile.count).to eq(UnhashedUploadFile.where(tracked: true).count)
      end
    end
  end

  def rails_sample_jpg_attrs
    {
      "size"       => 35255,
      "checksum"   => 'f2d1fd9d8d8a3368d468fa067888605d74a66f41c16f55979ceaf2af77375844'
    }
  end
end
