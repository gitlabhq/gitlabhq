# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Migration::EnqueuerWorker, :aggregate_failures, :clean_gitlab_redis_shared_state,
  feature_category: :container_registry do
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
        expect(worker).not_to receive(:handle_next_migration)
        expect(worker).not_to receive(:handle_aborted_migration)

        subject

        expect(container_repository.reload).to be_default
      end
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

    context 'with no repository qualifies' do
      include_examples 'an idempotent worker' do
        before do
          allow(ContainerRepository).to receive(:ready_for_import).and_return(ContainerRepository.none)
        end

        it_behaves_like 'no action'
      end
    end

    context 'when multiple aborted imports are available' do
      let_it_be(:aborted_repository1) { create(:container_repository, :import_aborted) }
      let_it_be(:aborted_repository2) { create(:container_repository, :import_aborted) }

      before do
        container_repository.update!(created_at: 30.seconds.ago)
      end

      context 'with successful registry requests' do
        before do
          allow_worker(on: :next_aborted_repository) do |repository|
            allow(repository).to receive(:migration_import).and_return(:ok)
            allow(repository.gitlab_api_client).to receive(:import_status).and_return('import_failed')
          end
        end

        it 'retries the import for the aborted repository' do
          expect_log_info(
            [
              {
                import_type: 'retry',
                container_repository_id: aborted_repository1.id,
                container_repository_path: aborted_repository1.path,
                container_repository_migration_state: 'importing'
              },
              {
                import_type: 'retry',
                container_repository_id: aborted_repository2.id,
                container_repository_path: aborted_repository2.path,
                container_repository_migration_state: 'importing'
              }
            ]
          )

          expect(worker).to receive(:handle_next_migration).and_call_original

          subject

          expect(aborted_repository1.reload).to be_importing
          expect(aborted_repository2.reload).to be_importing
        end
      end

      context 'when an error occurs' do
        it 'does abort that migration' do
          allow_worker(on: :next_aborted_repository) do |repository|
            allow(repository).to receive(:retry_aborted_migration).and_raise(StandardError)
          end

          expect_log_info(
            [
              {
                import_type: 'retry',
                container_repository_id: aborted_repository1.id,
                container_repository_path: aborted_repository1.path,
                container_repository_migration_state: 'import_aborted'
              }
            ]
          )

          subject

          expect(aborted_repository1.reload).to be_import_aborted
          expect(aborted_repository2.reload).to be_import_aborted
        end
      end
    end

    context 'when multiple qualified repositories are available' do
      let_it_be(:container_repository2) { create(:container_repository, created_at: 2.days.ago) }

      before do
        allow_worker(on: :next_repository) do |repository|
          allow(repository).to receive(:migration_pre_import).and_return(:ok)
        end

        stub_container_registry_tags(
          repository: container_repository2.path,
          tags: %w(tag4 tag5 tag6),
          with_manifest: true
        )
      end

      shared_examples 'starting all the next imports' do
        it 'starts the pre-import for the next qualified repositories' do
          expect_log_info(
            [
              {
                import_type: 'next',
                container_repository_id: container_repository.id,
                container_repository_path: container_repository.path,
                container_repository_migration_state: 'pre_importing'
              },
              {
                import_type: 'next',
                container_repository_id: container_repository2.id,
                container_repository_path: container_repository2.path,
                container_repository_migration_state: 'pre_importing'
              }
            ]
          )

          expect(worker).to receive(:handle_next_migration).exactly(3).times.and_call_original

          expect { subject }.to make_queries_matching(/LIMIT 25/)

          expect(container_repository.reload).to be_pre_importing
          expect(container_repository2.reload).to be_pre_importing
        end
      end

      it_behaves_like 'starting all the next imports'

      context 'when the new pre-import maxes out the capacity' do
        before do
          # set capacity to 10
          stub_feature_flags(
            container_registry_migration_phase2_capacity_25: false,
            container_registry_migration_phase2_capacity_40: false
          )

          # Plus 2 created above gives 9 importing repositories
          create_list(:container_repository, 7, :importing)
        end

        it 'starts the pre-import only for one qualified repository' do
          expect_log_info(
            [
              {
                import_type: 'next',
                container_repository_id: container_repository.id,
                container_repository_path: container_repository.path,
                container_repository_migration_state: 'pre_importing'
              }
            ]
          )

          subject

          expect(container_repository.reload).to be_pre_importing
          expect(container_repository2.reload).to be_default
        end
      end

      context 'max tag count is 0' do
        before do
          stub_application_setting(container_registry_import_max_tags_count: 0)
          # Add 8 tags to the next repository
          stub_container_registry_tags(
            repository: container_repository.path, tags: %w(a b c d e f g h), with_manifest: true
          )
        end

        it_behaves_like 'starting all the next imports'
      end

      context 'when the deadline is hit' do
        it 'does not handle the second qualified repository' do
          expect(worker).to receive(:loop_deadline).and_return(5.seconds.from_now, 2.seconds.ago)
          expect(worker).to receive(:handle_next_migration).once.and_call_original

          subject

          expect(container_repository.reload).to be_pre_importing
          expect(container_repository2.reload).to be_default
        end
      end
    end

    context 'when a mix of aborted imports and qualified repositories are available' do
      let_it_be(:aborted_repository) { create(:container_repository, :import_aborted) }

      before do
        allow_worker(on: :next_aborted_repository) do |repository|
          allow(repository).to receive(:migration_import).and_return(:ok)
          allow(repository.gitlab_api_client).to receive(:import_status).and_return('import_failed')
        end

        allow_worker(on: :next_repository) do |repository|
          allow(repository).to receive(:migration_pre_import).and_return(:ok)
        end
      end

      it 'retries the aborted repository and start the migration on the qualified repository' do
        expect_log_info(
          [
            {
              import_type: 'retry',
              container_repository_id: aborted_repository.id,
              container_repository_path: aborted_repository.path,
              container_repository_migration_state: 'importing'
            },
            {
              import_type: 'next',
              container_repository_id: container_repository.id,
              container_repository_path: container_repository.path,
              container_repository_migration_state: 'pre_importing'
            }
          ]
        )

        subject

        expect(aborted_repository.reload).to be_importing
        expect(container_repository.reload).to be_pre_importing
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

    context 'over max tag count' do
      before do
        stub_application_setting(container_registry_import_max_tags_count: 2)
      end

      it 'skips the repository' do
        expect_log_info(
          [
            {
              import_type: 'next',
              container_repository_id: container_repository.id,
              container_repository_path: container_repository.path,
              container_repository_migration_state: 'import_skipped',
              container_repository_migration_skipped_reason: 'too_many_tags'
            }
          ]
        )

        expect(worker).to receive(:handle_next_migration).twice.and_call_original
        # skipping the migration will re_enqueue the job
        expect(described_class).to receive(:enqueue_a_job)

        subject

        expect(container_repository.reload).to be_import_skipped
        expect(container_repository.migration_skipped_reason).to eq('too_many_tags')
        expect(container_repository.migration_skipped_at).not_to be_nil
      end
    end

    context 'when an error occurs' do
      before do
        allow(ContainerRegistry::Migration).to receive(:max_tags_count).and_raise(StandardError)
      end

      it 'aborts the import' do
        expect_log_info(
          [
            {
              import_type: 'next',
              container_repository_id: container_repository.id,
              container_repository_path: container_repository.path,
              container_repository_migration_state: 'import_aborted'
            }
          ]
        )

        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          instance_of(StandardError),
          next_repository_id: container_repository.id
        )

        # aborting the migration will re_enqueue the job
        expect(described_class).to receive(:enqueue_a_job)

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
        expect(worker).not_to receive(:handle_aborted_migration)
        expect(worker).not_to receive(:handle_next_migration)

        subject
      end
    end

    def expect_log_extra_metadata(metadata)
      metadata.each do |key, value|
        expect(worker).to receive(:log_extra_metadata_on_done).with(key, value)
      end
    end

    def expect_log_info(expected_multiple_arguments)
      expected_multiple_arguments.each do |extras|
        expect(worker.logger).to receive(:info).with(worker.structured_payload(extras))
      end
    end

    def allow_worker(on:)
      method_repository = worker.method(on)
      allow(worker).to receive(on) do
        repository = method_repository.call

        yield repository if repository

        repository
      end
    end
  end

  describe 'worker attributes' do
    it 'has deduplication set' do
      expect(described_class.get_deduplicate_strategy).to eq(:until_executing)
      expect(described_class.get_deduplication_options).to include(ttl: 30.minutes)
    end
  end
end
