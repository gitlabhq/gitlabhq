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

  it 'ensures the untracked_files_for_uploads table exists' do
    expect do
      migrate!
    end.to change { table_exists?(:untracked_files_for_uploads) }.from(false).to(true)
  end

  it 'has a path field long enough for really long paths' do
    migrate!

    component = 'a'*255

    long_path = [
      'uploads',
      component, # project.full_path
      component  # filename
    ].flatten.join('/')

    record = untracked_files_for_uploads.create!(path: long_path)
    expect(record.reload.path.size).to eq(519)
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
      Sidekiq::Testing.inline! do
        expect do
          migrate!
        end.to change { uploads.count }.from(4).to(8)

        expect(appearance.reload.uploads.where("path like '%/header_logo/%'").first.attributes).to include(@appearance_header_logo_attributes)
        expect(user2.reload.uploads.first.attributes).to include(@user2_avatar_attributes)
        expect(project2.reload.uploads.first.attributes).to include(@project2_avatar_attributes)
        expect(project2.uploads.last.attributes).to include(@project2_markdown_attributes)
      end
    end

    it 'ignores already-tracked uploads' do
      Sidekiq::Testing.inline! do
        migrate!

        expect(appearance.reload.uploads.where("path like '%/logo/%'").first.attributes).to include(@appearance_logo_attributes)
        expect(user1.reload.uploads.first.attributes).to include(@user1_avatar_attributes)
        expect(project1.reload.uploads.first.attributes).to include(@project1_avatar_attributes)
        expect(project1.uploads.last.attributes).to include(@project1_markdown_attributes)
      end
    end

    it 'all untracked_files_for_uploads records are marked as tracked' do
      Sidekiq::Testing.inline! do
        migrate!

        expect(untracked_files_for_uploads.count).to eq(8)
        expect(untracked_files_for_uploads.count).to eq(untracked_files_for_uploads.where(tracked: true).count)
      end
    end
  end
end
