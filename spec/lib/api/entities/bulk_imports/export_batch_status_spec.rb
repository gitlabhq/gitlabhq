# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::BulkImports::ExportBatchStatus, feature_category: :importers do
  let_it_be(:batch) { create(:bulk_import_export_batch) }

  let(:entity) { described_class.new(batch, request: double) }

  subject { entity.as_json }

  it 'has the correct attributes' do
    expect(subject).to eq(
      status: batch.status,
      batch_number: batch.batch_number,
      objects_count: batch.objects_count,
      error: batch.error,
      updated_at: batch.updated_at
    )
  end
end
