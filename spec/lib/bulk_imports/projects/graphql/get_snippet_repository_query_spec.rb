# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Graphql::GetSnippetRepositoryQuery do
  describe 'query repository based on full_path' do
    let_it_be(:entity)  { create(:bulk_import_entity) }
    let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
    let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

    it 'has a valid query' do
      query = GraphQL::Query.new(
        GitlabSchema,
        described_class.to_s,
        variables: described_class.variables(context)
      )
      result = GitlabSchema.static_validator.validate(query)

      expect(result[:errors]).to be_empty
    end

    it 'returns snippet httpUrlToRepo' do
      expect(described_class.to_s).to include('httpUrlToRepo')
    end

    it 'returns snippet createdAt' do
      expect(described_class.to_s).to include('createdAt')
    end

    it 'returns snippet title' do
      expect(described_class.to_s).to include('title')
    end

    describe '.variables' do
      it 'queries project based on source_full_path and pagination' do
        expected = { full_path: entity.source_full_path, cursor: nil, per_page: 500 }

        expect(described_class.variables(context)).to eq(expected)
      end
    end

    describe '.data_path' do
      it '.data_path returns data path' do
        expected = %w[data project snippets nodes]

        expect(described_class.data_path).to eq(expected)
      end
    end

    describe '.page_info_path' do
      it '.page_info_path returns pagination information path' do
        expected = %w[data project snippets page_info]

        expect(described_class.page_info_path).to eq(expected)
      end
    end
  end
end
