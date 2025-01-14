# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateInvalidCiDeletedObjectRecords, feature_category: :job_artifacts, migration: :gitlab_ci do
  let!(:ci_deleted_objects) { table(:ci_deleted_objects) }

  describe '#up' do
    before do
      ci_deleted_objects.create!(project_id: 1, pick_up_at: Time.current, store_dir: "dir", file: "file1")
      ci_deleted_objects.create!(project_id: nil, pick_up_at: Time.current, store_dir: "dir", file: "file2")
      ci_deleted_objects.create!(project_id: nil, pick_up_at: Time.current, store_dir: "dir", file: "file3")

      stub_const("#{described_class}::BATCH_SIZE", 1)
    end

    it 'sets project_id to -1 for records without a project_id' do
      migrate!

      expect(ci_deleted_objects.first).to have_attributes(project_id: 1)
      expect(ci_deleted_objects.second).to have_attributes(project_id: -1)
      expect(ci_deleted_objects.third).to have_attributes(project_id: -1)
    end

    it 'does nothing on gitlab.com' do
      allow(Gitlab).to receive(:com?).and_return(true)

      migrate!

      expect(ci_deleted_objects.first).to have_attributes(project_id: 1)
      expect(ci_deleted_objects.second).to have_attributes(project_id: nil)
      expect(ci_deleted_objects.third).to have_attributes(project_id: nil)
    end
  end
end
