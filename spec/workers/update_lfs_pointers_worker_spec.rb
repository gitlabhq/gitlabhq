require 'spec_helper'

describe UpdateLfsPointersWorker do
  subject(:worker) { described_class.new }

  describe '#perform' do
    let(:project) { create(:project, :repository) }
    let!(:unprocessed_lfs_push) { create(:unprocessed_lfs_push, project: project) }
    let(:blob_object) { project.repository.blob_at_branch('lfs', 'files/lfs/lfs_object.iso') }

    before do
      allow_any_instance_of(Gitlab::Git::RevList).to receive(:new_objects).and_return([blob_object.id])
    end

    def perform
      subject.perform(unprocessed_lfs_push.id)
    end

    context 'with LFS not enabled' do
      before do
        allow(Gitlab.config.lfs).to receive(:enabled).and_return(false)
      end

      it 'skips processing' do
        expect(Gitlab::Git::LfsChanges).not_to receive(:new)

        perform
      end
    end

    context 'with LFS enabled' do
      before do
        allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
      end

      it 'processes new lfs pointers' do
        expect(Gitlab::Git::LfsChanges).to receive(:new).and_call_original

        perform
      end

      it 'removes the updated reference from unprocessed_lfs_pushes' do
        expect { perform }.to change { project.reload.unprocessed_lfs_pushes.count }.by(-1)
      end

      it 'creates a ProcessedLfsRef for the reference' do
        expect { perform }.to change { project.processed_lfs_refs.count }.by(1)
      end

      it 'creates a LfsPointer record for each new blob' do
        expect { perform }.to change(LfsPointer, :count).by(1)
      end

      it 'looks up LFS pointers for the new ref' do
        expect(Gitlab::Git::RevList).to receive(:new).with(hash_including(newrev: unprocessed_lfs_push.ref)).and_call_original

        perform
      end

      it 'scans all objects in the project on first run' do
        expect_any_instance_of(Gitlab::Git::LfsChanges).to receive(:all_pointers).and_call_original

        perform
      end

      context 'with processed refrences' do
        let(:processed_reference) { 'some_feature' }

        before do
          create(:processed_lfs_ref, project: project, ref: processed_reference)
        end

        it 'ignores objects reachable from processed refs' do
          expect_any_instance_of(Gitlab::Git::RevList).to receive(:new_objects).with(hash_including(not_in: [processed_reference]))

          perform
        end
      end
    end
  end
end
