# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Import::Offline::Export, feature_category: :importers do
  let_it_be(:export) { build_stubbed(:offline_export) }

  subject(:entity) { described_class.new(export).as_json }

  it 'exposes the correct attributes' do
    expect(entity).to include(
      id: export.id,
      status: export.status_name,
      source_hostname: export.source_hostname,
      created_at: export.created_at,
      updated_at: export.updated_at,
      has_failures: export.has_failures
    )
  end
end
