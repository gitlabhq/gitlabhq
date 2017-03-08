require 'spec_helper'

describe Geo::FileDownloadService, services: true do
  let(:lfs_object) { create(:lfs_object) }
  let(:secondary) { create(:geo_node) }

  subject { Geo::FileDownloadService.new(:lfs, lfs_object.id) }

  before do
    create(:geo_node, :primary)
    allow(described_class).to receive(:current_node) { secondary }
  end

  describe '#execute' do
    it 'downloads an LFS object' do
      allow_any_instance_of(Gitlab::ExclusiveLease)
        .to receive(:try_obtain).and_return(true)
      allow_any_instance_of(Gitlab::Geo::LfsTransfer)
        .to receive(:download_from_primary).and_return(100)

      expect{ subject.execute }.to change { Geo::FileRegistry.count }.by(1)
    end
  end
end
