# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::BatchedRelationExportService, feature_category: :importers do
  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:portable) { create(:group) }

  let(:relation) { 'labels' }
  let(:jid) { '123' }

  subject(:service) { described_class.new(user, portable, relation, jid) }

  describe '#execute' do
    context 'when there are batches to export' do
      let_it_be(:label) { create(:group_label, group: portable) }

      it 'marks export as started' do
        service.execute

        export = portable.bulk_import_exports.first

        expect(export.reload.started?).to be(true)
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

        context 'when the export is for an offline transfer' do
          let_it_be(:offline_export_record) { create(:offline_export) }
          let_it_be_with_reload(:offline_bulk_export) do
            create(:bulk_import_export, group: portable, batched: true,
              offline_export_id: offline_export_record.id)
          end

          let_it_be_with_reload(:offline_export_batch) do
            create(:bulk_import_export_batch, export: offline_bulk_export)
          end

          subject(:service) do
            described_class.new(user, portable, relation, jid, offline_export_id: offline_export_record.id)
          end

          it 'logs with offline transfer importer' do
            expect(Gitlab::Export::Logger).to receive(:warn).with(
              hash_including(
                importer: Import::SOURCE_OFFLINE_TRANSFER
              )
            )

            service.execute
          end
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

        expect(export.finished?).to be(true)
        expect(export.batches.count).to eq(0)
      end
    end

    context 'with offline_export_id' do
      let_it_be(:offline_export) { create(:offline_export, user: user) }

      subject(:service) { described_class.new(user, portable, relation, jid, offline_export_id: offline_export.id) }

      it 'creates export with offline_export_id' do
        service.execute

        expect(portable.bulk_import_exports).not_to be_empty

        portable.bulk_import_exports.all? do |export|
          expect(export.offline_export_id).to eq(offline_export.id)
          expect(export.user_id).to be_nil
        end
      end

      it 'reuses existing export with same offline_export_id' do
        _existing_export = create(:bulk_import_export,
          group: portable,
          offline_export_id: offline_export.id,
          relation: relation,
          user: nil
        )

        expect { service.execute }.not_to change { portable.bulk_import_exports.count }
      end
    end
  end

  describe '#execute with commit_notes' do
    let_it_be(:project) { create(:project, :small_repo) }
    let_it_be(:commit_sha) { project.repository.commit.id }
    let_it_be(:commit_note) { create(:note_on_commit, project: project, commit_id: commit_sha) }

    let(:relation) { 'commit_notes' }

    subject(:service) { described_class.new(user, project, relation, jid) }

    it 'caches commit-note IDs (not SHAs) and enqueues a worker per note batch' do
      expect(BulkImports::RelationBatchExportWorker).to receive(:perform_async).at_least(:once)

      service.execute

      export = project.bulk_import_exports.first
      cached_ids = export.batches.flat_map do |batch|
        Gitlab::Cache::Import::Caching.values_from_set(described_class.cache_key(export.id, batch.id))
      end

      expect(cached_ids).to contain_exactly(commit_note.id.to_s)
    end

    it 'sets total_objects_count and batches_count from the commit notes count', :aggregate_failures do
      service.execute

      export = project.bulk_import_exports.first
      expect(export.total_objects_count).to eq(1)
      expect(export.batches_count).to eq(1)
      expect(export.batches.count).to eq(1)
    end

    it 'corrects total_objects_count and batches_count to what was actually enqueued', :aggregate_failures do
      # The upfront count sees 3 notes (batches_count would be 3 at batch size 1), but
      # stub the walk to enqueue only one batch, e.g. the other notes' commits are no
      # longer reachable from refs.
      stub_application_setting(relation_export_batch_size: 1)
      create_list(:note_on_commit, 2, project: project, commit_id: commit_sha)

      allow_next_instance_of(::Import::Export::Project::CommitNotesBatcher) do |batcher|
        allow(batcher).to receive(:each_commit_note_id_batch).and_yield([commit_note.id])
      end

      service.execute

      export = project.bulk_import_exports.first
      expect(export.total_objects_count).to eq(1)
      expect(export.batches_count).to eq(1)
      expect(export.batches.count).to eq(1)
    end

    it 'enqueues FinishBatchedRelationExportWorker' do
      expect(BulkImports::FinishBatchedRelationExportWorker).to receive(:perform_async)

      service.execute
    end

    context 'when there are more commit notes than the batch size' do
      before do
        stub_application_setting(relation_export_batch_size: 2)
        stub_const('Import::Export::Project::CommitNotesBatcher::DEFAULT_BATCH_SIZE', 2)
        create_list(:note_on_commit, 3, project: project, commit_id: commit_sha)
      end

      it 'splits the note IDs into full batches without empty ones', :aggregate_failures do
        service.execute

        export = project.bulk_import_exports.first
        # 4 commit notes / batch size 2 = 2 batches
        expect(export.batches_count).to eq(2)
        expect(export.batches.count).to eq(2)

        cached_ids = export.batches.flat_map do |batch|
          Gitlab::Cache::Import::Caching.values_from_set(described_class.cache_key(export.id, batch.id))
        end
        expect(cached_ids.size).to eq(4)
      end
    end

    context 'with the commit notes batch size' do
      let(:default_batch_size) { ::Import::Export::Project::CommitNotesBatcher::DEFAULT_BATCH_SIZE }

      it 'uses relation_export_batch_size when it exceeds the batcher default' do
        stub_application_setting(relation_export_batch_size: default_batch_size + 50)

        expect(::Import::Export::Project::CommitNotesBatcher)
          .to receive(:new).with(project, batch_size: default_batch_size + 50).and_call_original

        service.execute
      end

      it 'uses the batcher default when it exceeds relation_export_batch_size' do
        stub_application_setting(relation_export_batch_size: default_batch_size - 50)

        expect(::Import::Export::Project::CommitNotesBatcher)
          .to receive(:new)
          .with(project, batch_size: default_batch_size)
          .and_call_original

        service.execute
      end
    end

    context 'when the project has commits but no commit notes' do
      let_it_be(:empty_notes_project) { create(:project, :small_repo) }

      subject(:service) { described_class.new(user, empty_notes_project, relation, jid) }

      it 'enqueues no batches and finishes the export immediately' do
        expect(BulkImports::RelationBatchExportWorker).not_to receive(:perform_async)

        service.execute

        export = empty_notes_project.bulk_import_exports.first
        expect(export.finished?).to be(true)
        expect(export.batches.count).to eq(0)
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(commit_notes_export_via_repo: false)
      end

      it 'falls back to the default notes batching path' do
        expect(::Import::Export::Project::CommitNotesBatcher).not_to receive(:new)

        service.execute
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
