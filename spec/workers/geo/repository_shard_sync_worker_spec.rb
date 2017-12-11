require 'spec_helper'

# Disable transactions via :delete method because a foreign table
# can't see changes inside a transaction of a different connection.
describe Geo::RepositoryShardSyncWorker, :geo, :delete, :clean_gitlab_redis_cache do
  include ::EE::GeoHelpers

  let!(:primary) { create(:geo_node, :primary) }
  let!(:secondary) { create(:geo_node) }
  let!(:synced_group) { create(:group) }
  let!(:project_in_synced_group) { create(:project, group: synced_group) }
  let!(:unsynced_project) { create(:project) }
  let(:shard_name) { Gitlab.config.repositories.storages.keys.first }

  subject { described_class.new }

  before do
    stub_current_geo_node(secondary)
  end

  shared_examples '#perform' do |skip_tests|
    before do
      skip('FDW is not configured') if skip_tests
    end

    before do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { true }
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:renew) { true }

      Gitlab::Geo::ShardHealthCache.update([shard_name])
    end

    it 'performs Geo::ProjectSyncWorker for each project' do
      expect(Geo::ProjectSyncWorker).to receive(:perform_async).twice.and_return(spy)

      subject.perform(shard_name)
    end

    it 'performs Geo::ProjectSyncWorker for projects where last attempt to sync failed' do
      create(:geo_project_registry, :sync_failed, project: project_in_synced_group)
      create(:geo_project_registry, :synced, project: unsynced_project)

      expect(Geo::ProjectSyncWorker).to receive(:perform_async).once.and_return(spy)

      subject.perform(shard_name)
    end

    it 'does not perform Geo::ProjectSyncWorker when shard becomes unhealthy' do
      Gitlab::Geo::ShardHealthCache.update([])

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'performs Geo::ProjectSyncWorker for synced projects updated recently' do
      create(:geo_project_registry, :synced, :repository_dirty, project: project_in_synced_group)
      create(:geo_project_registry, :synced, project: unsynced_project)
      create(:geo_project_registry, :synced, :wiki_dirty)

      expect(Geo::ProjectSyncWorker).to receive(:perform_async).twice.and_return(spy)

      subject.perform(shard_name)
    end

    it 'does not perform Geo::ProjectSyncWorker when no geo database is configured' do
      allow(Gitlab::Geo).to receive(:geo_database_configured?) { false }

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)

      # We need to unstub here or the DatabaseCleaner will have issues since it
      # will appear as though the tracking DB were not available
      allow(Gitlab::Geo).to receive(:geo_database_configured?).and_call_original
    end

    it 'does not perform Geo::ProjectSyncWorker when not running on a secondary' do
      allow(Gitlab::Geo).to receive(:secondary?) { false }

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not perform Geo::ProjectSyncWorker when node is disabled' do
      allow_any_instance_of(GeoNode).to receive(:enabled?) { false }

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    context 'multiple shards' do
      it 'uses two loops to schedule jobs' do
        expect(subject).to receive(:schedule_jobs).twice.and_call_original

        Gitlab::Geo::ShardHealthCache.update([shard_name, 'shard2', 'shard3', 'shard4', 'shard5'])
        secondary.update!(repos_max_capacity: 5)

        subject.perform(shard_name)
      end
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

        subject.perform(shard_name)
      end

      it 'does not perform Geo::ProjectSyncWorker for synced projects updated recently that do not belong to selected namespaces to replicate' do
        create(:geo_project_registry, :synced, :repository_dirty, project: project_in_synced_group)
        create(:geo_project_registry, :synced, :repository_dirty, project: unsynced_project)

        expect(Geo::ProjectSyncWorker).to receive(:perform_async)
          .with(project_in_synced_group.id, within(1.minute).of(Time.now))
          .once
          .and_return(spy)

        subject.perform(shard_name)
      end
    end

    context 'all repositories fail' do
      let!(:project_list) { create_list(:project, 4, :random_last_repository_updated_at) }

      before do
        # Neither of these are needed for this spec
        unsynced_project.destroy
        project_in_synced_group.destroy

        allow_any_instance_of(described_class).to receive(:db_retrieve_batch_size).and_return(2) # Must be >1 because of the Geo::BaseSchedulerWorker#interleave
        secondary.update!(repos_max_capacity: 3) # Must be more than db_retrieve_batch_size
        allow_any_instance_of(Project).to receive(:ensure_repository).and_raise(Gitlab::Shell::Error.new('foo'))
        allow_any_instance_of(Geo::ProjectRegistry).to receive(:wiki_sync_due?).and_return(false)
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
          Sidekiq::Testing.inline! { subject.perform(shard_name) }
        end
      end
    end

    context 'additional shards' do
      it 'skips backfill for projects on unhealthy shards' do
        missing_not_synced = create(:project, group: synced_group)
        missing_not_synced.update_column(:repository_storage, 'unknown')
        missing_dirty = create(:project, group: synced_group)
        missing_dirty.update_column(:repository_storage, 'unknown')

        create(:geo_project_registry, :synced, :repository_dirty, project: missing_dirty)

        expect(Geo::ProjectSyncWorker).to receive(:perform_async).with(project_in_synced_group.id, anything)
        expect(Geo::ProjectSyncWorker).not_to receive(:perform_async).with(missing_not_synced.id, anything)
        expect(Geo::ProjectSyncWorker).not_to receive(:perform_async).with(missing_dirty.id, anything)

        Sidekiq::Testing.inline! { subject.perform(shard_name) }
      end
    end
  end

  describe 'when PostgreSQL FDW is available', :geo do
    # Skip if FDW isn't activated on this database
    it_behaves_like '#perform', Gitlab::Database.postgresql? && !Gitlab::Geo.fdw?
  end

  describe 'when PostgreSQL FDW is not enabled', :geo do
    before do
      allow(Gitlab::Geo).to receive(:fdw?).and_return(false)
    end

    it_behaves_like '#perform', false
  end
end
