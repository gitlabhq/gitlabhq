# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::RelationExportWorker, feature_category: :importers do
  let_it_be(:jid) { 'jid' }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:relation) { 'labels' }

  let(:batched) { false }
  let(:offline_export_id) { nil }
  let(:job_args) do
    [
      user.id,
      group.id,
      group.class.name,
      relation,
      batched,
      { 'offline_export_id' => offline_export_id }
    ]
  end

  describe '#perform' do
    include_examples 'an idempotent worker' do
      context 'when export record does not exist' do
        let(:another_group) { create(:group) }
        let(:job_args) { [user.id, another_group.id, another_group.class.name, relation, batched] }

        it 'creates export record' do
          another_group.add_owner(user)

          expect { perform_multiple(job_args) }
            .to change { another_group.bulk_import_exports.count }
            .from(0)
            .to(1)
        end
      end

      shared_examples 'export service' do |export_service|
        it 'executes export service' do
          group.add_owner(user)

          service = instance_double(export_service)

          expect(export_service)
            .to receive(:new)
            .with(
              user,
              group,
              relation,
              anything,
              hash_including(offline_export_id:)
            )
            .twice
            .and_return(service)
          expect(service).to receive(:execute).twice

          perform_multiple(job_args)
        end
      end

      context 'when export is batched' do
        let(:batched) { true }

        context 'when relation is batchable' do
          include_examples 'export service', BulkImports::BatchedRelationExportService
        end

        context 'when relation is not batchable' do
          let(:relation) { 'namespace_settings' }

          include_examples 'export service', BulkImports::RelationExportService
        end
      end

      context 'when export is not batched' do
        include_examples 'export service', BulkImports::RelationExportService
      end

      context 'when export is user_contributions' do
        let(:relation) { 'user_contributions' }

        it 'does not enqueue user contributions export' do
          expect(BulkImports::UserContributionsExportWorker).not_to receive(:perform_async)

          perform_multiple(job_args)
        end
      end

      context 'when offline export is provided' do
        let_it_be(:export) { create(:offline_export) }
        let(:offline_export_id) { export.id }

        include_examples 'export service', BulkImports::RelationExportService

        context 'and export is user_contributions' do
          let(:relation) { 'user_contributions' }

          it 'enqueues the UserContributionsExportWorker' do
            expect(BulkImports::UserContributionsExportWorker).to receive(:perform_async).with(
              group.id, group.class.name, user.id
            ).twice

            perform_multiple(job_args)
          end

          context 'when offline_transfer_exports feature flag is disabled' do
            before do
              stub_feature_flags(offline_transfer_exports: false)
            end

            it 'does not enqueue user contributions export' do
              expect(BulkImports::UserContributionsExportWorker).not_to receive(:perform_async)

              perform_multiple(job_args)
            end
          end
        end
      end
    end
  end

  describe '.perform_failure', :aggregate_failures do
    let(:job) { { 'args' => job_args } }
    let_it_be_with_reload(:export) { create(:bulk_import_export, group: group, relation: relation, user_id: user.id) }
    let_it_be_with_reload(:offline_export) do
      create(:bulk_import_export, :offline, group: group, relation: relation, user_id: user.id)
    end

    context 'when called by .sidekiq_retries_exhausted' do
      it 'sets export status to failed and tracks the exception' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception)
          .with(kind_of(StandardError), portable_id: group.id, portable_type: group.class.name)

        described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new('*' * 300))

        expect(export.reload).to be_failed
        expect(export.error.size).to eq(255)
        expect(offline_export.reload).not_to be_failed
      end
    end

    context 'when called by .sidekiq_interruptions_exhausted' do
      it 'sets export status to failed' do
        described_class.interruptions_exhausted_block.call(job)
        expect(export.reload).to be_failed
        expect(export.error).to eq('Export process reached the maximum number of interruptions')
        expect(offline_export.reload).not_to be_failed
      end
    end
  end
end
