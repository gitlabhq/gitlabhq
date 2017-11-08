require 'spec_helper'

describe Gitlab::BackgroundMigration::PopulateUntrackedUploads, :migration, :sidekiq, schema: 20171103140253 do
  let!(:unhashed_upload_files) { table(:unhashed_upload_files) }
  let!(:uploads) { table(:uploads) }

  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:project1) { create(:project) }
  let(:project2) { create(:project) }
  let(:appearance) { create(:appearance) }

  context 'with untracked files and tracked files in unhashed_upload_files' do
    before do
      fixture = Rails.root.join('spec', 'fixtures', 'rails_sample.jpg')

      # Tracked, by doing normal file upload
      uploaded_file = fixture_file_upload(fixture)
      user1.update!(avatar: uploaded_file)
      project1.update!(avatar: uploaded_file)
      UploadService.new(project1, uploaded_file, FileUploader).execute # Markdown upload
      appearance.update!(logo: uploaded_file)

      # Untracked, by doing normal file upload then later deleting records from DB
      uploaded_file = fixture_file_upload(fixture)
      user2.update!(avatar: uploaded_file)
      project2.update!(avatar: uploaded_file)
      UploadService.new(project2, uploaded_file, FileUploader).execute # Markdown upload
      appearance.update!(header_logo: uploaded_file)

      # Unhashed upload files created by PrepareUnhashedUploads
      unhashed_upload_files.create!(path: appearance.logo.file.file)
      unhashed_upload_files.create!(path: appearance.header_logo.file.file)
      unhashed_upload_files.create!(path: user1.avatar.file.file)
      unhashed_upload_files.create!(path: user2.avatar.file.file)
      unhashed_upload_files.create!(path: project1.avatar.file.file)
      unhashed_upload_files.create!(path: project2.avatar.file.file)
      unhashed_upload_files.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/#{project1.full_path}/#{project1.uploads.last.path}")
      unhashed_upload_files.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/#{project2.full_path}/#{project2.uploads.last.path}")

      user2.uploads.delete_all
      project2.uploads.delete_all
      appearance.uploads.last.destroy
    end

    it 'adds untracked files to the uploads table' do
      expect do
        described_class.new.perform(1, 1000)
      end.to change { uploads.count }.from(4).to(8)

      expect(user2.uploads.count).to eq(1)
      expect(project2.uploads.count).to eq(2)
      expect(appearance.uploads.count).to eq(2)
    end

    it 'does not create duplicate uploads of already tracked files' do
      described_class.new.perform(1, 1000)

      expect(user1.uploads.count).to eq(1)
      expect(project1.uploads.count).to eq(2)
      expect(appearance.uploads.count).to eq(2)
    end
  end

  context 'with no untracked files' do
    it 'does not add to the uploads table (and does not raise error)' do
      expect do
        described_class.new.perform(1, 1000)
      end.not_to change { uploads.count }.from(0)
    end
  end
end

describe Gitlab::BackgroundMigration::PopulateUntrackedUploads::UnhashedUploadFile do
  let(:upload_class) { Gitlab::BackgroundMigration::PopulateUntrackedUploads::Upload }

  describe '#ensure_tracked!' do
    let(:user1) { create(:user) }

    context 'when the file is already in the uploads table' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/user/avatar/#{user1.id}/avatar.jpg") }

      before do
        upload_class.create!(path: "uploads/-/system/user/avatar/#{user1.id}/avatar.jpg", uploader: 'AvatarUploader', model_type: 'User', model_id: user1.id, size: 1234)
      end

      it 'does not add an upload' do
        expect do
          unhashed_upload_file.ensure_tracked!
        end.to_not change { upload_class.count }.from(1)
      end
    end
  end

  describe '#add_to_uploads' do
    let(:fixture) { Rails.root.join('spec', 'fixtures', 'rails_sample.jpg') }
    let(:uploaded_file) { fixture_file_upload(fixture) }

    context 'for an appearance logo file path' do
      let(:appearance) { create(:appearance) }
      let(:unhashed_upload_file) { described_class.create!(path: appearance.logo.file.file) }

      before do
        appearance.update!(logo: uploaded_file)
        appearance.uploads.delete_all
      end

      it 'creates an Upload record' do
        expect do
          unhashed_upload_file.add_to_uploads
        end.to change { upload_class.count }.from(0).to(1)

        expect(upload_class.first.attributes).to include({
          "size"       => 35255,
          "path"       => "uploads/-/system/appearance/logo/#{appearance.id}/rails_sample.jpg",
          "checksum"   => nil,
          "model_id"   => appearance.id,
          "model_type" => "Appearance",
          "uploader"   => "AttachmentUploader"
        })
      end
    end

    context 'for an appearance header_logo file path' do
      let(:appearance) { create(:appearance) }
      let(:unhashed_upload_file) { described_class.create!(path: appearance.header_logo.file.file) }

      before do
        appearance.update!(header_logo: uploaded_file)
        appearance.uploads.delete_all
      end

      it 'creates an Upload record' do
        expect do
          unhashed_upload_file.add_to_uploads
        end.to change { upload_class.count }.from(0).to(1)

        expect(upload_class.first.attributes).to include({
          "size"       => 35255,
          "path"       => "uploads/-/system/appearance/header_logo/#{appearance.id}/rails_sample.jpg",
          "checksum"   => nil,
          "model_id"   => appearance.id,
          "model_type" => "Appearance",
          "uploader"   => "AttachmentUploader"
        })
      end
    end

    context 'for a pre-Markdown Note attachment file path' do
      let(:note) { create(:note) }
      let(:unhashed_upload_file) { described_class.create!(path: note.attachment.file.file) }

      before do
        note.update!(attachment: uploaded_file)
        upload_class.delete_all
      end

      it 'creates an Upload record' do
        expect do
          unhashed_upload_file.add_to_uploads
        end.to change { upload_class.count }.from(0).to(1)

        expect(upload_class.first.attributes).to include({
          "size"       => 35255,
          "path"       => "uploads/-/system/note/attachment/#{note.id}/rails_sample.jpg",
          "checksum"   => nil,
          "model_id"   => note.id,
          "model_type" => "Note",
          "uploader"   => "AttachmentUploader"
        })
      end
    end

    context 'for a user avatar file path' do
      let(:user) { create(:user) }
      let(:unhashed_upload_file) { described_class.create!(path: user.avatar.file.file) }

      before do
        user.update!(avatar: uploaded_file)
        upload_class.delete_all
      end

      it 'creates an Upload record' do
        expect do
          unhashed_upload_file.add_to_uploads
        end.to change { upload_class.count }.from(0).to(1)

        expect(upload_class.first.attributes).to include({
          "size"       => 35255,
          "path"       => "uploads/-/system/user/avatar/#{user.id}/rails_sample.jpg",
          "checksum"   => nil,
          "model_id"   => user.id,
          "model_type" => "User",
          "uploader"   => "AvatarUploader"
        })
      end
    end

    context 'for a group avatar file path' do
      let(:group) { create(:group) }
      let(:unhashed_upload_file) { described_class.create!(path: group.avatar.file.file) }

      before do
        group.update!(avatar: uploaded_file)
        upload_class.delete_all
      end

      it 'creates an Upload record' do
        expect do
          unhashed_upload_file.add_to_uploads
        end.to change { upload_class.count }.from(0).to(1)

        expect(upload_class.first.attributes).to include({
          "size"       => 35255,
          "path"       => "uploads/-/system/group/avatar/#{group.id}/rails_sample.jpg",
          "checksum"   => nil,
          "model_id"   => group.id,
          "model_type" => "Group",
          "uploader"   => "AvatarUploader"
        })
      end
    end

    context 'for a project avatar file path' do
      let(:project) { create(:project) }
      let(:unhashed_upload_file) { described_class.create!(path: project.avatar.file.file) }

      before do
        project.update!(avatar: uploaded_file)
        upload_class.delete_all
      end

      it 'creates an Upload record' do
        expect do
          unhashed_upload_file.add_to_uploads
        end.to change { upload_class.count }.from(0).to(1)

        expect(upload_class.first.attributes).to include({
          "size"       => 35255,
          "path"       => "uploads/-/system/project/avatar/#{project.id}/rails_sample.jpg",
          "checksum"   => nil,
          "model_id"   => project.id,
          "model_type" => "Project",
          "uploader"   => "AvatarUploader"
        })
      end
    end

    context 'for a project Markdown attachment (notes, issues, MR descriptions) file path' do
      let(:project) { create(:project) }
      let(:unhashed_upload_file) { described_class.new(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/#{project.full_path}/#{project.uploads.first.path}") }

      before do
        UploadService.new(project, uploaded_file, FileUploader).execute # Markdown upload
        unhashed_upload_file.save!
        upload_class.delete_all
      end

      it 'creates an Upload record' do
        expect do
          unhashed_upload_file.add_to_uploads
        end.to change { upload_class.count }.from(0).to(1)

        random_hex = unhashed_upload_file.path.match(/\/(\h+)\/rails_sample.jpg/)[1]
        expect(upload_class.first.attributes).to include({
          "size"       => 35255,
          "path"       => "#{random_hex}/rails_sample.jpg",
          "checksum"   => nil,
          "model_id"   => project.id,
          "model_type" => "Project",
          "uploader"   => "FileUploader"
        })
      end
    end
  end

  describe '#mark_as_tracked' do
    let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/appearance/logo/1/some_logo.jpg") }

    it 'saves the record with tracked set to true' do
      expect do
        unhashed_upload_file.mark_as_tracked
      end.to change { unhashed_upload_file.tracked }.from(false).to(true)

      expect(unhashed_upload_file.persisted?).to be_truthy
    end
  end

  describe '#upload_path' do
    context 'for an appearance logo file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/appearance/logo/1/some_logo.jpg") }

      it 'returns the file path relative to the CarrierWave root' do
        expect(unhashed_upload_file.upload_path).to eq('uploads/-/system/appearance/logo/1/some_logo.jpg')
      end
    end

    context 'for an appearance header_logo file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/appearance/header_logo/1/some_logo.jpg") }

      it 'returns the file path relative to the CarrierWave root' do
        expect(unhashed_upload_file.upload_path).to eq('uploads/-/system/appearance/header_logo/1/some_logo.jpg')
      end
    end

    context 'for a pre-Markdown Note attachment file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/note/attachment/1234/some_attachment.pdf") }

      it 'returns the file path relative to the CarrierWave root' do
        expect(unhashed_upload_file.upload_path).to eq('uploads/-/system/note/attachment/1234/some_attachment.pdf')
      end
    end

    context 'for a user avatar file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/user/avatar/1234/avatar.jpg") }

      it 'returns the file path relative to the CarrierWave root' do
        expect(unhashed_upload_file.upload_path).to eq('uploads/-/system/user/avatar/1234/avatar.jpg')
      end
    end

    context 'for a group avatar file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/group/avatar/1234/avatar.jpg") }

      it 'returns the file path relative to the CarrierWave root' do
        expect(unhashed_upload_file.upload_path).to eq('uploads/-/system/group/avatar/1234/avatar.jpg')
      end
    end

    context 'for a project avatar file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/project/avatar/1234/avatar.jpg") }

      it 'returns the file path relative to the CarrierWave root' do
        expect(unhashed_upload_file.upload_path).to eq('uploads/-/system/project/avatar/1234/avatar.jpg')
      end
    end

    context 'for a project Markdown attachment (notes, issues, MR descriptions) file path' do
      let(:project) { create(:project) }
      let(:random_hex) { SecureRandom.hex }
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/#{project.full_path}/#{random_hex}/Some file.jpg") }

      it 'returns the file path relative to the project directory in uploads' do
        expect(unhashed_upload_file.upload_path).to eq("#{random_hex}/Some file.jpg")
      end
    end
  end

  describe '#uploader' do
    context 'for an appearance logo file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/appearance/logo/1/some_logo.jpg") }

      it 'returns AttachmentUploader as a string' do
        expect(unhashed_upload_file.uploader).to eq('AttachmentUploader')
      end
    end

    context 'for an appearance header_logo file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/appearance/header_logo/1/some_logo.jpg") }

      it 'returns AttachmentUploader as a string' do
        expect(unhashed_upload_file.uploader).to eq('AttachmentUploader')
      end
    end

    context 'for a pre-Markdown Note attachment file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/note/attachment/1234/some_attachment.pdf") }

      it 'returns AttachmentUploader as a string' do
        expect(unhashed_upload_file.uploader).to eq('AttachmentUploader')
      end
    end

    context 'for a user avatar file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/user/avatar/1234/avatar.jpg") }

      it 'returns AvatarUploader as a string' do
        expect(unhashed_upload_file.uploader).to eq('AvatarUploader')
      end
    end

    context 'for a group avatar file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/group/avatar/1234/avatar.jpg") }

      it 'returns AvatarUploader as a string' do
        expect(unhashed_upload_file.uploader).to eq('AvatarUploader')
      end
    end

    context 'for a project avatar file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/project/avatar/1234/avatar.jpg") }

      it 'returns AvatarUploader as a string' do
        expect(unhashed_upload_file.uploader).to eq('AvatarUploader')
      end
    end

    context 'for a project Markdown attachment (notes, issues, MR descriptions) file path' do
      let(:project) { create(:project) }
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/#{project.full_path}/#{SecureRandom.hex}/Some file.jpg") }

      it 'returns FileUploader as a string' do
        expect(unhashed_upload_file.uploader).to eq('FileUploader')
      end
    end
  end

  describe '#model_type' do
    context 'for an appearance logo file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/appearance/logo/1/some_logo.jpg") }

      it 'returns Appearance as a string' do
        expect(unhashed_upload_file.model_type).to eq('Appearance')
      end
    end

    context 'for an appearance header_logo file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/appearance/header_logo/1/some_logo.jpg") }

      it 'returns Appearance as a string' do
        expect(unhashed_upload_file.model_type).to eq('Appearance')
      end
    end

    context 'for a pre-Markdown Note attachment file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/note/attachment/1234/some_attachment.pdf") }

      it 'returns Note as a string' do
        expect(unhashed_upload_file.model_type).to eq('Note')
      end
    end

    context 'for a user avatar file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/user/avatar/1234/avatar.jpg") }

      it 'returns User as a string' do
        expect(unhashed_upload_file.model_type).to eq('User')
      end
    end

    context 'for a group avatar file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/group/avatar/1234/avatar.jpg") }

      it 'returns Group as a string' do
        expect(unhashed_upload_file.model_type).to eq('Group')
      end
    end

    context 'for a project avatar file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/project/avatar/1234/avatar.jpg") }

      it 'returns Project as a string' do
        expect(unhashed_upload_file.model_type).to eq('Project')
      end
    end

    context 'for a project Markdown attachment (notes, issues, MR descriptions) file path' do
      let(:project) { create(:project) }
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/#{project.full_path}/#{SecureRandom.hex}/Some file.jpg") }

      it 'returns Project as a string' do
        expect(unhashed_upload_file.model_type).to eq('Project')
      end
    end
  end

  describe '#model_id' do
    context 'for an appearance logo file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/appearance/logo/1/some_logo.jpg") }

      it 'returns the ID as a string' do
        expect(unhashed_upload_file.model_id).to eq('1')
      end
    end

    context 'for an appearance header_logo file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/appearance/header_logo/1/some_logo.jpg") }

      it 'returns the ID as a string' do
        expect(unhashed_upload_file.model_id).to eq('1')
      end
    end

    context 'for a pre-Markdown Note attachment file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/note/attachment/1234/some_attachment.pdf") }

      it 'returns the ID as a string' do
        expect(unhashed_upload_file.model_id).to eq('1234')
      end
    end

    context 'for a user avatar file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/user/avatar/1234/avatar.jpg") }

      it 'returns the ID as a string' do
        expect(unhashed_upload_file.model_id).to eq('1234')
      end
    end

    context 'for a group avatar file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/group/avatar/1234/avatar.jpg") }

      it 'returns the ID as a string' do
        expect(unhashed_upload_file.model_id).to eq('1234')
      end
    end

    context 'for a project avatar file path' do
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/-/system/project/avatar/1234/avatar.jpg") }

      it 'returns the ID as a string' do
        expect(unhashed_upload_file.model_id).to eq('1234')
      end
    end

    context 'for a project Markdown attachment (notes, issues, MR descriptions) file path' do
      let(:project) { create(:project) }
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/#{project.full_path}/#{SecureRandom.hex}/Some file.jpg") }

      it 'returns the ID as a string' do
        expect(unhashed_upload_file.model_id).to eq(project.id.to_s)
      end
    end
  end

  describe '#file_size' do
    let(:fixture) { Rails.root.join('spec', 'fixtures', 'rails_sample.jpg') }
    let(:uploaded_file) { fixture_file_upload(fixture) }

    context 'for an appearance logo file path' do
      let(:appearance) { create(:appearance) }
      let(:unhashed_upload_file) { described_class.create!(path: appearance.logo.file.file) }

      before do
        appearance.update!(logo: uploaded_file)
      end

      it 'returns the file size' do
        expect(unhashed_upload_file.file_size).to eq(35255)
      end

      it 'returns the same thing that CarrierWave would return' do
        expect(unhashed_upload_file.file_size).to eq(appearance.logo.size)
      end
    end

    context 'for a project avatar file path' do
      let(:project) { create(:project) }
      let(:unhashed_upload_file) { described_class.create!(path: project.avatar.file.file) }

      before do
        project.update!(avatar: uploaded_file)
      end

      it 'returns the file size' do
        expect(unhashed_upload_file.file_size).to eq(35255)
      end

      it 'returns the same thing that CarrierWave would return' do
        expect(unhashed_upload_file.file_size).to eq(project.avatar.size)
      end
    end

    context 'for a project Markdown attachment (notes, issues, MR descriptions) file path' do
      let(:project) { create(:project) }
      let(:unhashed_upload_file) { described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}/#{project.full_path}/#{project.uploads.first.path}") }

      before do
        UploadService.new(project, uploaded_file, FileUploader).execute
      end

      it 'returns the file size' do
        expect(unhashed_upload_file.file_size).to eq(35255)
      end

      it 'returns the same thing that CarrierWave would return' do
        expect(unhashed_upload_file.file_size).to eq(project.uploads.first.size)
      end
    end
  end
end
