require 'spec_helper'

describe Geo::RepositorySyncWorker do
  let!(:primary)   { create(:geo_node, :primary, host: 'primary-geo-node') }
  let!(:secondary) { create(:geo_node, :current) }
  let!(:project_1) { create(:empty_project) }
  let!(:project_2) { create(:empty_project) }

  subject { described_class.new }

  describe '#perform' do
    before do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { true }
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:renew) { true }
    end

    it 'performs Geo::ProjectSyncWorker for each project' do
      expect(Geo::ProjectSyncWorker).to receive(:perform_in).twice.and_return(spy)

      subject.perform
    end

    it 'performs Geo::ProjectSyncWorker for projects where last attempt to sync failed' do
      create(:geo_project_registry, :sync_failed, project: project_1)
      create(:geo_project_registry, :synced, project: project_2)

      expect(Geo::ProjectSyncWorker).to receive(:perform_in).once.and_return(spy)

      subject.perform
    end

    it 'performs Geo::ProjectSyncWorker for synced projects updated recently' do
      create(:geo_project_registry, :synced, :repository_dirty, project: project_1)
      create(:geo_project_registry, :synced, project: project_2)
      create(:geo_project_registry, :synced, :wiki_dirty)

      expect(Geo::ProjectSyncWorker).to receive(:perform_in).twice.and_return(spy)

      subject.perform
    end

    it 'does not perform Geo::ProjectSyncWorker when no geo database is configured' do
      allow(Gitlab::Geo).to receive(:geo_database_configured?) { false }

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_in)

      subject.perform
    end

    it 'does not perform Geo::ProjectSyncWorker when not running on a secondary' do
      allow(Gitlab::Geo).to receive(:secondary?) { false }

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_in)

      subject.perform
    end

    it 'does not perform Geo::ProjectSyncWorker when node is disabled' do
      allow_any_instance_of(GeoNode).to receive(:enabled?) { false }

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_in)

      subject.perform
    end
  end
end
