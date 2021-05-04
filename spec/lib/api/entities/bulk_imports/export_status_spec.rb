# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::BulkImports::ExportStatus do
  let_it_be(:export) { create(:bulk_import_export) }

  let(:entity) { described_class.new(export, request: double) }

  subject { entity.as_json }

  it 'has the correct attributes' do
    expect(subject).to eq({
      relation: export.relation,
      status: export.status,
      error: export.error,
      updated_at: export.updated_at
    })
  end
end
