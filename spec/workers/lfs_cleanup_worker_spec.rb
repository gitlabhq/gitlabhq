require 'spec_helper'

describe LfsCleanupWorker do
  subject(:worker) { described_class.new }

  describe '#perform' do
    let!(:project) { create(:project) }
    let!(:lfs_pointer) { create(:lfs_pointer, project: project) }
    let!(:lfs_objects_project) { create(:lfs_objects_project, project: project) }

    it 'schedules cleanup for individual projects' do
      expect(LfsProjectCleanupWorker).to receive(:perform_async).with(project.id)

      subject.perform
    end

    it 'ignores projects without LfsPointer records' do
      project.lfs_pointers.destroy_all

      expect(LfsProjectCleanupWorker).not_to receive(:perform_async)

      subject.perform
    end

    it 'ignores projects without LfsObject records' do
      project.lfs_pointers.destroy_all

      expect(LfsProjectCleanupWorker).not_to receive(:perform_async)

      subject.perform
    end
  end
end
