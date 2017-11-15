require 'spec_helper'

describe Gitlab::Geo::LogCursor::Daemon, :postgresql, :clean_gitlab_redis_shared_state do
  include ::EE::GeoHelpers

  set(:primary) { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }

  let(:options) { {} }
  subject(:daemon) { described_class.new(options) }

  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  before do
    stub_current_geo_node(secondary)

    allow(daemon).to receive(:trap_signals)
    allow(daemon).to receive(:arbitrary_sleep).and_return(0.1)
  end

  describe '#run!' do
    it 'traps signals' do
      is_expected.to receive(:exit?).and_return(true)
      is_expected.to receive(:trap_signals)

      daemon.run!
    end

    it 'does not perform a full scan by default' do
      is_expected.to receive(:exit?).and_return(true)
      is_expected.not_to receive(:full_scan!)

      daemon.run!
    end

    context 'the command-line defines full_scan: true' do
      let(:options) { { full_scan: true } }

      it 'executes a full-scan' do
        is_expected.to receive(:exit?).and_return(true)
        is_expected.to receive(:full_scan!)

        daemon.run!
      end
    end

    it 'delegates to #run_once! in a loop' do
      is_expected.to receive(:exit?).and_return(false, false, false, true)
      is_expected.to receive(:run_once!).twice

      daemon.run!
    end

    it 'skips execution if cannot achieve a lease' do
      is_expected.to receive(:exit?).and_return(false, true)
      is_expected.not_to receive(:run_once!)
      expect_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain_with_ttl).and_return({ ttl: 1, uuid: false })

      daemon.run!
    end
  end

  describe '#run_once!' do
    context 'when replaying a repository created event' do
      let(:project) { create(:project) }
      let(:repository_created_event) { create(:geo_repository_created_event, project: project) }
      let(:event_log) { create(:geo_event_log, repository_created_event: repository_created_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }

      it 'creates a new project registry' do
        expect { daemon.run_once! }.to change(Geo::ProjectRegistry, :count).by(1)
      end

      it 'sets resync attributes to true' do
        daemon.run_once!

        registry = Geo::ProjectRegistry.last

        expect(registry).to have_attributes(project_id: project.id, resync_repository: true, resync_wiki: true)
      end

      it 'sets resync_wiki to false if wiki_path is nil' do
        repository_created_event.update!(wiki_path: nil)

        daemon.run_once!

        registry = Geo::ProjectRegistry.last

        expect(registry).to have_attributes(project_id: project.id, resync_repository: true, resync_wiki: false)
      end

      it 'performs Geo::ProjectSyncWorker' do
        expect(Geo::ProjectSyncWorker).to receive(:perform_async)
          .with(project.id, anything).once

        daemon.run_once!
      end
    end

    context 'when replaying a repository updated event' do
      let(:project) { create(:project) }
      let(:repository_updated_event) { create(:geo_repository_updated_event, project: project) }
      let(:event_log) { create(:geo_event_log, repository_updated_event: repository_updated_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }

      it 'creates a new project registry if it does not exist' do
        expect { daemon.run_once! }.to change(Geo::ProjectRegistry, :count).by(1)
      end

      it 'sets resync_repository to true if event source is repository' do
        repository_updated_event.update!(source: Geo::RepositoryUpdatedEvent::REPOSITORY)
        registry = create(:geo_project_registry, :synced, project: repository_updated_event.project)

        daemon.run_once!

        expect(registry.reload.resync_repository).to be true
      end

      it 'sets resync_wiki to true if event source is wiki' do
        repository_updated_event.update!(source: Geo::RepositoryUpdatedEvent::WIKI)
        registry = create(:geo_project_registry, :synced, project: repository_updated_event.project)

        daemon.run_once!

        expect(registry.reload.resync_wiki).to be true
      end

      it 'performs Geo::ProjectSyncWorker' do
        expect(Geo::ProjectSyncWorker).to receive(:perform_async)
          .with(project.id, anything).once

        daemon.run_once!
      end
    end

    context 'when replaying a repository deleted event' do
      let(:event_log) { create(:geo_event_log, :deleted_event) }
      let(:project) { event_log.repository_deleted_event.project }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
      let(:repository_deleted_event) { event_log.repository_deleted_event }

      it 'does not create a new project registry' do
        expect { daemon.run_once! }.not_to change(Geo::ProjectRegistry, :count)
      end

      it 'schedules a GeoRepositoryDestroyWorker' do
        project_id   = repository_deleted_event.project_id
        project_name = repository_deleted_event.deleted_project_name
        full_path    = File.join(repository_deleted_event.repository_storage_path,
                                 repository_deleted_event.deleted_path)

        expect(::GeoRepositoryDestroyWorker).to receive(:perform_async)
          .with(project_id, project_name, full_path, project.repository_storage)

        daemon.run_once!
      end
    end

    context 'when replaying a repositories changed event' do
      let(:repositories_changed_event) { create(:geo_repositories_changed_event, geo_node: secondary) }
      let(:event_log) { create(:geo_event_log, repositories_changed_event: repositories_changed_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }

      it 'schedules a GeoRepositoryDestroyWorker when event node is the current node' do
        expect(Geo::RepositoriesCleanUpWorker).to receive(:perform_in).with(within(5.minutes).of(1.hour), secondary.id)

        daemon.run_once!
      end

      it 'does not schedule a GeoRepositoryDestroyWorker when event node is not the current node' do
        stub_current_geo_node(build(:geo_node))

        expect(Geo::RepositoriesCleanUpWorker).not_to receive(:perform_in)

        daemon.run_once!
      end
    end

    context 'when node has namespace restrictions' do
      let(:group_1) { create(:group) }
      let(:group_2) { create(:group) }
      let(:project) { create(:project, group: group_1) }
      let(:repository_updated_event) { create(:geo_repository_updated_event, project: project) }
      let(:event_log) { create(:geo_event_log, repository_updated_event: repository_updated_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }

      before do
        allow(Geo::ProjectSyncWorker).to receive(:perform_async)
      end

      it 'replays events for projects that belong to selected namespaces to replicate' do
        secondary.update!(namespaces: [group_1])

        expect { daemon.run_once! }.to change(Geo::ProjectRegistry, :count).by(1)
      end

      it 'does not replay events for projects that do not belong to selected namespaces to replicate' do
        secondary.update!(namespaces: [group_2])

        expect { daemon.run_once! }.not_to change(Geo::ProjectRegistry, :count)
      end
    end

    context 'when processing a repository renamed event' do
      let(:event_log) { create(:geo_event_log, :renamed_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
      let(:repository_renamed_event) { event_log.repository_renamed_event }

      it 'does not create a new project registry' do
        expect { daemon.run_once! }.not_to change(Geo::ProjectRegistry, :count)
      end

      it 'schedules a Geo::RenameRepositoryWorker' do
        project_id = repository_renamed_event.project_id
        old_path_with_namespace = repository_renamed_event.old_path_with_namespace
        new_path_with_namespace = repository_renamed_event.new_path_with_namespace

        expect(::Geo::RenameRepositoryWorker).to receive(:perform_async)
          .with(project_id, old_path_with_namespace, new_path_with_namespace)

        daemon.run_once!
      end
    end

    context 'when processing a hashed storage migration event' do
      let(:event_log) { create(:geo_event_log, :hashed_storage_migration_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
      let(:hashed_storage_migrated_event) { event_log.hashed_storage_migrated_event }

      it 'does not create a new project registry' do
        expect { daemon.run_once! }.not_to change(Geo::ProjectRegistry, :count)
      end

      it 'schedules a Geo::HashedStorageMigrationWorker' do
        project = hashed_storage_migrated_event.project
        old_disk_path = hashed_storage_migrated_event.old_disk_path
        new_disk_path = hashed_storage_migrated_event.new_disk_path
        old_storage_version = project.storage_version

        expect(::Geo::HashedStorageMigrationWorker).to receive(:perform_async)
          .with(project.id, old_disk_path, new_disk_path, old_storage_version)

        daemon.run_once!
      end
    end
  end

  describe '#full_scan!' do
    let(:project) { create(:project) }

    context 'with selective sync enabled' do
      it 'creates registries for missing projects that belong to selected namespaces' do
        secondary.update!(namespaces: [project.namespace])

        expect { daemon.full_scan! }.to change(Geo::ProjectRegistry, :count).by(1)
      end

      it 'does not create registries for missing projects that do not belong to selected namespaces' do
        secondary.update!(namespaces: [create(:group)])

        expect { daemon.full_scan! }.not_to change(Geo::ProjectRegistry, :count)
      end
    end
  end
end
