require "spec_helper"
require Rails.root.join("db", "post_migrate", "20170317162059_update_upload_paths_to_system.rb")

describe UpdateUploadPathsToSystem do
  let(:migration) { described_class.new }

  before do
    allow(migration).to receive(:say)
  end

  describe "#uploads_to_switch_to_new_path" do
    it "contains only uploads with the old path for the correct models" do
      _upload_for_other_type = create(:upload, model: create(:ci_pipeline), path: "uploads/ci_pipeline/avatar.jpg")
      _upload_with_system_path = create(:upload, model: create(:project), path: "uploads/-/system/project/avatar.jpg")
      _upload_with_other_path = create(:upload, model: create(:project), path: "thelongsecretforafileupload/avatar.jpg")
      old_upload = create(:upload, model: create(:project), path: "uploads/project/avatar.jpg")
      group_upload = create(:upload, model: create(:group), path: "uploads/group/avatar.jpg")

      expect(Upload.where(migration.uploads_to_switch_to_new_path)).to contain_exactly(old_upload, group_upload)
    end
  end

  describe "#uploads_to_switch_to_old_path" do
    it "contains only uploads with the new path for the correct models" do
      _upload_for_other_type = create(:upload, model: create(:ci_pipeline), path: "uploads/ci_pipeline/avatar.jpg")
      upload_with_system_path = create(:upload, model: create(:project), path: "uploads/-/system/project/avatar.jpg")
      _upload_with_other_path = create(:upload, model: create(:project), path: "thelongsecretforafileupload/avatar.jpg")
      _old_upload = create(:upload, model: create(:project), path: "uploads/project/avatar.jpg")

      expect(Upload.where(migration.uploads_to_switch_to_old_path)).to contain_exactly(upload_with_system_path)
    end
  end

  describe "#up", truncate: true do
    it "updates old upload records to the new path" do
      old_upload = create(:upload, model: create(:project), path: "uploads/project/avatar.jpg")

      migration.up

      expect(old_upload.reload.path).to eq("uploads/-/system/project/avatar.jpg")
    end
  end

  describe "#down", truncate: true do
    it "updates the new system patsh to the old paths" do
      new_upload = create(:upload, model: create(:project), path: "uploads/-/system/project/avatar.jpg")

      migration.down

      expect(new_upload.reload.path).to eq("uploads/project/avatar.jpg")
    end
  end
end
