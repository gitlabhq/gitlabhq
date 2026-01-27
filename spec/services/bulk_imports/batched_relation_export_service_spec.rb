# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::BatchedRelationExportService, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:portable) { create(:group) }

  let(:relation) { 'labels' }
  let(:jid) { '123' }

  subject(:service) { described_class.new(user, portable, relation, jid) }

  describe '#execute' do
    context 'when there are batches to export' do
      let_it_be(:label) { create(:group_label, group: portable) }

      it 'marks export as started' do
        service.execute

        export = portable.bulk_import_exports.first

        expect(export.reload.started?).to eq(true)
      end

      it 'removes existing batches' do
        expect_next_instance_of(BulkImports::Export) do |export|
          expect(export.batches).to receive(:destroy_all)
        end

        service.execute
      end

      it 'enqueues export jobs for each batch & caches batch record ids' do
        expect(BulkImports::RelationBatchExportWorker).to receive(:perform_async)
        expect(Gitlab::Cache::Import::Caching).to receive(:set_add)

        service.execute
      end

      it 'enqueues FinishBatchedRelationExportWorker' do
        expect(BulkImports::FinishBatchedRelationExportWorker).to receive(:perform_async)

        service.execute
      end

      context 'when there are multiple batches' do
        before do
          stub_application_setting(relation_export_batch_size: 1)
          create_list(:group_label, 10, group: portable)
        end

        it 'creates a batch record for each batch of records' do
          service.execute

          export = portable.bulk_import_exports.first

          expect(export.batches.count).to eq(11)
        end

        it 'caches the batch size for the export' do
          # Execute once to set the cache
          service.execute

          # Run a new instance of the export service for the same relation with
          # a different batch size
          stub_application_setting(relation_export_batch_size: 2)
          described_class.new(user, portable, relation, jid).execute
          export = portable.bulk_import_exports.first

          expect(export.batches.count).to eq(11)
        end
      end

      context 'when an error occurs during batches creation' do
        it 'does not enqueue FinishBatchedRelationExportWorker' do
          allow(service).to receive(:enqueue_batch_exports).and_raise(StandardError)

          expect(BulkImports::FinishBatchedRelationExportWorker).not_to receive(:perform_async)

          expect { service.execute }.to raise_error(StandardError)
        end
      end

      shared_examples 'export batch deletion not logged' do
        it 'does not log deleting export batches' do
          expect(Gitlab::Export::Logger).not_to receive(:warn)

          service.execute
        end
      end

      it_behaves_like 'export batch deletion not logged'

      context 'when export_batch records already exist' do
        let_it_be_with_reload(:export) { create(:bulk_import_export, group: portable, user: user, batched: true) }
        let_it_be_with_reload(:export_batch) { create(:bulk_import_export_batch, export: export) }

        it 'logs restarting batched export for active processing export' do
          expect(Gitlab::Export::Logger).to receive(:warn).with(
            hash_including(
              message: 'Restarting batched export relation and deleting existing export batches',
              export_id: export.id,
              relation: relation,
              importer: Import::SOURCE_DIRECT_TRANSFER
            )
          )

          service.execute
        end

        context 'and the export is finished' do
          before do
            export.finish!
          end

          it_behaves_like 'export batch deletion not logged'
        end

        context 'and the export is failed' do
          before do
            export.fail_op!
          end

          it_behaves_like 'export batch deletion not logged'
        end

        context 'and the export batches are not in progress' do
          before do
            export.batches.map(&:fail_op!)
          end

          it_behaves_like 'export batch deletion not logged'
        end
      end
    end

    context 'when there are no batches to export' do
      let(:relation) { 'milestones' }

      it 'marks export as finished' do
        service.execute

        export = portable.bulk_import_exports.first

        expect(export.finished?).to eq(true)
        expect(export.batches.count).to eq(0)
      end
    end
  end

  describe '.cache_key' do
    it 'returns cache key given export and batch ids' do
      expect(described_class.cache_key(1, 1)).to eq('bulk_imports/batched_relation_export/1/1')
    end
  end

  describe '.batch_size_cache_key' do
    it 'returns the cache key for the export batch size' do
      expect(described_class.batch_size_cache_key(1)).to eq('bulk_imports/batched_relation_export/1/batch_size')
    end
  end
end
