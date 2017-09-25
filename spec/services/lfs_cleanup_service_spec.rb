require 'spec_helper'

describe LfsCleanupService do
  let(:project) { create(:project) }
  let!(:lfs_pointer) { create(:lfs_pointer, project: project) }
  let!(:lfs_objects_project) { create(:lfs_objects_project, project: project) }
  let!(:reference_change) { create(:reference_change, project: project, processed: true) }

  subject(:service) { described_class.new(project) }

  before do
    allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
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

    it "skips project if it hasn't been scanned for LFS pointers" do
      ReferenceChange.destroy_all

      expect(subject).not_to receive(:unreferenced_pointers)

      subject.remove_unreferenced
    end

    it 'skips project if newly pushed changes could contain LFS pointers' do
      reference_change.update!(processed: false)

      expect(subject).not_to receive(:unreferenced_pointers)

      subject.remove_unreferenced
    end

    it 'skips project if no LfsObjects exist to clean up' do
      LfsObject.destroy_all

      expect(subject).not_to receive(:unreferenced_pointers)

      subject.remove_unreferenced
    end

    it 'removes LfsPointers which no longer exist in the project' do
      allow(subject).to receive(:unreferenced_pointers).and_return(LfsPointer.where(id: lfs_pointer.id))

      expect { subject.remove_unreferenced }.to change(LfsPointer, :count).by(-1)
    end

    it 'removes LfsObjectProjects/LfsObjects which are no longer referenced by pointers'

    # xit 'skips projects with less than 5MB of LfsFiles'
  end

  describe '#unreferenced_pointers' do
    let(:removed_pointer_oids) { [lfs_pointer.blob_oid] }

    before do
      allow(Gitlab::Git::Blob).to receive(:batch_blob_existance)
                                          .with(project.repository,
                                                [lfs_pointer.blob_oid],
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
