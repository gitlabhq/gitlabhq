# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::ConsistencyFixService, feature_category: :cell do
  describe '#execute' do
    context 'fixing namespaces inconsistencies' do
      subject(:consistency_fix_service) do
        described_class.new(
          source_model: Namespace,
          target_model: Ci::NamespaceMirror,
          sync_event_class: Namespaces::SyncEvent,
          source_sort_key: :id,
          target_sort_key: :namespace_id
        )
      end

      let(:table) { 'public.namespaces' }
      let!(:namespace) { create(:namespace) }
      let!(:namespace_mirror) { Ci::NamespaceMirror.find_by(namespace_id: namespace.id) }

      context 'when both objects exist' do
        it 'creates a Namespaces::SyncEvent to modify the target object' do
          expect do
            consistency_fix_service.execute(ids: [namespace.id])
          end.to change {
            Namespaces::SyncEvent.where(namespace_id: namespace.id).count
          }.by(1)
        end

        it 'enqueues the worker to process the Namespaces::SyncEvents' do
          expect(::Namespaces::ProcessSyncEventsWorker).to receive(:perform_async)
          consistency_fix_service.execute(ids: [namespace.id])
        end
      end

      context 'when the source object has been deleted, but not the target' do
        before do
          namespace.delete
        end

        it 'deletes the target object' do
          expect do
            consistency_fix_service.execute(ids: [namespace.id])
          end.to change { Ci::NamespaceMirror.where(namespace_id: namespace.id).count }.by(-1)
        end
      end
    end

    context 'fixing projects inconsistencies' do
      subject(:consistency_fix_service) do
        described_class.new(
          source_model: Project,
          target_model: Ci::ProjectMirror,
          sync_event_class: Projects::SyncEvent,
          source_sort_key: :id,
          target_sort_key: :project_id
        )
      end

      let(:table) { 'public.projects' }
      let!(:project) { create(:project) }
      let!(:project_mirror) { Ci::ProjectMirror.find_by(project_id: project.id) }

      context 'when both objects exist' do
        it 'creates a Projects::SyncEvent to modify the target object' do
          expect do
            consistency_fix_service.execute(ids: [project.id])
          end.to change {
            Projects::SyncEvent.where(project_id: project.id).count
          }.by(1)
        end

        it 'enqueues the worker to process the Projects::SyncEvents' do
          expect(::Projects::ProcessSyncEventsWorker).to receive(:perform_async)
          consistency_fix_service.execute(ids: [project.id])
        end
      end

      context 'when the source object has been deleted, but not the target' do
        before do
          project.delete
        end

        it 'deletes the target object' do
          expect do
            consistency_fix_service.execute(ids: [project.id])
          end.to change { Ci::ProjectMirror.where(project_id: project.id).count }.by(-1)
        end
      end
    end
  end

  describe '#create_sync_event_for' do
    context 'when the source model is Namespace' do
      let(:namespace) { create(:namespace) }

      let(:service) do
        described_class.new(
          source_model: Namespace,
          target_model: Ci::NamespaceMirror,
          sync_event_class: Namespaces::SyncEvent,
          source_sort_key: :id,
          target_sort_key: :namespace_id
        )
      end

      it 'creates a Namespaces::SyncEvent object' do
        expect do
          service.send(:create_sync_event_for, namespace.id)
        end.to change { Namespaces::SyncEvent.where(namespace_id: namespace.id).count }.by(1)
      end
    end

    context 'when the source model is Project' do
      let(:project) { create(:project) }

      let(:service) do
        described_class.new(
          source_model: Project,
          target_model: Ci::ProjectMirror,
          sync_event_class: Projects::SyncEvent,
          source_sort_key: :id,
          target_sort_key: :project_id
        )
      end

      it 'creates a Projects::SyncEvent object' do
        expect do
          service.send(:create_sync_event_for, project.id)
        end.to change { Projects::SyncEvent.where(project_id: project.id).count }.by(1)
      end
    end
  end

  context 'when the source model is User' do
    let(:service) do
      described_class.new(
        source_model: User,
        target_model: Ci::ProjectMirror,
        sync_event_class: Projects::SyncEvent,
        source_sort_key: :id,
        target_sort_key: :project_id
      )
    end

    it 'raises an error' do
      expect do
        service.send(:create_sync_event_for, 1)
      end.to raise_error("Unknown Source Model User")
    end
  end
end
