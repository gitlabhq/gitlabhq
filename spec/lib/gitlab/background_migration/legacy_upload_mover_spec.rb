# frozen_string_literal: true
require 'spec_helper'

# rubocop: disable RSpec/FactoriesInMigrationSpecs
RSpec.describe Gitlab::BackgroundMigration::LegacyUploadMover, :aggregate_failures do
  let(:test_dir) { FileUploader.options['storage_path'] }
  let(:filename) { 'image.png' }

  let!(:namespace) { create(:namespace) }
  let!(:legacy_project) { create(:project, :legacy_storage, namespace: namespace) }
  let!(:hashed_project) { create(:project, namespace: namespace) }
  # default project
  let(:project) { legacy_project }

  let!(:issue) { create(:issue, project: project) }
  let!(:note) { create(:note, note: 'some note', project: project, noteable: issue) }

  let(:legacy_upload) { create_upload(note, filename) }

  def create_remote_upload(model, filename)
    create(
      :upload,
      :attachment_upload,
      path: "note/attachment/#{model.id}/#{filename}",
      secret: nil,
      store: ObjectStorage::Store::REMOTE,
      model: model
    )
  end

  def create_upload(model, filename, with_file = true)
    params = {
      path: "uploads/-/system/note/attachment/#{model.id}/#{filename}",
      model: model,
      store: ObjectStorage::Store::LOCAL
    }

    if with_file
      upload = create(:upload, :with_file, :attachment_upload, params)
      model.update!(attachment: upload.retrieve_uploader)
      model.attachment.upload
    else
      create(:upload, :attachment_upload, params)
    end
  end

  def new_upload
    Upload.find_by(model_id: project.id, model_type: 'Project')
  end

  def expect_error_log
    expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |logger|
      expect(logger).to receive(:warn)
    end
  end

  shared_examples 'legacy upload deletion' do
    it 'removes the upload record' do
      described_class.new(legacy_upload).execute

      expect { legacy_upload.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  shared_examples 'move error' do
    it 'does not remove the upload file' do
      expect_error_log

      described_class.new(legacy_upload).execute

      expect(legacy_upload.reload).to eq(legacy_upload)
    end
  end

  shared_examples 'migrates the file correctly' do |remote|
    it 'creates a new upload record correctly, updates the legacy upload note so that it references the file in the markdown, removes the attachment from the note model, removes the file, moves legacy uploads to the correct location, removes the upload record' do
      expect(File.exist?(legacy_upload.absolute_path)).to be_truthy unless remote

      described_class.new(legacy_upload).execute

      expect(new_upload.secret).not_to be_nil
      expect(new_upload.path).to end_with("#{new_upload.secret}/#{filename}")
      expect(new_upload.model_id).to eq(project.id)
      expect(new_upload.model_type).to eq('Project')
      expect(new_upload.uploader).to eq('FileUploader')

      expected_path = File.join('/uploads', new_upload.secret, filename)
      expected_markdown = "some note \n ![image](#{expected_path})"

      expect(note.reload.note).to eq(expected_markdown)
      expect(note.attachment.file).to be_nil

      if remote
        expect(bucket.files.get(remote_file[:key])).to be_nil
        connection = ::Fog::Storage.new(FileUploader.object_store_credentials)
        expect(connection.get_object('uploads', new_upload.path)[:status]).to eq(200)
      else
        expect(File.exist?(legacy_upload.absolute_path)).to be_falsey
        expected_path = File.join(test_dir, 'uploads', project.disk_path, new_upload.secret, filename)
        expect(File.exist?(expected_path)).to be_truthy
      end

      expect { legacy_upload.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when no note found for the upload' do
    before do
      legacy_upload.model_id = nil
      legacy_upload.model_type = 'Note'
      expect_error_log
    end

    it_behaves_like 'legacy upload deletion'
  end

  context 'when upload does not belong to a note' do
    before do
      legacy_upload.model = create(:appearance)
    end

    it 'does not remove the upload' do
      expect { described_class.new(legacy_upload).execute }.not_to change { Upload.count }
    end
  end

  context 'when the upload move fails' do
    before do
      expect(FileUploader).to receive(:copy_to).and_raise('failed')
    end

    it_behaves_like 'move error'
  end

  context 'when the upload is in local storage' do
    context 'when the upload file does not exist on the filesystem' do
      let(:legacy_upload) { create_upload(note, filename, false) }

      before do
        expect_error_log
      end

      it_behaves_like 'legacy upload deletion'
    end

    context 'when an upload belongs to a legacy_diff_note' do
      let!(:merge_request) { create(:merge_request, :skip_diff_creation, source_project: project) }

      let!(:note) do
        create(:legacy_diff_note_on_merge_request,
          note: 'some note', project: project, noteable: merge_request)
      end

      let(:legacy_upload) do
        create(
          :upload,
          :with_file,
          :attachment_upload,
          path: "uploads/-/system/note/attachment/#{note.id}/#{filename}",
          model: note
        )
      end

      context 'when the file does not exist for the upload' do
        let(:legacy_upload) do
          create(
            :upload,
            :attachment_upload,
            path: "uploads/-/system/note/attachment/#{note.id}/#{filename}",
            model: note
          )
        end

        it_behaves_like 'move error'
      end

      context 'when the file does not exist on expected path' do
        let(:legacy_upload) do
          create(
            :upload,
            :attachment_upload,
            :with_file,
            path: "uploads/-/system/note/attachment/some_part/#{note.id}/#{filename}",
            model: note
          )
        end

        it_behaves_like 'move error'
      end

      context 'when the file path does not include system/note/attachment' do
        let(:legacy_upload) do
          create(
            :upload,
            :attachment_upload,
            :with_file,
            path: "uploads/-/system#{note.id}/#{filename}",
            model: note
          )
        end

        it_behaves_like 'move error'
      end

      context 'when the file move raises an error' do
        before do
          allow(FileUtils).to receive(:mv).and_raise(Errno::EACCES)
        end

        it_behaves_like 'move error'
      end

      context 'when upload has mount_point nil' do
        let(:legacy_upload) do
          create(
            :upload,
            :with_file,
            :attachment_upload,
            path: "uploads/-/system/note/attachment/#{note.id}/#{filename}",
            model: note,
            mount_point: nil
          )
        end

        it_behaves_like 'migrates the file correctly', false
      end

      context 'when the file can be handled correctly' do
        it_behaves_like 'migrates the file correctly', false
      end
    end

    context 'when object storage is disabled for FileUploader' do
      context 'when the file belongs to a legacy project' do
        let(:project) { legacy_project }

        it_behaves_like 'migrates the file correctly', false
      end

      context 'when the file belongs to a hashed project' do
        let(:project) { hashed_project }

        it_behaves_like 'migrates the file correctly', false
      end
    end

    context 'when object storage is enabled for FileUploader' do
      # The process of migrating to object storage is a manual one,
      # so it would go against expectations to automatically migrate these files
      # to object storage during this migration.
      # After this migration, these files should be able to successfully migrate to object storage.

      before do
        stub_uploads_object_storage(FileUploader)
      end

      context 'when the file belongs to a legacy project' do
        let(:project) { legacy_project }

        it_behaves_like 'migrates the file correctly', false
      end

      context 'when the file belongs to a hashed project' do
        let(:project) { hashed_project }

        it_behaves_like 'migrates the file correctly', false
      end
    end
  end

  context 'when legacy uploads are stored in object storage' do
    let(:legacy_upload) { create_remote_upload(note, filename) }
    let(:remote_file) do
      { key: legacy_upload.path.to_s }
    end

    let(:connection) { ::Fog::Storage.new(FileUploader.object_store_credentials) }
    let(:bucket) { connection.directories.create(key: 'uploads') } # rubocop:disable Rails/SaveBang

    before do
      stub_uploads_object_storage(FileUploader)
    end

    context 'when the upload file does not exist on the filesystem' do
      it_behaves_like 'legacy upload deletion'
    end

    context 'when the file belongs to a legacy project' do
      before do
        bucket.files.create(remote_file) # rubocop:disable Rails/SaveBang
      end

      let(:project) { legacy_project }

      it_behaves_like 'migrates the file correctly', true
    end

    context 'when the file belongs to a hashed project' do
      before do
        bucket.files.create(remote_file) # rubocop:disable Rails/SaveBang
      end

      let(:project) { hashed_project }

      it_behaves_like 'migrates the file correctly', true
    end
  end
end
# rubocop: enable RSpec/FactoriesInMigrationSpecs
