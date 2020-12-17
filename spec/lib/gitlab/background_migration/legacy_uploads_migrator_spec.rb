# frozen_string_literal: true
require 'spec_helper'

# rubocop: disable RSpec/FactoriesInMigrationSpecs
RSpec.describe Gitlab::BackgroundMigration::LegacyUploadsMigrator do
  let(:test_dir) { FileUploader.options['storage_path'] }

  let!(:hashed_project) { create(:project) }
  let!(:legacy_project) { create(:project, :legacy_storage) }
  let!(:issue) { create(:issue, project: hashed_project) }
  let!(:issue_legacy) { create(:issue, project: legacy_project) }

  let!(:note1) { create(:note, project: hashed_project, noteable: issue) }
  let!(:note2) { create(:note, project: hashed_project, noteable: issue) }
  let!(:note_legacy) { create(:note, project: legacy_project, noteable: issue_legacy) }

  def create_upload(model, with_file = true)
    filename = 'image.png'
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

  let!(:legacy_upload) { create_upload(note1) }
  let!(:legacy_upload_no_file) { create_upload(note2, false) }
  let!(:legacy_upload_legacy_project) { create_upload(note_legacy) }

  let!(:appearance) { create(:appearance, :with_logo) }

  let(:start_id) { 1 }
  let(:end_id) { 10000 }

  subject { described_class.new.perform(start_id, end_id) }

  it 'removes all legacy files' do
    expect(File.exist?(legacy_upload.absolute_path)).to be_truthy
    expect(File.exist?(legacy_upload_no_file.absolute_path)).to be_falsey
    expect(File.exist?(legacy_upload_legacy_project.absolute_path)).to be_truthy

    subject

    expect(File.exist?(legacy_upload.absolute_path)).to be_falsey
    expect(File.exist?(legacy_upload_no_file.absolute_path)).to be_falsey
    expect(File.exist?(legacy_upload_legacy_project.absolute_path)).to be_falsey
  end

  it 'removes all Note AttachmentUploader records' do
    expect { subject }.to change { Upload.where(uploader: 'AttachmentUploader').count }.from(4).to(1)
  end

  it 'creates new uploads for successfully migrated records' do
    expect { subject }.to change { Upload.where(uploader: 'FileUploader').count }.from(0).to(2)
  end

  it 'does not remove appearance uploads' do
    subject

    expect(appearance.logo.file).to exist
  end
end
# rubocop: enable RSpec/FactoriesInMigrationSpecs
