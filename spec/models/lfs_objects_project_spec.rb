require 'spec_helper'

describe LfsObjectsProject do
  subject { create(:lfs_objects_project, project: project) }
  let(:project) { create(:empty_project) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:lfs_object) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:lfs_object_id) }
    it { is_expected.to validate_uniqueness_of(:lfs_object_id).scoped_to(:project_id).with_message("already exists in project") }

    it { is_expected.to validate_presence_of(:project_id) }
  end

  describe '#update_project_statistics' do
    it 'updates project statistics when the object is added' do
      expect(ProjectCacheWorker).to receive(:perform_async)
        .with(project.id, [], [:lfs_objects_size])

      subject.save!
    end

    it 'updates project statistics when the object is removed' do
      subject.save!

      expect(ProjectCacheWorker).to receive(:perform_async)
        .with(project.id, [], [:lfs_objects_size])

      subject.destroy
    end
  end
end
