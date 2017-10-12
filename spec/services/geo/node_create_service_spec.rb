require 'spec_helper'

describe Geo::NodeCreateService do
  describe '#execute' do
    it 'creates a new node with valid params' do
      params = { url: 'http://example.com', geo_node_key_attributes: attributes_for(:key) }
      service = described_class.new(params)

      expect { service.execute }.to change(GeoNode, :count).by(1)
    end

    it 'does not create a node with invalid params' do
      service = described_class.new({ url: 'http://example.com' })

      expect { service.execute }.not_to change(GeoNode, :count)
    end

    it 'returns true when creation succeeds' do
      params = { url: 'http://example.com', geo_node_key_attributes: attributes_for(:key) }
      service = described_class.new(params)

      expect(service.execute).to eq true
    end

    it 'returns false when creation fails' do
      params = { url: 'http://example.com' }
      service = described_class.new(params)

      expect(service.execute).to eq false
    end

    it 'parses the namespace_ids when node have namespace restrictions' do
      groups = create_list(:group, 2)
      params = { url: 'http://example.com', geo_node_key_attributes: attributes_for(:key), namespace_ids: groups.map(&:id).join(',') }
      service = described_class.new(params)

      service.execute

      expect(GeoNode.last.namespace_ids).to match_array(groups.map(&:id))
    end
  end
end
