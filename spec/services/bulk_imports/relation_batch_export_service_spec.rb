# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::RelationBatchExportService, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:label) { create(:label, project: project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:export) { create(:bulk_import_export, :batched, project: project) }
  let_it_be(:batch) { create(:bulk_import_export_batch, export: export) }
  let_it_be(:cache_key) { BulkImports::BatchedRelationExportService.cache_key(export.id, batch.id) }

  subject(:service) { described_class.new(user.id, batch.id) }

  before(:all) do
    Gitlab::Cache::Import::Caching.set_add(cache_key, label.id)
  end

  after(:all) do
    Gitlab::Cache::Import::Caching.expire(cache_key, 0)
  end

  describe '#execute' do
    it 'exports relation batch' do
      expect(Gitlab::Cache::Import::Caching).to receive(:values_from_set).with(cache_key).and_call_original

      service.execute
      batch.reload

      expect(batch.finished?).to eq(true)
      expect(batch.objects_count).to eq(1)
      expect(batch.error).to be_nil
      expect(export.upload.export_file).to be_present
    end

    it 'removes exported contents after export' do
      double = instance_double(BulkImports::FileTransfer::ProjectConfig, export_path: 'foo')

      allow(BulkImports::FileTransfer).to receive(:config_for).and_return(double)
      allow(double).to receive(:export_service_for).and_raise(StandardError, 'Error!')
      allow(FileUtils).to receive(:remove_entry)

      expect(FileUtils).to receive(:remove_entry).with('foo')

      service.execute
    end

    context 'when exception occurs' do
      before do
        allow(service).to receive(:gzip).and_raise(StandardError, 'Error!')
      end

      it 'marks batch as failed' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception)
          .with(StandardError, portable_id: project.id, portable_type: 'Project')

        service.execute
        batch.reload

        expect(batch.failed?).to eq(true)
        expect(batch.objects_count).to eq(0)
        expect(batch.error).to eq('Error!')
      end
    end
  end
end
