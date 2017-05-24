require 'spec_helper'

describe GeoNodeStatusEntity do
  let(:geo_node_status) do
    GeoNodeStatus.new(
      id: 1,
      health: nil,
      attachments_count: 329,
      attachments_synced_count: 141,
      lfs_objects_count: 256,
      lfs_objects_synced_count: 123,
      repositories_count: 10,
      repositories_synced_count: 5
    )
  end

  let(:entity) do
    described_class.new(geo_node_status, request: double)
  end

  let(:error) do
    'Could not connect to Geo database'
  end

  subject { entity.as_json }

  it { is_expected.to have_key(:id) }
  it { is_expected.to have_key(:healthy) }
  it { is_expected.to have_key(:health) }
  it { is_expected.to have_key(:attachments_count) }
  it { is_expected.to have_key(:attachments_synced_count) }
  it { is_expected.to have_key(:attachments_synced_in_percentage) }
  it { is_expected.to have_key(:lfs_objects_count) }
  it { is_expected.to have_key(:lfs_objects_synced_count) }
  it { is_expected.to have_key(:lfs_objects_synced_in_percentage) }
  it { is_expected.to have_key(:repositories_count) }
  it { is_expected.to have_key(:repositories_failed_count) }
  it { is_expected.to have_key(:repositories_synced_count)}
  it { is_expected.to have_key(:repositories_synced_in_percentage) }

  describe '#healthy' do
    context 'when node is healthy' do
      it 'returns true' do
        expect(subject[:healthy]).to eq true
      end
    end

    context 'when node is unhealthy' do
      before do
        geo_node_status.health = error
      end

      subject { entity.as_json }

      it 'returns false' do
        expect(subject[:healthy]).to eq false
      end
    end
  end

  describe '#health' do
    context 'when node is healthy' do
      it 'exposes the health message' do
        expect(subject[:health]).to eq 'Healthy'
      end
    end

    context 'when node is unhealthy' do
      before do
        geo_node_status.health = error
      end

      subject { entity.as_json }

      it 'exposes the error message' do
        expect(subject[:health]).to eq error
      end
    end
  end

  describe '#attachments_synced_in_percentage' do
    it 'formats as percentage' do
      expect(subject[:attachments_synced_in_percentage]).to eq '42.86%'
    end
  end

  describe '#lfs_objects_synced_in_percentage' do
    it 'formats as percentage' do
      expect(subject[:lfs_objects_synced_in_percentage]).to eq '48.05%'
    end
  end

  describe '#repositories_synced_in_percentage' do
    it 'formats as percentage' do
      expect(subject[:repositories_synced_in_percentage]).to eq '50.00%'
    end
  end
end
