require 'spec_helper'

describe Gitlab::Geo::LfsDownloader do
  let(:lfs_object) { create(:lfs_object) }

  subject do
    described_class.new(:lfs, lfs_object.id)
  end

  context '#download_from_primary' do
    it 'with LFS object' do
      allow_any_instance_of(Gitlab::Geo::LfsTransfer)
        .to receive(:download_from_primary).and_return(100)

      expect(subject.execute).to eq(100)
    end

    it 'with unknown LFS object' do
      expect(described_class.new(:lfs, 10000)).not_to receive(:download_from_primary)

      expect(subject.execute).to be_nil
    end
  end
end
