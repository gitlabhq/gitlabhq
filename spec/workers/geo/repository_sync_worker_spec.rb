require 'spec_helper'

describe Geo::RepositorySyncWorker do
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
      expect(Geo::ProjectSyncWorker).to receive(:perform_in).twice.and_return(spy)

      subject.perform
    end

    it 'performs Geo::ProjectSyncWorker for projects where last attempt to sync failed' do
      create(:geo_project_registry, :sync_failed, project: project_in_synced_group)
      create(:geo_project_registry, :synced, project: unsynced_project)

      expect(Geo::ProjectSyncWorker).to receive(:perform_in).once.and_return(spy)

      subject.perform
    end

    it 'performs Geo::ProjectSyncWorker for synced projects updated recently' do
      create(:geo_project_registry, :synced, :repository_dirty, project: project_in_synced_group)
      create(:geo_project_registry, :synced, project: unsynced_project)
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

    context 'when node has namespace restrictions' do
      before do
        secondary.update_attribute(:namespaces, [synced_group])
      end

      it 'does not perform Geo::ProjectSyncWorker for projects that do not belong to selected namespaces to replicate' do
        expect(Geo::ProjectSyncWorker).to receive(:perform_in)
          .with(300, project_in_synced_group.id, within(1.minute).of(Time.now))
          .once
          .and_return(spy)

        subject.perform
      end

      it 'does not perform Geo::ProjectSyncWorker for synced projects updated recently that do not belong to selected namespaces to replicate' do
        create(:geo_project_registry, :synced, :repository_dirty, project: project_in_synced_group)
        create(:geo_project_registry, :synced, :repository_dirty, project: unsynced_project)

        expect(Geo::ProjectSyncWorker).to receive(:perform_in)
          .with(300, project_in_synced_group.id, within(1.minute).of(Time.now))
          .once
          .and_return(spy)

        subject.perform
      end
    end

    context 'all repositories fail' do
      before do
        allow_any_instance_of(described_class).to receive(:db_retrieve_batch_size).and_return(4)
        allow_any_instance_of(described_class).to receive(:max_capacity).and_return(5)
        allow_any_instance_of(Project).to receive(:ensure_repository).and_raise(Gitlab::Shell::Error.new('foo'))
        allow_any_instance_of(Geo::ProjectSyncWorker).to receive(:sync_wiki?).and_return(false)
        allow_any_instance_of(Geo::RepositorySyncService).to receive(:expire_repository_caches)
        allow_any_instance_of(Geo::RepositorySyncService).to receive(:try_obtain_lease) { |&arg| arg.call }

        create_list(:project, 20, :random_last_repository_updated_at)
      end

      it 'attempts to sync them all' do
        Sidekiq::Testing.inline! do
          10.times do
            subject.perform
            break if Geo::ProjectRegistry.count == Project.count
          end
        end

        expect(Geo::ProjectRegistry.count).to eq(Project.count)
      end
    end
  end
end
