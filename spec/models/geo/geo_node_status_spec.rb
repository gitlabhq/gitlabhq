require 'spec_helper'

describe Geo::GeoNodeStatus, models: true do
  subject { GeoNodeStatus.new }

  describe '#lfs_objects_synced_in_percentage' do
    it 'returns 0 when no objects are available' do
      subject.lfs_objects_total = 0
      subject.lfs_objects_synced = 0

      expect(subject.lfs_objects_synced_in_percentage).to eq(0)
    end

    it 'returns the right percentage' do
      subject.lfs_objects_total = 4
      subject.lfs_objects_synced = 1

      expect(subject.lfs_objects_synced_in_percentage).to be_within(0.0001).of(25)
    end
  end
end
