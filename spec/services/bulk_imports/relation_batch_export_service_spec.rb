# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::RelationBatchExportService, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:label) { create(:label, project: project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:export) { create(:bulk_import_export, :batched, project: project) }
  let_it_be(:batch) { create(:bulk_import_export_batch, export: export) }
  let_it_be(:cache_key) { BulkImports::BatchedRelationExportService.cache_key(export.id, batch.id) }

  subject(:service) { described_class.new(user, batch) }

  before_all do
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
      allow(subject).to receive(:export_path).and_return('foo')
      allow(FileUtils).to receive(:remove_entry)

      expect(FileUtils).to receive(:remove_entry).with('foo')

      service.execute
    end

    it 'updates export updated_at so the timeout resets' do
      expect { service.execute }.to change { export.reload.updated_at }
    end

    context 'when relation is empty and there is nothing to export' do
      let_it_be(:export) { create(:bulk_import_export, :batched, project: project, relation: 'milestones') }
      let_it_be(:batch) { create(:bulk_import_export_batch, export: export) }

      it 'creates empty file on disk' do
        allow(subject).to receive(:export_path).and_return('foo')
        allow(FileUtils).to receive(:remove_entry)

        expect(FileUtils).to receive(:touch).with('foo/milestones.ndjson').and_call_original

        subject.execute
      end
    end
  end
end
