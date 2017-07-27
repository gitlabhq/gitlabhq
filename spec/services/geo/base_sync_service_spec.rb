require 'spec_helper'

describe Geo::BaseSyncService do
  let(:project) { build('project')}
  subject { described_class.new(project) }

  it_behaves_like 'geo base sync execution'

  describe '#lease_key' do
    it 'returns a key in the correct pattern' do
      described_class.type = :test
      allow(project).to receive(:id) { 999 }

      expect(subject.lease_key).to eq('geo_sync_service:test:999')
    end
  end

  describe '#primary_ssh_path_prefix' do
    let!(:primary_node) { create(:geo_node, :primary, host: 'primary-geo-node') }

    it 'raises exception when clone_url_prefix is nil' do
      allow_any_instance_of(GeoNode).to receive(:clone_url_prefix) { nil }

      expect { subject.primary_ssh_path_prefix }.to raise_error Geo::EmptyCloneUrlPrefixError
    end

    it 'returns the prefix defined in the primary node' do
      expect(subject.primary_ssh_path_prefix).to eq('git@localhost:')
    end
  end
end
