require 'spec_helper'

describe Gitlab::BackgroundMigration::PrepareUnhashedUploads, :migration, schema: 20171103140253 do
  let!(:unhashed_upload_files) { table(:unhashed_upload_files) }

  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:project1) { create(:project) }
  let(:project2) { create(:project) }
  let(:appearance) { create(:appearance) }

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

    it 'adds unhashed files to the unhashed_upload_files table' do
      expect do
        described_class.new.perform
      end.to change { unhashed_upload_files.count }.from(0).to(5)
    end

    it 'does not add hashed files to the unhashed_upload_files table' do
      described_class.new.perform

      hashed_file_path = project2.uploads.where(uploader: 'FileUploader').first.path
      expect(unhashed_upload_files.where("path like '%#{hashed_file_path}%'").exists?).to be_falsey
    end

    # E.g. from a previous failed run of this background migration
    context 'when there is existing data in unhashed_upload_files' do
      before do
        unhashed_upload_files.create(path: '/foo/bar.jpg')
      end

      it 'clears existing data before adding new data' do
        expect do
          described_class.new.perform
        end.to change { unhashed_upload_files.count }.from(1).to(5)
      end
    end

    # E.g. The installation is in use at the time of migration, and someone has
    # just uploaded a file
    context 'when there are files in /uploads/tmp' do
      before do
        FileUtils.touch(Rails.root.join(described_class::UPLOAD_DIR, 'tmp', 'some_file.jpg'))
      end

      it 'does not add files from /uploads/tmp' do
        expect do
          described_class.new.perform
        end.to change { unhashed_upload_files.count }.from(0).to(5)
      end
    end
  end

  # Very new or lightly-used installations that are running this migration
  # may not have an upload directory because they have no uploads.
  context 'when no files were ever uploaded' do
    it 'does not add to the unhashed_upload_files table (and does not raise error)' do
      expect do
        described_class.new.perform
      end.not_to change { unhashed_upload_files.count }.from(0)
    end
  end
end
