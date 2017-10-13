require 'spec_helper'

describe Geo::FileRegistry do
  set(:failed) { create(:geo_file_registry, success: false) }
  set(:synced) { create(:geo_file_registry, success: true) }

  describe '.failed' do
    it 'returns registries in the failed state' do
      expect(described_class.failed).to contain_exactly(failed)
    end
  end

  describe '.synced' do
    it 'returns registries in the synced state' do
      expect(described_class.synced).to contain_exactly(synced)
    end
  end
end
