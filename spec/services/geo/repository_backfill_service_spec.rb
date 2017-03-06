require 'spec_helper'

describe Geo::RepositoryBackfillService, services: true do
  let!(:primary) { create(:geo_node, :primary, host: 'primary-geo-node') }
  let(:project) { create(:empty_project) }

  subject { described_class.new(project.id, '123456') }

  describe '#execute' do
    it 'fetches project repositories' do
      fetch_count = 0

      allow_any_instance_of(Repository).to receive(:fetch_geo_mirror) do
        fetch_count += 1
      end

      subject.execute

      expect(fetch_count).to eq 2
    end

    it 'expires repository caches' do
      allow_any_instance_of(Repository).to receive(:fetch_geo_mirror) { true }

      expect_any_instance_of(Repository).to receive(:after_sync).once

      subject.execute
    end

    it 'releases leases' do
      expect(Gitlab::ExclusiveLease).to receive(:cancel).exactly(2).and_call_original

      subject.execute
    end

    context 'tracking database' do
      it 'tracks repository sync' do
        expect { subject.execute }.to change(Geo::ProjectRegistry, :count).by(1)
      end

      it 'stores last_repository_successful_sync_at when succeed' do
        allow_any_instance_of(Repository).to receive(:fetch_geo_mirror) { true }

        subject.execute

        registry = Geo::ProjectRegistry.find_by(project_id: project.id)

        expect(registry.last_repository_successful_sync_at).not_to be_nil
      end

      it 'reset last_repository_successful_sync_at when fail' do
        allow_any_instance_of(Repository).to receive(:fetch_geo_mirror) { raise Gitlab::Shell::Error }

        subject.execute

        registry = Geo::ProjectRegistry.find_by(project_id: project.id)

        expect(registry.last_repository_successful_sync_at).to be_nil
      end
    end
  end
end
