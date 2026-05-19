# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::ExportStatus, feature_category: :importers do
  describe '.for_context' do
    let(:relation) { 'labels' }
    let(:tracker) { build(:bulk_import_tracker, entity: entity) }

    context 'when the import is offline' do
      let(:offline_import) { build(:bulk_import, :with_offline_configuration) }
      let(:entity) { build(:bulk_import_entity, bulk_import: offline_import) }

      it 'returns an Import::Offline::ExportStatus instance' do
        expect(described_class.for_context(tracker, relation)).to be_a(Import::Offline::ExportStatus)
      end
    end

    context 'when the import is not offline' do
      let(:bulk_import) { build(:bulk_import, :with_configuration) }
      let(:entity) { build(:bulk_import_entity, bulk_import: bulk_import) }

      it 'returns a BulkImports::ExportStatus instance' do
        expect(described_class.for_context(tracker, relation)).to be_a(BulkImports::ExportStatus)
      end
    end
  end

  describe 'abstract methods' do
    let(:relation) { 'labels' }
    let(:entity) { build(:bulk_import_entity) }
    let(:tracker) { build(:bulk_import_tracker, entity: entity) }

    subject(:export_status) { described_class.new(tracker, relation) }

    describe '#in_progress?' do
      it 'raises Gitlab::AbstractMethodError' do
        expect { export_status.in_progress? }.to raise_error(Gitlab::AbstractMethodError)
      end
    end

    describe '#failed?' do
      it 'raises Gitlab::AbstractMethodError' do
        expect { export_status.failed? }.to raise_error(Gitlab::AbstractMethodError)
      end
    end

    describe '#waiting_on_export?' do
      it 'raises Gitlab::AbstractMethodError' do
        expect { export_status.waiting_on_export? }.to raise_error(Gitlab::AbstractMethodError)
      end
    end

    describe '#error' do
      it 'raises Gitlab::AbstractMethodError' do
        expect { export_status.error }.to raise_error(Gitlab::AbstractMethodError)
      end
    end

    describe '#batched?' do
      it 'raises Gitlab::AbstractMethodError' do
        expect { export_status.batched? }.to raise_error(Gitlab::AbstractMethodError)
      end
    end

    describe '#batches_count' do
      it 'raises Gitlab::AbstractMethodError' do
        expect { export_status.batches_count }.to raise_error(Gitlab::AbstractMethodError)
      end
    end

    describe '#all_batch_numbers' do
      it 'raises Gitlab::AbstractMethodError' do
        expect { export_status.all_batch_numbers }.to raise_error(Gitlab::AbstractMethodError)
      end
    end

    describe '#batch_failed?' do
      it 'raises Gitlab::AbstractMethodError' do
        expect { export_status.batch_failed?(1) }.to raise_error(Gitlab::AbstractMethodError)
      end
    end

    describe '#batch_error' do
      it 'raises Gitlab::AbstractMethodError' do
        expect { export_status.batch_error(1) }.to raise_error(Gitlab::AbstractMethodError)
      end
    end

    describe '#total_objects_count' do
      it 'raises Gitlab::AbstractMethodError' do
        expect { export_status.total_objects_count }.to raise_error(Gitlab::AbstractMethodError)
      end
    end
  end
end
