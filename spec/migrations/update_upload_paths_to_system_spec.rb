require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170317162059_update_upload_paths_to_system.rb')

describe UpdateUploadPathsToSystem, :migration do
  let(:migration) { described_class.new }
  let(:uploads_table) { table(:uploads) }
  let(:base_upload_attributes) { { size: 42, uploader: 'John Doe' } }

  before do
    allow(migration).to receive(:say)
  end

  describe '#uploads_to_switch_to_new_path' do
    it 'contains only uploads with the old path for the correct models' do
      _upload_for_other_type = create_upload('Pipeline', 'uploads/ci_pipeline/avatar.jpg')
      _upload_with_system_path = create_upload('Project', 'uploads/-/system/project/avatar.jpg')
      _upload_with_other_path = create_upload('Project', 'thelongsecretforafileupload/avatar.jpg')
      old_upload = create_upload('Project', 'uploads/project/avatar.jpg')
      group_upload = create_upload('Namespace', 'uploads/group/avatar.jpg')

      expect(uploads_table.where(migration.uploads_to_switch_to_new_path)).to contain_exactly(old_upload, group_upload)
    end
  end

  describe '#uploads_to_switch_to_old_path' do
    it 'contains only uploads with the new path for the correct models' do
      _upload_for_other_type = create_upload('Pipeline', 'uploads/ci_pipeline/avatar.jpg')
      upload_with_system_path = create_upload('Project', 'uploads/-/system/project/avatar.jpg')
      _upload_with_other_path = create_upload('Project', 'thelongsecretforafileupload/avatar.jpg')
      _old_upload = create_upload('Project', 'uploads/project/avatar.jpg')

      expect(uploads_table.where(migration.uploads_to_switch_to_old_path)).to contain_exactly(upload_with_system_path)
    end
  end

  describe '#up' do
    it 'updates old upload records to the new path' do
      old_upload = create_upload('Project', 'uploads/project/avatar.jpg')

      migration.up

      expect(old_upload.reload.path).to eq('uploads/-/system/project/avatar.jpg')
    end
  end

  describe '#down' do
    it 'updates the new system patsh to the old paths' do
      new_upload = create_upload('Project', 'uploads/-/system/project/avatar.jpg')

      migration.down

      expect(new_upload.reload.path).to eq('uploads/project/avatar.jpg')
    end
  end

  def create_upload(type, path)
    uploads_table.create(base_upload_attributes.merge(model_type: type, path: path))
  end
end
