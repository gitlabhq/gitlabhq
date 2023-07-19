# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::BulkImports::ExportStatus, feature_category: :importers do
  let_it_be(:export) { create(:bulk_import_export) }

  let(:entity) { described_class.new(export, request: double) }

  subject { entity.as_json }

  it 'has the correct attributes' do
    expect(subject).to eq(
      relation: export.relation,
      status: export.status,
      error: export.error,
      updated_at: export.updated_at,
      batched: export.batched?,
      batches_count: export.batches_count,
      total_objects_count: export.total_objects_count
    )
  end

  context 'when export is batched' do
    let_it_be(:export) { create(:bulk_import_export, :batched) }

    it 'exposes batches' do
      expect(subject).to match(hash_including(batches: []))
    end
  end
end
