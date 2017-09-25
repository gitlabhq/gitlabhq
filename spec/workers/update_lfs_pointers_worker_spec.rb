require 'spec_helper'

describe UpdateLfsPointersWorker do
  subject(:worker) { described_class.new }

  describe '#perform' do
    let(:project) { create(:project, :repository) }
    let(:reference_change) { create(:reference_change, project: project) }
    let(:blob_object) { project.repository.blob_at_branch('lfs', 'files/lfs/lfs_object.iso') }

    before do
      allow_any_instance_of(Gitlab::Git::RevList).to receive(:new_objects).and_return([blob_object.id])
    end

    def perform
      subject.perform(reference_change.id)
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

      it 'marks the updated reference as processed' do
        expect { perform }.to change { reference_change.reload.processed }.from(false).to(true)
      end

      it 'creates a LfsPointer record for each new blob' do
        expect { perform }.to change(LfsPointer, :count).by(1)
      end

      it 'looks up LFS pointers for the new ref' do
        expect(Gitlab::Git::RevList).to receive(:new).with(hash_including(newrev: reference_change.newrev)).and_call_original

        perform
      end

      it 'scans all objects in the given ref on first run' do
        expect_any_instance_of(Gitlab::Git::LfsChanges).to receive(:new_pointers).with(not_in: []).and_call_original

        perform
      end

      context 'with processed refrences' do
        let(:processed_reference) { 'fa15ebeefacce55ed4dec0dea5decafbeefba115' }

        before do
          create(:reference_change, project: project,
                                    newrev: processed_reference,
                                    processed: true)
        end

        it 'ignores objects reachable from processed refs' do
          expect_any_instance_of(Gitlab::Git::RevList).to receive(:new_objects).with(hash_including(not_in: [processed_reference]))

          perform
        end
      end
    end
  end
end
