# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Migration::EnqueuerWorker, :aggregate_failures, :clean_gitlab_redis_shared_state do
  using RSpec::Parameterized::TableSyntax
  include ExclusiveLeaseHelpers

  let_it_be_with_reload(:container_repository) { create(:container_repository, created_at: 2.days.ago) }
  let_it_be(:importing_repository) { create(:container_repository, :importing) }
  let_it_be(:pre_importing_repository) { create(:container_repository, :pre_importing) }

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

    shared_examples 're-enqueuing based on capacity' do |capacity_limit: 4|
      context 'below capacity' do
        before do
          allow(ContainerRegistry::Migration).to receive(:capacity).and_return(capacity_limit)
        end

        it 're-enqueues the worker' do
          expect(described_class).to receive(:perform_async)

          subject
        end
      end

      context 'above capacity' do
        before do
          allow(ContainerRegistry::Migration).to receive(:capacity).and_return(-1)
        end

        it 'does not re-enqueue the worker' do
          expect(described_class).not_to receive(:perform_async)

          subject
        end
      end
    end

    context 'with qualified repository' do
      before do
        method = worker.method(:next_repository)
        allow(worker).to receive(:next_repository) do
          next_qualified_repository = method.call
          allow(next_qualified_repository).to receive(:migration_pre_import).and_return(:ok)
          next_qualified_repository
        end
      end

      it 'starts the pre-import for the next qualified repository' do
        expect_log_extra_metadata(
          import_type: 'next',
          container_repository_id: container_repository.id,
          container_repository_path: container_repository.path,
          container_repository_migration_state: 'pre_importing'
        )

        subject

        expect(container_repository.reload).to be_pre_importing
      end

      context 'when the new pre-import maxes out the capacity' do
        before do
          # set capacity to 10
          stub_feature_flags(
            container_registry_migration_phase2_capacity_25: false
          )

          # Plus 2 created above gives 9 importing repositories
          create_list(:container_repository, 7, :importing)
        end

        it 'does not re-enqueue the worker' do
          expect(described_class).not_to receive(:perform_async)

          subject
        end
      end

      it_behaves_like 're-enqueuing based on capacity'
    end

    context 'migrations are disabled' do
      before do
        allow(ContainerRegistry::Migration).to receive(:enabled?).and_return(false)
      end

      it_behaves_like 'no action' do
        before do
          expect_log_extra_metadata(migration_enabled: false)
        end
      end
    end

    context 'above capacity' do
      before do
        create(:container_repository, :importing)
        create(:container_repository, :importing)
        allow(ContainerRegistry::Migration).to receive(:capacity).and_return(1)
      end

      it_behaves_like 'no action' do
        before do
          expect_log_extra_metadata(below_capacity: false, max_capacity_setting: 1)
        end
      end

      it 'does not re-enqueue the worker' do
        expect(ContainerRegistry::Migration::EnqueuerWorker).not_to receive(:perform_async)

        subject
      end
    end

    context 'too soon before previous completed import step' do
      where(:state, :timestamp) do
        :import_done     | :migration_import_done_at
        :pre_import_done | :migration_pre_import_done_at
        :import_aborted  | :migration_aborted_at
        :import_skipped  | :migration_skipped_at
      end

      with_them do
        before do
          allow(ContainerRegistry::Migration).to receive(:enqueue_waiting_time).and_return(45.minutes)
          create(:container_repository, state, timestamp => 1.minute.ago)
        end

        it_behaves_like 'no action' do
          before do
            expect_log_extra_metadata(waiting_time_passed: false, current_waiting_time_setting: 45.minutes)
          end
        end
      end

      context 'when last completed repository has nil timestamps' do
        before do
          allow(ContainerRegistry::Migration).to receive(:enqueue_waiting_time).and_return(45.minutes)
          create(:container_repository, migration_state: 'import_done')
        end

        it 'continues to try the next import' do
          expect { subject }.to change { container_repository.reload.migration_state }
        end
      end
    end

    context 'when an aborted import is available' do
      let_it_be(:aborted_repository) { create(:container_repository, :import_aborted) }

      context 'with a successful registry request' do
        before do
          method = worker.method(:next_aborted_repository)
          allow(worker).to receive(:next_aborted_repository) do
            next_aborted_repository = method.call
            allow(next_aborted_repository).to receive(:migration_import).and_return(:ok)
            allow(next_aborted_repository.gitlab_api_client).to receive(:import_status).and_return('import_failed')
            next_aborted_repository
          end
        end

        it 'retries the import for the aborted repository' do
          expect_log_extra_metadata(
            import_type: 'retry',
            container_repository_id: aborted_repository.id,
            container_repository_path: aborted_repository.path,
            container_repository_migration_state: 'importing'
          )

          subject

          expect(aborted_repository.reload).to be_importing
          expect(container_repository.reload).to be_default
        end

        it_behaves_like 're-enqueuing based on capacity'
      end

      context 'when an error occurs' do
        it 'does not abort that migration' do
          method = worker.method(:next_aborted_repository)
          allow(worker).to receive(:next_aborted_repository) do
            next_aborted_repository = method.call
            allow(next_aborted_repository).to receive(:retry_aborted_migration).and_raise(StandardError)
            next_aborted_repository
          end

          expect_log_extra_metadata(
            import_type: 'retry',
            container_repository_id: aborted_repository.id,
            container_repository_path: aborted_repository.path,
            container_repository_migration_state: 'import_aborted'
          )

          subject

          expect(aborted_repository.reload).to be_import_aborted
          expect(container_repository.reload).to be_default
        end
      end
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
        expect_log_extra_metadata(
          import_type: 'next',
          container_repository_id: container_repository.id,
          container_repository_path: container_repository.path,
          container_repository_migration_state: 'import_skipped',
          tags_count_too_high: true,
          max_tags_count_setting: 2
        )

        subject

        expect(container_repository.reload).to be_import_skipped
        expect(container_repository.migration_skipped_reason).to eq('too_many_tags')
        expect(container_repository.migration_skipped_at).not_to be_nil
      end

      it_behaves_like 're-enqueuing based on capacity', capacity_limit: 3
    end

    context 'when an error occurs' do
      before do
        allow(ContainerRegistry::Migration).to receive(:max_tags_count).and_raise(StandardError)
      end

      it 'aborts the import' do
        expect_log_extra_metadata(
          import_type: 'next',
          container_repository_id: container_repository.id,
          container_repository_path: container_repository.path,
          container_repository_migration_state: 'import_aborted'
        )

        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          instance_of(StandardError),
          next_repository_id: container_repository.id
        )

        subject

        expect(container_repository.reload).to be_import_aborted
      end
    end

    context 'with the exclusive lease taken' do
      let(:lease_key) { worker.send(:lease_key) }

      before do
        stub_exclusive_lease_taken(lease_key, timeout: 30.minutes)
      end

      it 'does not perform' do
        expect(worker).not_to receive(:runnable?)
        expect(worker).not_to receive(:re_enqueue_if_capacity)

        subject
      end
    end

    def expect_log_extra_metadata(metadata)
      metadata.each do |key, value|
        expect(worker).to receive(:log_extra_metadata_on_done).with(key, value)
      end
    end
  end
end
