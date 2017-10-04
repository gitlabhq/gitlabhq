require 'spec_helper'

describe Gitlab::Geo::LogCursor::Daemon, :postgresql do
  include ::EE::GeoHelpers

  describe '#run!' do
    set(:geo_node) { create(:geo_node) }

    before do
      stub_current_geo_node(geo_node)
    end

    it 'traps signals' do
      allow(subject).to receive(:exit?) { true }
      expect(subject).to receive(:trap_signals)

      subject.run!
    end

    context 'when the command-line defines full_scan: true' do
      subject { described_class.new(full_scan: true) }

      it 'executes a full-scan' do
        allow(subject).to receive(:exit?) { true }

        expect(subject).to receive(:full_scan!)

        subject.run!
      end
    end

    context 'when replaying a repository created event' do
      let(:project) { create(:project) }
      let(:repository_created_event) { create(:geo_repository_created_event, project: project) }
      let(:event_log) { create(:geo_event_log, repository_created_event: repository_created_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }

      before do
        allow(subject).to receive(:exit?).and_return(false, true)
      end

      it 'creates a new project registry' do
        expect { subject.run! }.to change(Geo::ProjectRegistry, :count).by(1)
      end

      it 'sets resync attributes to true' do
        subject.run!

        registry = Geo::ProjectRegistry.last

        expect(registry).to have_attributes(project_id: project.id, resync_repository: true, resync_wiki: true)
      end

      it 'sets resync_wiki to false if wiki_path is nil' do
        repository_created_event.update_attribute(:wiki_path, nil)

        subject.run!

        registry = Geo::ProjectRegistry.last

        expect(registry).to have_attributes(project_id: project.id, resync_repository: true, resync_wiki: false)
      end

      it 'performs Geo::ProjectSyncWorker' do
        expect(Geo::ProjectSyncWorker).to receive(:perform_async)
          .with(project.id, anything).once.and_return(spy)

        subject.run!
      end
    end

    context 'when replaying a repository updated event' do
      let(:project) { create(:project) }
      let(:repository_updated_event) { create(:geo_repository_updated_event, project: project) }
      let(:event_log) { create(:geo_event_log, repository_updated_event: repository_updated_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }

      before do
        allow(subject).to receive(:exit?).and_return(false, true)
      end

      it 'creates a new project registry if it does not exist' do
        expect { subject.run! }.to change(Geo::ProjectRegistry, :count).by(1)
      end

      it 'sets resync_repository to true if event source is repository' do
        repository_updated_event.update_attribute(:source, Geo::RepositoryUpdatedEvent::REPOSITORY)
        registry = create(:geo_project_registry, :synced, project: repository_updated_event.project)

        subject.run!

        expect(registry.reload.resync_repository).to be true
      end

      it 'sets resync_wiki to true if event source is wiki' do
        repository_updated_event.update_attribute(:source, Geo::RepositoryUpdatedEvent::WIKI)
        registry = create(:geo_project_registry, :synced, project: repository_updated_event.project)

        subject.run!

        expect(registry.reload.resync_wiki).to be true
      end

      it 'performs Geo::ProjectSyncWorker' do
        expect(Geo::ProjectSyncWorker).to receive(:perform_async)
          .with(project.id, anything).once.and_return(spy)

        subject.run!
      end
    end

    context 'when replaying a repository deleted event' do
      let(:event_log) { create(:geo_event_log, :deleted_event) }
      let(:project) { event_log.repository_deleted_event.project }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
      let(:repository_deleted_event) { event_log.repository_deleted_event }

      before do
        allow(subject).to receive(:exit?).and_return(false, true)
      end

      it 'does not create a new project registry' do
        expect { subject.run! }.not_to change(Geo::ProjectRegistry, :count)
      end

      it 'schedules a GeoRepositoryDestroyWorker' do
        project_id   = repository_deleted_event.project_id
        project_name = repository_deleted_event.deleted_project_name
        full_path    = File.join(repository_deleted_event.repository_storage_path,
                                 repository_deleted_event.deleted_path)

        expect(::GeoRepositoryDestroyWorker).to receive(:perform_async)
          .with(project_id, project_name, full_path, project.repository_storage)

        subject.run!
      end
    end

    context 'when replaying a repositories changed event' do
      let(:geo_node) { create(:geo_node) }
      let(:repositories_changed_event) { create(:geo_repositories_changed_event, geo_node: geo_node) }
      let(:event_log) { create(:geo_event_log, repositories_changed_event: repositories_changed_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }

      before do
        allow(subject).to receive(:exit?).and_return(false, true)
      end

      it 'schedules a GeoRepositoryDestroyWorker when event node is the current node' do
        expect(Geo::RepositoriesCleanUpWorker).to receive(:perform_in).with(within(5.minutes).of(1.hour), geo_node.id)

        subject.run!
      end

      it 'does not schedule a GeoRepositoryDestroyWorker when event node is not the current node' do
        stub_current_geo_node(build(:geo_node))

        expect(Geo::RepositoriesCleanUpWorker).not_to receive(:perform_in)

        subject.run!
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
        allow(subject).to receive(:exit?).and_return(false, true)
        allow(Geo::ProjectSyncWorker).to receive(:perform_async).and_return(spy)
      end

      it 'replays events for projects that belong to selected namespaces to replicate' do
        geo_node.update_attribute(:namespaces, [group_1])

        expect { subject.run! }.to change(Geo::ProjectRegistry, :count).by(1)
      end

      it 'does not replay events for projects that do not belong to selected namespaces to replicate' do
        geo_node.update_attribute(:namespaces, [group_2])

        expect { subject.run! }.not_to change(Geo::ProjectRegistry, :count)
      end

      context 'when performing a full scan' do
        subject { described_class.new(full_scan: true) }

        it 'creates registries for missing projects that belong to selected namespaces' do
          geo_node.update_attribute(:namespaces, [group_1])

          expect { subject.run! }.to change(Geo::ProjectRegistry, :count).by(1)
        end

        it 'does not create registries for missing projects that do not belong to selected namespaces' do
          geo_node.update_attribute(:namespaces, [group_2])

          expect { subject.run! }.not_to change(Geo::ProjectRegistry, :count)
        end
      end
    end

    context 'when processing a repository renamed event' do
      let(:event_log) { create(:geo_event_log, :renamed_event) }
      let(:project) { event_log.repository_rename_event.project }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
      let(:repository_rename_event) { event_log.repository_renamed_event }

      before do
        allow(subject).to receive(:exit?).and_return(false, true)
      end

      it 'does not create a new project registry' do
        expect { subject.run! }.not_to change(Geo::ProjectRegistry, :count)
      end

      it 'schedules a GeoRepositoryDestroyWorker' do
        project_id = repository_rename_event.project_id
        old_path_with_namespace = repository_rename_event.old_path_with_namespace
        new_path_with_namespace = repository_rename_event.new_path_with_namespace

        expect(::GeoRepositoryMoveWorker).to receive(:perform_async)
          .with(project_id, '', old_path_with_namespace, new_path_with_namespace)

        subject.run!
      end
    end
  end
end
