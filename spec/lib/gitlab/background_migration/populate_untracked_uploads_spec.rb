require 'spec_helper'

describe Gitlab::BackgroundMigration::PopulateUntrackedUploads, :sidekiq do
  include TrackUntrackedUploadsHelpers

  subject { described_class.new }

  let!(:untracked_files_for_uploads) { described_class::UntrackedFile }
  let!(:uploads) { described_class::Upload }

  before do
    DatabaseCleaner.clean
    drop_temp_table_if_exists
    ensure_temporary_tracking_table_exists
    uploads.delete_all
  end

  after(:all) do
    drop_temp_table_if_exists
  end

  context 'with untracked files and tracked files in untracked_files_for_uploads' do
    let!(:appearance) { create_or_update_appearance(logo: uploaded_file, header_logo: uploaded_file) }
    let!(:user1) { create(:user, :with_avatar) }
    let!(:user2) { create(:user, :with_avatar) }
    let!(:project1) { create(:project, :legacy_storage, :with_avatar) }
    let!(:project2) { create(:project, :legacy_storage, :with_avatar) }

    before do
      UploadService.new(project1, uploaded_file, FileUploader).execute # Markdown upload
      UploadService.new(project2, uploaded_file, FileUploader).execute # Markdown upload

      # File records created by PrepareUntrackedUploads
      untracked_files_for_uploads.create!(path: appearance.uploads.first.path)
      untracked_files_for_uploads.create!(path: appearance.uploads.last.path)
      untracked_files_for_uploads.create!(path: user1.uploads.first.path)
      untracked_files_for_uploads.create!(path: user2.uploads.first.path)
      untracked_files_for_uploads.create!(path: project1.uploads.first.path)
      untracked_files_for_uploads.create!(path: project2.uploads.first.path)
      untracked_files_for_uploads.create!(path: "#{Gitlab::BackgroundMigration::PrepareUntrackedUploads::RELATIVE_UPLOAD_DIR}/#{project1.full_path}/#{project1.uploads.last.path}")
      untracked_files_for_uploads.create!(path: "#{Gitlab::BackgroundMigration::PrepareUntrackedUploads::RELATIVE_UPLOAD_DIR}/#{project2.full_path}/#{project2.uploads.last.path}")

      # Untrack 4 files
      user2.uploads.delete_all
      project2.uploads.delete_all # 2 files: avatar and a Markdown upload
      appearance.uploads.where("path like '%header_logo%'").delete_all
    end

    it 'adds untracked files to the uploads table' do
      expect do
        subject.perform(1, untracked_files_for_uploads.reorder(:id).last.id)
      end.to change { uploads.count }.from(4).to(8)

      expect(user2.uploads.count).to eq(1)
      expect(project2.uploads.count).to eq(2)
      expect(appearance.uploads.count).to eq(2)
    end

    it 'deletes rows after processing them' do
      expect(subject).to receive(:drop_temp_table_if_finished) # Don't drop the table so we can look at it

      expect do
        subject.perform(1, untracked_files_for_uploads.last.id)
      end.to change { untracked_files_for_uploads.count }.from(8).to(0)
    end

    it 'does not create duplicate uploads of already tracked files' do
      subject.perform(1, untracked_files_for_uploads.last.id)

      expect(user1.uploads.count).to eq(1)
      expect(project1.uploads.count).to eq(2)
      expect(appearance.uploads.count).to eq(2)
    end

    it 'uses the start and end batch ids [only 1st half]' do
      ids = untracked_files_for_uploads.all.order(:id).pluck(:id)
      start_id = ids[0]
      end_id = ids[3]

      expect do
        subject.perform(start_id, end_id)
      end.to change { uploads.count }.from(4).to(6)

      expect(user1.uploads.count).to eq(1)
      expect(user2.uploads.count).to eq(1)
      expect(appearance.uploads.count).to eq(2)
      expect(project1.uploads.count).to eq(2)
      expect(project2.uploads.count).to eq(0)

      # Only 4 have been either confirmed or added to uploads
      expect(untracked_files_for_uploads.count).to eq(4)
    end

    it 'uses the start and end batch ids [only 2nd half]' do
      ids = untracked_files_for_uploads.all.order(:id).pluck(:id)
      start_id = ids[4]
      end_id = ids[7]

      expect do
        subject.perform(start_id, end_id)
      end.to change { uploads.count }.from(4).to(6)

      expect(user1.uploads.count).to eq(1)
      expect(user2.uploads.count).to eq(0)
      expect(appearance.uploads.count).to eq(1)
      expect(project1.uploads.count).to eq(2)
      expect(project2.uploads.count).to eq(2)

      # Only 4 have been either confirmed or added to uploads
      expect(untracked_files_for_uploads.count).to eq(4)
    end

    it 'does not drop the temporary tracking table after processing the batch, if there are still untracked rows' do
      subject.perform(1, untracked_files_for_uploads.last.id - 1)

      expect(ActiveRecord::Base.connection.table_exists?(:untracked_files_for_uploads)).to be_truthy
    end

    it 'drops the temporary tracking table after processing the batch, if there are no untracked rows left' do
      subject.perform(1, untracked_files_for_uploads.last.id)

      expect(ActiveRecord::Base.connection.table_exists?(:untracked_files_for_uploads)).to be_falsey
    end

    it 'does not block a whole batch because of one bad path' do
      untracked_files_for_uploads.create!(path: "#{Gitlab::BackgroundMigration::PrepareUntrackedUploads::RELATIVE_UPLOAD_DIR}/#{project2.full_path}/._7d37bf4c747916390e596744117d5d1a")
      expect(untracked_files_for_uploads.count).to eq(9)
      expect(uploads.count).to eq(4)

      subject.perform(1, untracked_files_for_uploads.last.id)

      expect(untracked_files_for_uploads.count).to eq(1)
      expect(uploads.count).to eq(8)
    end

    it 'an unparseable path is shown in error output' do
      bad_path = "#{Gitlab::BackgroundMigration::PrepareUntrackedUploads::RELATIVE_UPLOAD_DIR}/#{project2.full_path}/._7d37bf4c747916390e596744117d5d1a"
      untracked_files_for_uploads.create!(path: bad_path)

      expect(Rails.logger).to receive(:error).with(/Error parsing path "#{bad_path}":/)

      subject.perform(1, untracked_files_for_uploads.last.id)
    end
  end

  context 'with no untracked files' do
    it 'does not add to the uploads table (and does not raise error)' do
      expect do
        subject.perform(1, 1000)
      end.not_to change { uploads.count }.from(0)
    end
  end

  describe 'upload outcomes for each path pattern' do
    shared_examples_for 'non_markdown_file' do
      let!(:expected_upload_attrs) { model.uploads.first.attributes.slice('path', 'uploader', 'size', 'checksum') }
      let!(:untracked_file) { untracked_files_for_uploads.create!(path: expected_upload_attrs['path']) }

      before do
        model.uploads.delete_all
      end

      it 'creates an Upload record' do
        expect do
          subject.perform(1, untracked_files_for_uploads.last.id)
        end.to change { model.reload.uploads.count }.from(0).to(1)

        expect(model.uploads.first.attributes).to include(expected_upload_attrs)
      end
    end

    context 'for an appearance logo file path' do
      let(:model) { create_or_update_appearance(logo: uploaded_file) }

      it_behaves_like 'non_markdown_file'
    end

    context 'for an appearance header_logo file path' do
      let(:model) { create_or_update_appearance(header_logo: uploaded_file) }

      it_behaves_like 'non_markdown_file'
    end

    context 'for a pre-Markdown Note attachment file path' do
      let(:model) { create(:note, :with_attachment) }
      let!(:expected_upload_attrs) { Upload.where(model_type: 'Note', model_id: model.id).first.attributes.slice('path', 'uploader', 'size', 'checksum') }
      let!(:untracked_file) { untracked_files_for_uploads.create!(path: expected_upload_attrs['path']) }

      before do
        Upload.where(model_type: 'Note', model_id: model.id).delete_all
      end

      # Can't use the shared example because Note doesn't have an `uploads` association
      it 'creates an Upload record' do
        expect do
          subject.perform(1, untracked_files_for_uploads.last.id)
        end.to change { Upload.where(model_type: 'Note', model_id: model.id).count }.from(0).to(1)

        expect(Upload.where(model_type: 'Note', model_id: model.id).first.attributes).to include(expected_upload_attrs)
      end
    end

    context 'for a user avatar file path' do
      let(:model) { create(:user, :with_avatar) }

      it_behaves_like 'non_markdown_file'
    end

    context 'for a group avatar file path' do
      let(:model) { create(:group, :with_avatar) }

      it_behaves_like 'non_markdown_file'
    end

    context 'for a project avatar file path' do
      let(:model) { create(:project, :legacy_storage, :with_avatar) }

      it_behaves_like 'non_markdown_file'
    end

    context 'for a project Markdown attachment (notes, issues, MR descriptions) file path' do
      let(:model) { create(:project, :legacy_storage) }

      before do
        # Upload the file
        UploadService.new(model, uploaded_file, FileUploader).execute

        # Create the untracked_files_for_uploads record
        untracked_files_for_uploads.create!(path: "#{Gitlab::BackgroundMigration::PrepareUntrackedUploads::RELATIVE_UPLOAD_DIR}/#{model.full_path}/#{model.uploads.first.path}")

        # Save the expected upload attributes
        @expected_upload_attrs = model.reload.uploads.first.attributes.slice('path', 'uploader', 'size', 'checksum')

        # Untrack the file
        model.reload.uploads.delete_all
      end

      it 'creates an Upload record' do
        expect do
          subject.perform(1, untracked_files_for_uploads.last.id)
        end.to change { model.reload.uploads.count }.from(0).to(1)

        expect(model.uploads.first.attributes).to include(@expected_upload_attrs)
      end
    end
  end
end

describe Gitlab::BackgroundMigration::PopulateUntrackedUploads::UntrackedFile do
  include TrackUntrackedUploadsHelpers

  let(:upload_class) { Gitlab::BackgroundMigration::PopulateUntrackedUploads::Upload }

  before(:all) do
    ensure_temporary_tracking_table_exists
  end

  after(:all) do
    drop_temp_table_if_exists
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
        project = create(:project, :legacy_storage)
        random_hex = SecureRandom.hex

        assert_upload_path("/#{project.full_path}/#{random_hex}/Some file.jpg", "#{random_hex}/Some file.jpg")
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
        project = create(:project, :legacy_storage)

        assert_uploader("/#{project.full_path}/#{SecureRandom.hex}/Some file.jpg", 'FileUploader')
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
        project = create(:project, :legacy_storage)

        assert_model_type("/#{project.full_path}/#{SecureRandom.hex}/Some file.jpg", 'Project')
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
        project = create(:project, :legacy_storage)

        assert_model_id("/#{project.full_path}/#{SecureRandom.hex}/Some file.jpg", project.id)
      end
    end
  end

  describe '#file_size' do
    context 'for an appearance logo file path' do
      let(:appearance) { create_or_update_appearance(logo: uploaded_file) }
      let(:untracked_file) { described_class.create!(path: appearance.uploads.first.path) }

      it 'returns the file size' do
        expect(untracked_file.file_size).to eq(35255)
      end

      it 'returns the same thing that CarrierWave would return' do
        expect(untracked_file.file_size).to eq(appearance.logo.size)
      end
    end

    context 'for a project avatar file path' do
      let(:project) { create(:project, :legacy_storage, avatar: uploaded_file) }
      let(:untracked_file) { described_class.create!(path: project.uploads.first.path) }

      it 'returns the file size' do
        expect(untracked_file.file_size).to eq(35255)
      end

      it 'returns the same thing that CarrierWave would return' do
        expect(untracked_file.file_size).to eq(project.avatar.size)
      end
    end

    context 'for a project Markdown attachment (notes, issues, MR descriptions) file path' do
      let(:project) { create(:project, :legacy_storage) }
      let(:untracked_file) { create_untracked_file("/#{project.full_path}/#{project.uploads.first.path}") }

      before do
        UploadService.new(project, uploaded_file, FileUploader).execute
      end

      it 'returns the file size' do
        expect(untracked_file.file_size).to eq(35255)
      end

      it 'returns the same thing that CarrierWave would return' do
        expect(untracked_file.file_size).to eq(project.uploads.first.size)
      end
    end
  end

  def create_untracked_file(path_relative_to_upload_dir)
    described_class.create!(path: "#{Gitlab::BackgroundMigration::PrepareUntrackedUploads::RELATIVE_UPLOAD_DIR}#{path_relative_to_upload_dir}")
  end
end
