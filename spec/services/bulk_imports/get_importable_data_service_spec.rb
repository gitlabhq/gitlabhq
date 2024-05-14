# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::GetImportableDataService, feature_category: :importers do
  describe '#execute' do
    include_context 'bulk imports requests context', 'https://gitlab.example.com'

    let_it_be(:params) { { per_page: 20, page: 1 } }
    let_it_be(:query_params) { { top_level_only: true, min_access_level: 50, search: '' } }
    let_it_be(:credentials) { { url: 'https://gitlab.example.com', access_token: 'demo-pat' } }
    let_it_be(:expected_version_validation) do
      {
        features: {
          project_migration: {
            available: true,
            min_version: BulkImport.min_gl_version_for_project_migration.to_s
          },
          source_instance_version: BulkImport.min_gl_version_for_project_migration.to_s
        }
      }
    end

    let_it_be(:expected_parsed_response) do
      [
        {
          'id' => 2595438,
          'web_url' => 'https://gitlab.com/groups/auto-breakfast',
          'name' => 'Stub',
          'path' => 'stub-group',
          'full_name' => 'Stub',
          'full_path' => 'stub-group'
        }
      ]
    end

    let(:source_version) do
      Gitlab::VersionInfo.new(
        ::BulkImport::MIN_MAJOR_VERSION,
        ::BulkImport::MIN_MINOR_VERSION_FOR_PROJECT
      )
    end

    before do
      allow_next_instance_of(BulkImports::Clients::HTTP) do |instance|
        allow(instance).to receive(:instance_version).and_return(source_version)
        allow(instance).to receive(:instance_enterprise).and_return(false)
      end
    end

    subject do
      described_class.new(params, query_params, credentials).execute
    end

    it 'returns version_validation and a response' do
      expect(subject[:version_validation]).to eq(expected_version_validation)
      expect(subject[:response].parsed_response).to eq(expected_parsed_response)
    end
  end
end
