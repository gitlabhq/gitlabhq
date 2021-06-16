#  frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImportWorker do
  describe '#perform' do
    context 'when no bulk import is found' do
      it 'does nothing' do
        expect(described_class).not_to receive(:perform_in)

        subject.perform(non_existing_record_id)
      end
    end

    context 'when bulk import is finished' do
      it 'does nothing' do
        bulk_import = create(:bulk_import, :finished)

        expect(described_class).not_to receive(:perform_in)

        subject.perform(bulk_import.id)
      end
    end

    context 'when bulk import is failed' do
      it 'does nothing' do
        bulk_import = create(:bulk_import, :failed)

        expect(described_class).not_to receive(:perform_in)

        subject.perform(bulk_import.id)
      end
    end

    context 'when all entities are processed' do
      it 'marks bulk import as finished' do
        bulk_import = create(:bulk_import, :started)
        create(:bulk_import_entity, :finished, bulk_import: bulk_import)
        create(:bulk_import_entity, :failed, bulk_import: bulk_import)

        subject.perform(bulk_import.id)

        expect(bulk_import.reload.finished?).to eq(true)
      end
    end

    context 'when all entities are failed' do
      it 'marks bulk import as failed' do
        bulk_import = create(:bulk_import, :started)
        create(:bulk_import_entity, :failed, bulk_import: bulk_import)
        create(:bulk_import_entity, :failed, bulk_import: bulk_import)

        subject.perform(bulk_import.id)

        expect(bulk_import.reload.failed?).to eq(true)
      end
    end

    context 'when maximum allowed number of import entities in progress' do
      it 'reenqueues itself' do
        bulk_import = create(:bulk_import, :started)
        (described_class::DEFAULT_BATCH_SIZE + 1).times { |_| create(:bulk_import_entity, :started, bulk_import: bulk_import) }

        expect(described_class).to receive(:perform_in).with(described_class::PERFORM_DELAY, bulk_import.id)

        subject.perform(bulk_import.id)
      end
    end

    context 'when bulk import is created' do
      it 'marks bulk import as started' do
        bulk_import = create(:bulk_import, :created)
        create(:bulk_import_entity, :created, bulk_import: bulk_import)

        subject.perform(bulk_import.id)

        expect(bulk_import.reload.started?).to eq(true)
      end

      it 'creates all the required pipeline trackers' do
        bulk_import = create(:bulk_import, :created)
        entity_1 = create(:bulk_import_entity, :created, bulk_import: bulk_import)
        entity_2 = create(:bulk_import_entity, :created, bulk_import: bulk_import)

        expect { subject.perform(bulk_import.id) }
          .to change(BulkImports::Tracker, :count)
          .by(BulkImports::Stage.pipelines.size * 2)

        expect(entity_1.trackers).not_to be_empty
        expect(entity_2.trackers).not_to be_empty
      end

      context 'when there are created entities to process' do
        it 'marks a batch of entities as started, enqueues EntityWorker, ExportRequestWorker and reenqueues' do
          stub_const("#{described_class}::DEFAULT_BATCH_SIZE", 1)

          bulk_import = create(:bulk_import, :created)
          create(:bulk_import_entity, :created, bulk_import: bulk_import)
          create(:bulk_import_entity, :created, bulk_import: bulk_import)

          expect(described_class).to receive(:perform_in).with(described_class::PERFORM_DELAY, bulk_import.id)
          expect(BulkImports::EntityWorker).to receive(:perform_async)
          expect(BulkImports::ExportRequestWorker).to receive(:perform_async)

          subject.perform(bulk_import.id)

          expect(bulk_import.entities.map(&:status_name)).to contain_exactly(:created, :started)
        end
      end

      context 'when exception occurs' do
        it 'tracks the exception & marks import as failed' do
          bulk_import = create(:bulk_import, :created)
          create(:bulk_import_entity, :created, bulk_import: bulk_import)

          allow(BulkImports::EntityWorker).to receive(:perform_async).and_raise(StandardError)

          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(kind_of(StandardError), bulk_import_id: bulk_import.id)

          subject.perform(bulk_import.id)

          expect(bulk_import.reload.failed?).to eq(true)
        end
      end
    end
  end
end
