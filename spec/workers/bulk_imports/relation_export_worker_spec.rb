# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::RelationExportWorker, feature_category: :importers do
  let_it_be(:jid) { 'jid' }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:batched) { false }
  let(:relation) { 'labels' }
  let(:job_args) { [user.id, group.id, group.class.name, relation, batched] }

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
            .with(user, group, relation, anything)
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

        context 'and :importer_user_mapping feature flag is enabled' do
          it 'enqueues the UserContributionsExportWorker' do
            expect(BulkImports::UserContributionsExportWorker).to receive(:perform_async).with(
              group.id, group.class.name, user.id
            ).twice

            perform_multiple(job_args)
          end
        end

        context 'and :importer_user_mapping feature flag is disabled' do
          before do
            stub_feature_flags(importer_user_mapping: false)
          end

          it 'does not enqueue the UserContributionsExportWorker' do
            expect(BulkImports::UserContributionsExportWorker).not_to receive(:perform_async)

            perform_multiple(job_args)
          end

          it 'does not create a user contributions export with a different service' do
            expect { perform_multiple(job_args) }.not_to change {
              group.bulk_import_exports.where(relation: 'user_contributions').count
            }.from(0)
          end
        end
      end
    end
  end

  describe '.sidekiq_retries_exhausted' do
    let(:job) { { 'args' => job_args } }
    let!(:export) { create(:bulk_import_export, group: group, relation: relation, user_id: user.id) }

    it 'sets export status to failed and tracks the exception' do
      expect(Gitlab::ErrorTracking)
        .to receive(:track_exception)
        .with(kind_of(StandardError), portable_id: group.id, portable_type: group.class.name)

      described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new('*' * 300))

      expect(export.reload.failed?).to eq(true)
      expect(export.error.size).to eq(255)
    end
  end

  describe '.sidekiq_interruptions_exhausted' do
    let!(:export) { create(:bulk_import_export, group: group, relation: relation, user_id: user.id) }

    it 'sets export status to failed' do
      job = { 'args' => job_args }

      described_class.interruptions_exhausted_block.call(job)
      expect(export.reload).to be_failed
      expect(export.error).to eq('Export process reached the maximum number of interruptions')
    end
  end
end
