require 'spec_helper'

describe GeoNodeKey do
  let(:geo_node) { create(:geo_node) }
  let(:geo_node_key) { create(:geo_node_key, geo_nodes: [geo_node]) }

  describe 'Associations' do
    it { is_expected.to have_one(:geo_node) }
  end
end
