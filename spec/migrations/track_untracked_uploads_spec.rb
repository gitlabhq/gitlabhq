require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20171103140253_track_untracked_uploads')

describe TrackUntrackedUploads, :migration, :sidekiq do
  include TrackUntrackedUploadsHelpers

  let(:untracked_files_for_uploads) { table(:untracked_files_for_uploads) }

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

  context 'with tracked and untracked uploads' do
    let!(:appearance) { create(:appearance, logo: uploaded_file, header_logo: uploaded_file) }
    let!(:user1) { create(:user, :with_avatar) }
    let!(:user2) { create(:user, :with_avatar) }
    let!(:project1) { create(:project, :with_avatar) }
    let!(:project2) { create(:project, :with_avatar) }
    let(:uploads) { table(:uploads) }

    before do
      UploadService.new(project1, uploaded_file, FileUploader).execute # Markdown upload
      UploadService.new(project2, uploaded_file, FileUploader).execute # Markdown upload

      # Save expected Upload attributes
      @appearance_logo_attributes = appearance.uploads.where("path like '%/logo/%'").first.attributes.slice('path', 'uploader', 'size', 'checksum')
      @appearance_header_logo_attributes = appearance.uploads.where("path like '%/header_logo/%'").first.attributes.slice('path', 'uploader', 'size', 'checksum')
      @user1_avatar_attributes = user1.uploads.first.attributes.slice('path', 'uploader', 'size', 'checksum')
      @user2_avatar_attributes = user2.uploads.first.attributes.slice('path', 'uploader', 'size', 'checksum')
      @project1_avatar_attributes = project1.uploads.first.attributes.slice('path', 'uploader', 'size', 'checksum')
      @project2_avatar_attributes = project2.uploads.first.attributes.slice('path', 'uploader', 'size', 'checksum')
      @project1_markdown_attributes = project1.uploads.last.attributes.slice('path', 'uploader', 'size', 'checksum')
      @project2_markdown_attributes = project2.uploads.last.attributes.slice('path', 'uploader', 'size', 'checksum')

      # Untrack 4 files
      user2.uploads.delete_all
      project2.uploads.delete_all # 2 files: avatar and a Markdown upload
      appearance.uploads.where("path like '%header_logo%'").delete_all
    end

    it 'tracks untracked uploads' do
      expect do
        migrate!
      end.to change { uploads.count }.from(4).to(8)

      expect(appearance.reload.uploads.where("path like '%/header_logo/%'").first.attributes).to include(@appearance_header_logo_attributes)
      expect(user2.reload.uploads.first.attributes).to include(@user2_avatar_attributes)
      expect(project2.reload.uploads.first.attributes).to include(@project2_avatar_attributes)
      expect(project2.uploads.last.attributes).to include(@project2_markdown_attributes)
    end

    it 'ignores already-tracked uploads' do
      migrate!

      expect(appearance.reload.uploads.where("path like '%/logo/%'").first.attributes).to include(@appearance_logo_attributes)
      expect(user1.reload.uploads.first.attributes).to include(@user1_avatar_attributes)
      expect(project1.reload.uploads.first.attributes).to include(@project1_avatar_attributes)
      expect(project1.uploads.last.attributes).to include(@project1_markdown_attributes)
    end

    it 'the temporary table untracked_files_for_uploads no longer exists' do
      migrate!

      expect(table_exists?(:untracked_files_for_uploads)).to be_falsey
    end
  end
end
