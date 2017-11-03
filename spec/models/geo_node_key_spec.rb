require 'spec_helper'

describe GeoNodeKey do
  describe 'Associations' do
    it { is_expected.to have_one(:geo_node) }
  end

  describe '#active?' do
    let(:geo_node) { create(:geo_node, :ssh) }
    let(:geo_node_key) { geo_node.geo_node_key }

    subject { geo_node_key.active? }

    it 'returns true for a secondary SSH Geo node' do
      is_expected.to be_truthy
    end

    it 'returns false for a primary SSH Geo node' do
      geo_node.primary = true

      is_expected.to be_falsy
    end

    it 'returns false for a secondary HTTP Geo node' do
      geo_node.clone_protocol = 'http'

      is_expected.to be_falsy
    end
  end
end
