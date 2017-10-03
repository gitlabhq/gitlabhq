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

  describe '#remove_unreferenced' do
    it 'skips project if it has LFS disabled' do
      allow(Gitlab.config.lfs).to receive(:enabled).and_return(false)

      expect(subject).not_to receive(:unreferenced_pointers)

      subject.remove_unreferenced
    end

    it 'skips project if no LfsPointers have been detected' do
      lfs_pointer.destroy!

      expect(subject).not_to receive(:unreferenced_pointers)

      subject.remove_unreferenced
    end

    it 'skips project if newly pushed changes could contain LFS pointers' do
      create(:unprocessed_lfs_push, project: project)

      expect(subject).not_to receive(:unreferenced_pointers)

      subject.remove_unreferenced
    end

    it 'skips project if no LfsObjects exist to clean up' do
      LfsObject.destroy_all

      expect(subject).not_to receive(:unreferenced_pointers)

      subject.remove_unreferenced
    end

    context 'with less than 5MB of LFS files in the project' do
      before do
        lfs_object.update!(size: 5.megabytes - 1)
        project.statistics.refresh!(only: [:lfs_objects_size])
      end

      it 'skips cleanup' do
        expect(subject).not_to receive(:unreferenced_pointers)

        subject.remove_unreferenced
      end
    end

    it 'removes LfsPointers which no longer exist in the project' do
      allow(subject).to receive(:unreferenced_pointers).and_return(LfsPointer.where(id: lfs_pointer.id))

      expect { subject.remove_unreferenced }.to change(LfsPointer, :count).by(-1)
    end

    describe 'LfsObjectProjects' do
      let!(:project) { create(:project, :repository) }

      it 'are removed when no longer referenced by pointers' do
        allow(subject).to receive(:removed_pointer_oids).and_return([lfs_pointer.blob_oid])

        expect { subject.remove_unreferenced }.to change(LfsObjectsProject, :count).by(-1)
      end

      it 'cause LFS storage statistics to be updated' do
        allow(subject).to receive(:removed_pointer_oids).and_return([lfs_pointer.blob_oid])

        expect(ProjectCacheWorker).to receive(:perform_async).with(project.id, [], [:lfs_objects_size])

        subject.remove_unreferenced
      end

      it "don't cause LfsObjects to be removed" do
        allow(subject).to receive(:removed_pointer_oids).and_return([lfs_pointer.blob_oid])

        expect { subject.remove_unreferenced }.not_to change(LfsObject, :count)
      end

      it "are not removed when pointers haven't been removed" do
        allow(subject).to receive(:removed_pointer_oids).and_return([])

        expect { subject.remove_unreferenced }.not_to change(LfsObjectsProject, :count)
      end

      it 'are not removed if other pointers still reference them' do
        create(:lfs_pointer, project: project,
                             lfs_oid: lfs_object.oid,
                             blob_oid: 'b7f094b759e6b023278323195812ce1019cb57ff')

        allow(subject).to receive(:removed_pointer_oids).and_return([lfs_pointer.blob_oid])

        expect { subject.remove_unreferenced }.not_to change(LfsObjectsProject, :count)
      end
    end
  end

  describe '#unreferenced_pointers' do
    let(:removed_pointer_oids) { [lfs_pointer.blob_oid] }

    before do
      allow(project.repository).to receive(:batch_existence)
                                          .with([lfs_pointer.blob_oid],
                                                existing: false)
                                          .and_return(removed_pointer_oids)
    end

    it 'detects LFS pointers which no longer exist in the project' do
      expect(subject.unreferenced_pointers.first).to eq lfs_pointer
    end

    context 'with no removed pointer blobs' do
      let(:removed_pointer_oids) { [] }

      it 'returns an empty relation' do
        expect(subject.unreferenced_pointers).to be_empty
      end
    end
  end
end
