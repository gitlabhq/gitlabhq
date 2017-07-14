require 'spec_helper'

describe Geo::BaseSyncService, services: true do
  let(:project) { build('project')}
  subject { described_class.new(project) }

  describe '#execute' do
    context 'when can acquire exclusive lease' do
      before do
        allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { 12345 }
      end

      it 'executes the synchronization' do
        expect(subject).to receive(:sync_repository)

        subject.execute
      end
    end

    context 'when exclusive lease is not acquired' do
      before do
        allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { nil }
      end

      it 'is does not execute synchronization' do
        expect(subject).not_to receive(:sync_repository)

        subject.execute
      end
    end
  end

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

      expect { subject.send(:primary_ssh_path_prefix) }.to raise_error Geo::EmptyCloneUrlPrefixError
    end

    it 'returns the prefix defined in the primary node' do
      expect { subject.send(:primary_ssh_path_prefix) }.not_to raise_error
      expect(subject.send(:primary_ssh_path_prefix)).to eq('git@localhost:')
    end
  end
end
