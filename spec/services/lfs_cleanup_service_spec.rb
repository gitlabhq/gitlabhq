require 'spec_helper'

describe LfsCleanupService do
  let(:project) { create(:project) }
  let!(:lfs_object) { create(:lfs_object, size: 10.megabytes) }
  let!(:lfs_pointer) { create(:lfs_pointer, project: project, lfs_oid: lfs_object.oid) }
  let!(:lfs_objects_project) { create(:lfs_objects_project, project: project, lfs_object: lfs_object) }
  let!(:processed_lfs_ref) { create(:processed_lfs_ref, project: project) }

  subject(:service) { described_class.new(project) }

  before do
    allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)

    # ProjectCacheWorker skips this becuase no project.repository.exists?
    project.statistics.refresh!(only: [:lfs_objects_size])
  end

  describe '#execute' do
    it 'skips project if it has LFS disabled' do
      allow(Gitlab.config.lfs).to receive(:enabled).and_return(false)

      expect(subject).not_to receive(:delete_unreferenced_pointers!)

      subject.execute
    end

    it 'skips project if no LfsPointers have been detected' do
      lfs_pointer.destroy!

      expect(subject).not_to receive(:delete_unreferenced_pointers!)

      subject.execute
    end

    it 'skips project if newly pushed changes could contain LFS pointers' do
      create(:unprocessed_lfs_push, project: project)

      expect(subject).not_to receive(:delete_unreferenced_pointers!)

      subject.execute
    end

    it 'skips project if no LfsObjects exist to clean up' do
      LfsObject.destroy_all

      expect(subject).not_to receive(:delete_unreferenced_pointers!)

      subject.execute
    end

    context 'with less than 5MB of LFS files in the project' do
      before do
        lfs_object.update!(size: 5.megabytes - 1)
        project.statistics.refresh!(only: [:lfs_objects_size])
      end

      it 'skips cleanup' do
        expect(subject).not_to receive(:delete_unreferenced_pointers!)

        subject.execute
      end
    end

    it 'removes LfsPointers which no longer exist in the project' do
      allow(LfsPointer).to receive(:missing_on_disk).and_return(LfsPointer.where(id: lfs_pointer.id))
      expect(subject).to receive(:delete_unreferenced_pointers!).and_call_original

      expect { subject.execute }.to change(LfsPointer, :count).by(-1)
    end

    describe 'LfsObjectProjects' do
      let!(:project) { create(:project, :repository) }

      it 'are removed when no longer referenced by pointers' do
        allow(LfsPointer).to receive(:missing_on_disk).and_return(LfsPointer.all)

        expect { subject.execute }.to change(LfsObjectsProject, :count).by(-1)
      end

      it 'cause LFS storage statistics to be updated' do
        allow(LfsPointer).to receive(:missing_on_disk).and_return(LfsPointer.all)

        expect(ProjectCacheWorker).to receive(:perform_async).with(project.id, [], [:lfs_objects_size])

        subject.execute
      end

      it "don't cause LfsObjects to be removed" do
        allow(LfsPointer).to receive(:missing_on_disk).and_return(LfsPointer.all)

        expect { subject.execute }.not_to change(LfsObject, :count)
      end

      it "are not removed when pointers haven't been removed" do
        allow(LfsPointer).to receive(:missing_on_disk).and_return(LfsPointer.none)

        expect { subject.execute }.not_to change(LfsObjectsProject, :count)
      end

      it 'are not removed if other pointers still reference them' do
        create(:lfs_pointer, project: project,
                             lfs_oid: lfs_object.oid,
                             blob_oid: 'b7f094b759e6b023278323195812ce1019cb57ff')

        allow(LfsPointer).to receive(:missing_on_disk).and_return(LfsPointer.where(id: lfs_pointer.id))

        expect { subject.execute }.not_to change(LfsObjectsProject, :count)
      end
    end
  end
end
