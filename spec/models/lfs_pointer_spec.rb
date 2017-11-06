require 'spec_helper'

describe LfsPointer do
  it { is_expected.to belong_to(:project) }

  it { is_expected.to have_db_column(:blob_oid).of_type(:string) }
  it { is_expected.to have_db_column(:lfs_oid).of_type(:string) }

  describe '#missing_on_disk' do
    let!(:lfs_pointer) { create(:lfs_pointer) }
    let(:removed_oids) { [lfs_pointer.blob_oid] }
    let(:repository) { double }

    before do
      allow(repository).to receive(:batch_existence)
                                  .with([lfs_pointer.blob_oid],
                                        existing: false)
                                  .and_return(removed_oids)
    end

    it 'detects LFS pointers which no longer exist in the project' do
      expect(described_class.missing_on_disk(repository).first).to eq lfs_pointer
    end

    context 'with no removed pointer blobs' do
      let(:removed_oids) { [] }

      it 'returns an empty relation' do
        expect(described_class.missing_on_disk(repository)).to be_empty
      end
    end
  end
end
