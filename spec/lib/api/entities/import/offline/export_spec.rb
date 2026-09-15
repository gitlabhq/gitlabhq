# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Import::Offline::Export, feature_category: :importers do
  subject(:entity) { described_class.new(export).as_json }

  context 'when the export has a configuration' do
    let_it_be(:export) { build_stubbed(:offline_export, :with_configuration) }

    it 'exposes the correct attributes' do
      expect(entity).to include(
        id: export.id,
        status: export.status_name,
        source_hostname: export.source_hostname,
        created_at: export.created_at,
        updated_at: export.updated_at,
        has_failures: export.has_failures,
        bucket: export.configuration.bucket,
        export_prefix: export.configuration.export_prefix
      )
    end
  end

  context 'when the export has no configuration' do
    let_it_be(:export) { build_stubbed(:offline_export) }

    it 'exposes bucket and export_prefix as nil' do
      expect(entity).to include(bucket: nil, export_prefix: nil)
    end
  end
end
