# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Migration::EnqueuerWorker, :aggregate_failures do
  let_it_be_with_reload(:container_repository) { create(:container_repository, created_at: 2.days.ago) }

  let(:worker) { described_class.new }

  before do
    stub_container_registry_config(enabled: true)
    stub_application_setting(container_registry_import_created_before: 1.day.ago)
    stub_container_registry_tags(repository: container_repository.path, tags: %w(tag1 tag2 tag3), with_manifest: true)
  end

  describe '#perform' do
    subject { worker.perform }

    shared_examples 'no action' do
      it 'does not queue or change any repositories' do
        subject

        expect(container_repository.reload).to be_default
      end
    end

    shared_examples 're-enqueuing based on capacity' do
      context 'below capacity' do
        before do
          allow(ContainerRegistry::Migration).to receive(:capacity).and_return(9999)
        end

        it 're-enqueues the worker' do
          expect(ContainerRegistry::Migration::EnqueuerWorker).to receive(:perform_async)

          subject
        end
      end

      context 'above capacity' do
        before do
          allow(ContainerRegistry::Migration).to receive(:capacity).and_return(-1)
        end

        it 'does not re-enqueue the worker' do
          expect(ContainerRegistry::Migration::EnqueuerWorker).not_to receive(:perform_async)

          subject
        end
      end
    end

    context 'with qualified repository' do
      it 'starts the pre-import for the next qualified repository' do
        method = worker.method(:next_repository)
        allow(worker).to receive(:next_repository) do
          next_qualified_repository = method.call
          allow(next_qualified_repository).to receive(:migration_pre_import).and_return(:ok)
          next_qualified_repository
        end

        expect(worker).to receive(:log_extra_metadata_on_done)
          .with(:container_repository_id, container_repository.id)
        expect(worker).to receive(:log_extra_metadata_on_done)
          .with(:import_type, 'next')

        subject

        expect(container_repository.reload).to be_pre_importing
      end

      it_behaves_like 're-enqueuing based on capacity'
    end

    context 'migrations are disabled' do
      before do
        allow(ContainerRegistry::Migration).to receive(:enabled?).and_return(false)
      end

      it_behaves_like 'no action'
    end

    context 'above capacity' do
      before do
        create(:container_repository, :importing)
        create(:container_repository, :importing)
        allow(ContainerRegistry::Migration).to receive(:capacity).and_return(1)
      end

      it_behaves_like 'no action'

      it 'does not re-enqueue the worker' do
        expect(ContainerRegistry::Migration::EnqueuerWorker).not_to receive(:perform_async)

        subject
      end
    end

    context 'too soon before previous completed import step' do
      before do
        create(:container_repository, :import_done, migration_import_done_at: 1.minute.ago)
        allow(ContainerRegistry::Migration).to receive(:enqueue_waiting_time).and_return(1.hour)
      end

      it_behaves_like 'no action'
    end

    context 'when an aborted import is available' do
      let_it_be(:aborted_repository) { create(:container_repository, :import_aborted) }

      it 'retries the import for the aborted repository' do
        method = worker.method(:next_aborted_repository)
        allow(worker).to receive(:next_aborted_repository) do
          next_aborted_repository = method.call
          allow(next_aborted_repository).to receive(:migration_import).and_return(:ok)
          allow(next_aborted_repository.gitlab_api_client).to receive(:import_status).and_return('import_failed')
          next_aborted_repository
        end

        expect(worker).to receive(:log_extra_metadata_on_done)
          .with(:container_repository_id, aborted_repository.id)
        expect(worker).to receive(:log_extra_metadata_on_done)
          .with(:import_type, 'retry')

        subject

        expect(aborted_repository.reload).to be_importing
        expect(container_repository.reload).to be_default
      end

      it_behaves_like 're-enqueuing based on capacity'
    end

    context 'when no repository qualifies' do
      include_examples 'an idempotent worker' do
        before do
          allow(ContainerRepository).to receive(:ready_for_import).and_return(ContainerRepository.none)
        end

        it_behaves_like 'no action'
      end
    end

    context 'over max tag count' do
      before do
        stub_application_setting(container_registry_import_max_tags_count: 2)
      end

      it 'skips the repository' do
        subject

        expect(container_repository.reload).to be_import_skipped
        expect(container_repository.migration_skipped_reason).to eq('too_many_tags')
        expect(container_repository.migration_skipped_at).not_to be_nil
      end

      it_behaves_like 're-enqueuing based on capacity'
    end

    context 'when an error occurs' do
      before do
        allow(ContainerRegistry::Migration).to receive(:max_tags_count).and_raise(StandardError)
      end

      it 'aborts the import' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          instance_of(StandardError),
          next_repository_id: container_repository.id,
          next_aborted_repository_id: nil
        )

        subject

        expect(container_repository.reload).to be_import_aborted
      end
    end
  end
end
