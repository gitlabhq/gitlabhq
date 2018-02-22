require 'spec_helper'

# Rollback DB to 10.5 (later than this was originally written for) because it still needs to work.
describe Gitlab::BackgroundMigration::PopulateUntrackedUploadsDependencies::UntrackedFile, :migration, schema: 20180208183958 do
  include MigrationsHelpers::TrackUntrackedUploadsHelpers

  let!(:appearances) { table(:appearances) }
  let!(:namespaces) { table(:namespaces) }
  let!(:projects) { table(:projects) }
  let!(:routes) { table(:routes) }
  let!(:uploads) { table(:uploads) }

  before(:all) do
    ensure_temporary_tracking_table_exists
  end

  describe '#upload_path' do
    def assert_upload_path(file_path, expected_upload_path)
      untracked_file = create_untracked_file(file_path)

      expect(untracked_file.upload_path).to eq(expected_upload_path)
    end

    context 'for an appearance logo file path' do
      it 'returns the file path relative to the CarrierWave root' do
        assert_upload_path('/-/system/appearance/logo/1/some_logo.jpg', 'uploads/-/system/appearance/logo/1/some_logo.jpg')
      end
    end

    context 'for an appearance header_logo file path' do
      it 'returns the file path relative to the CarrierWave root' do
        assert_upload_path('/-/system/appearance/header_logo/1/some_logo.jpg', 'uploads/-/system/appearance/header_logo/1/some_logo.jpg')
      end
    end

    context 'for a pre-Markdown Note attachment file path' do
      it 'returns the file path relative to the CarrierWave root' do
        assert_upload_path('/-/system/note/attachment/1234/some_attachment.pdf', 'uploads/-/system/note/attachment/1234/some_attachment.pdf')
      end
    end

    context 'for a user avatar file path' do
      it 'returns the file path relative to the CarrierWave root' do
        assert_upload_path('/-/system/user/avatar/1234/avatar.jpg', 'uploads/-/system/user/avatar/1234/avatar.jpg')
      end
    end

    context 'for a group avatar file path' do
      it 'returns the file path relative to the CarrierWave root' do
        assert_upload_path('/-/system/group/avatar/1234/avatar.jpg', 'uploads/-/system/group/avatar/1234/avatar.jpg')
      end
    end

    context 'for a project avatar file path' do
      it 'returns the file path relative to the CarrierWave root' do
        assert_upload_path('/-/system/project/avatar/1234/avatar.jpg', 'uploads/-/system/project/avatar/1234/avatar.jpg')
      end
    end

    context 'for a project Markdown attachment (notes, issues, MR descriptions) file path' do
      it 'returns the file path relative to the project directory in uploads' do
        project = create_project
        random_hex = SecureRandom.hex

        assert_upload_path("/#{get_full_path(project)}/#{random_hex}/Some file.jpg", "#{random_hex}/Some file.jpg")
      end
    end
  end

  describe '#uploader' do
    def assert_uploader(file_path, expected_uploader)
      untracked_file = create_untracked_file(file_path)

      expect(untracked_file.uploader).to eq(expected_uploader)
    end

    context 'for an appearance logo file path' do
      it 'returns AttachmentUploader as a string' do
        assert_uploader('/-/system/appearance/logo/1/some_logo.jpg', 'AttachmentUploader')
      end
    end

    context 'for an appearance header_logo file path' do
      it 'returns AttachmentUploader as a string' do
        assert_uploader('/-/system/appearance/header_logo/1/some_logo.jpg', 'AttachmentUploader')
      end
    end

    context 'for a pre-Markdown Note attachment file path' do
      it 'returns AttachmentUploader as a string' do
        assert_uploader('/-/system/note/attachment/1234/some_attachment.pdf', 'AttachmentUploader')
      end
    end

    context 'for a user avatar file path' do
      it 'returns AvatarUploader as a string' do
        assert_uploader('/-/system/user/avatar/1234/avatar.jpg', 'AvatarUploader')
      end
    end

    context 'for a group avatar file path' do
      it 'returns AvatarUploader as a string' do
        assert_uploader('/-/system/group/avatar/1234/avatar.jpg', 'AvatarUploader')
      end
    end

    context 'for a project avatar file path' do
      it 'returns AvatarUploader as a string' do
        assert_uploader('/-/system/project/avatar/1234/avatar.jpg', 'AvatarUploader')
      end
    end

    context 'for a project Markdown attachment (notes, issues, MR descriptions) file path' do
      it 'returns FileUploader as a string' do
        project = create_project

        assert_uploader("/#{get_full_path(project)}/#{SecureRandom.hex}/Some file.jpg", 'FileUploader')
      end
    end
  end

  describe '#model_type' do
    def assert_model_type(file_path, expected_model_type)
      untracked_file = create_untracked_file(file_path)

      expect(untracked_file.model_type).to eq(expected_model_type)
    end

    context 'for an appearance logo file path' do
      it 'returns Appearance as a string' do
        assert_model_type('/-/system/appearance/logo/1/some_logo.jpg', 'Appearance')
      end
    end

    context 'for an appearance header_logo file path' do
      it 'returns Appearance as a string' do
        assert_model_type('/-/system/appearance/header_logo/1/some_logo.jpg', 'Appearance')
      end
    end

    context 'for a pre-Markdown Note attachment file path' do
      it 'returns Note as a string' do
        assert_model_type('/-/system/note/attachment/1234/some_attachment.pdf', 'Note')
      end
    end

    context 'for a user avatar file path' do
      it 'returns User as a string' do
        assert_model_type('/-/system/user/avatar/1234/avatar.jpg', 'User')
      end
    end

    context 'for a group avatar file path' do
      it 'returns Namespace as a string' do
        assert_model_type('/-/system/group/avatar/1234/avatar.jpg', 'Namespace')
      end
    end

    context 'for a project avatar file path' do
      it 'returns Project as a string' do
        assert_model_type('/-/system/project/avatar/1234/avatar.jpg', 'Project')
      end
    end

    context 'for a project Markdown attachment (notes, issues, MR descriptions) file path' do
      it 'returns Project as a string' do
        project = create_project

        assert_model_type("/#{get_full_path(project)}/#{SecureRandom.hex}/Some file.jpg", 'Project')
      end
    end
  end

  describe '#model_id' do
    def assert_model_id(file_path, expected_model_id)
      untracked_file = create_untracked_file(file_path)

      expect(untracked_file.model_id).to eq(expected_model_id)
    end

    context 'for an appearance logo file path' do
      it 'returns the ID as a string' do
        assert_model_id('/-/system/appearance/logo/1/some_logo.jpg', 1)
      end
    end

    context 'for an appearance header_logo file path' do
      it 'returns the ID as a string' do
        assert_model_id('/-/system/appearance/header_logo/1/some_logo.jpg', 1)
      end
    end

    context 'for a pre-Markdown Note attachment file path' do
      it 'returns the ID as a string' do
        assert_model_id('/-/system/note/attachment/1234/some_attachment.pdf', 1234)
      end
    end

    context 'for a user avatar file path' do
      it 'returns the ID as a string' do
        assert_model_id('/-/system/user/avatar/1234/avatar.jpg', 1234)
      end
    end

    context 'for a group avatar file path' do
      it 'returns the ID as a string' do
        assert_model_id('/-/system/group/avatar/1234/avatar.jpg', 1234)
      end
    end

    context 'for a project avatar file path' do
      it 'returns the ID as a string' do
        assert_model_id('/-/system/project/avatar/1234/avatar.jpg', 1234)
      end
    end

    context 'for a project Markdown attachment (notes, issues, MR descriptions) file path' do
      it 'returns the ID as a string' do
        project = create_project

        assert_model_id("/#{get_full_path(project)}/#{SecureRandom.hex}/Some file.jpg", project.id)
      end
    end
  end

  describe '#file_size' do
    context 'for an appearance logo file path' do
      let(:appearance) { create_or_update_appearance(logo: true) }
      let(:untracked_file) { described_class.create!(path: get_uploads(appearance, 'Appearance').first.path) }

      it 'returns the file size' do
        expect(untracked_file.file_size).to eq(1062)
      end
    end

    context 'for a project avatar file path' do
      let(:project) { create_project(avatar: true) }
      let(:untracked_file) { described_class.create!(path: get_uploads(project, 'Project').first.path) }

      it 'returns the file size' do
        expect(untracked_file.file_size).to eq(1062)
      end
    end

    context 'for a project Markdown attachment (notes, issues, MR descriptions) file path' do
      let(:project) { create_project }
      let(:untracked_file) { create_untracked_file("/#{get_full_path(project)}/#{get_uploads(project, 'Project').first.path}") }

      before do
        add_markdown_attachment(project)
      end

      it 'returns the file size' do
        expect(untracked_file.file_size).to eq(1062)
      end
    end
  end

  def create_untracked_file(path_relative_to_upload_dir)
    described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUntrackedUploads::RELATIVE_UPLOAD_DIR}#{path_relative_to_upload_dir}")
  end
end
