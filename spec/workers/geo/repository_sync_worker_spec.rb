require 'spec_helper'

describe Geo::RepositorySyncWorker, :postgresql do
  let!(:primary) { create(:geo_node, :primary, host: 'primary-geo-node') }
  let!(:secondary) { create(:geo_node, :current) }
  let(:synced_group) { create(:group) }
  let!(:project_in_synced_group) { create(:project, group: synced_group) }
  let!(:unsynced_project) { create(:project) }

  subject { described_class.new }

  describe '#perform' do
    before do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { true }
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:renew) { true }
    end

    it 'performs Geo::ProjectSyncWorker for each project' do
      expect(Geo::ProjectSyncWorker).to receive(:perform_async).twice.and_return(spy)

      subject.perform
    end

    it 'performs Geo::ProjectSyncWorker for projects where last attempt to sync failed' do
      create(:geo_project_registry, :sync_failed, project: project_in_synced_group)
      create(:geo_project_registry, :synced, project: unsynced_project)

      expect(Geo::ProjectSyncWorker).to receive(:perform_async).once.and_return(spy)

      subject.perform
    end

    it 'performs Geo::ProjectSyncWorker for synced projects updated recently' do
      create(:geo_project_registry, :synced, :repository_dirty, project: project_in_synced_group)
      create(:geo_project_registry, :synced, project: unsynced_project)
      create(:geo_project_registry, :synced, :wiki_dirty)

      expect(Geo::ProjectSyncWorker).to receive(:perform_async).twice.and_return(spy)

      subject.perform
    end

    it 'does not perform Geo::ProjectSyncWorker when no geo database is configured' do
      allow(Gitlab::Geo).to receive(:geo_database_configured?) { false }

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform
    end

    it 'does not perform Geo::ProjectSyncWorker when not running on a secondary' do
      allow(Gitlab::Geo).to receive(:secondary?) { false }

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform
    end

    it 'does not perform Geo::ProjectSyncWorker when node is disabled' do
      allow_any_instance_of(GeoNode).to receive(:enabled?) { false }

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform
    end

    context 'when node has namespace restrictions' do
      before do
        secondary.update_attribute(:namespaces, [synced_group])
      end

      it 'does not perform Geo::ProjectSyncWorker for projects that do not belong to selected namespaces to replicate' do
        expect(Geo::ProjectSyncWorker).to receive(:perform_async)
          .with(project_in_synced_group.id, within(1.minute).of(Time.now))
          .once
          .and_return(spy)

        subject.perform
      end

      it 'does not perform Geo::ProjectSyncWorker for synced projects updated recently that do not belong to selected namespaces to replicate' do
        create(:geo_project_registry, :synced, :repository_dirty, project: project_in_synced_group)
        create(:geo_project_registry, :synced, :repository_dirty, project: unsynced_project)

        expect(Geo::ProjectSyncWorker).to receive(:perform_async)
          .with(project_in_synced_group.id, within(1.minute).of(Time.now))
          .once
          .and_return(spy)

        subject.perform
      end
    end

    context 'all repositories fail' do
      let!(:project_list) { create_list(:project, 4, :random_last_repository_updated_at) }

      before do
        allow_any_instance_of(described_class).to receive(:db_retrieve_batch_size).and_return(2) # Must be >1 because of the Geo::BaseSchedulerWorker#interleave
        allow_any_instance_of(described_class).to receive(:max_capacity).and_return(3) # Must be more than db_retrieve_batch_size
        allow_any_instance_of(Project).to receive(:ensure_repository).and_raise(Gitlab::Shell::Error.new('foo'))
        allow_any_instance_of(Geo::ProjectSyncWorker).to receive(:sync_wiki?).and_return(false)
        allow_any_instance_of(Geo::RepositorySyncService).to receive(:expire_repository_caches)
      end

      it 'tries to sync every project' do
        project_list.each do |project|
          expect(Geo::ProjectSyncWorker)
            .to receive(:perform_async)
              .with(project.id, anything)
              .at_least(:once)
              .and_call_original
        end

        3.times do
          Sidekiq::Testing.inline! { subject.perform }
        end
      end
    end
  end
end
