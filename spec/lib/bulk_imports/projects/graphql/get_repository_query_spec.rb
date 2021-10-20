# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Graphql::GetRepositoryQuery do
  describe 'query repository based on full_path' do
    let(:entity)  { double(source_full_path: 'test', bulk_import: nil) }
    let(:tracker) { double(entity: entity) }
    let(:context) { BulkImports::Pipeline::Context.new(tracker) }

    it 'returns project repository url' do
      expect(described_class.to_s).to include('httpUrlToRepo')
    end

    it 'queries project based on source_full_path' do
      expected = { full_path: entity.source_full_path }

      expect(described_class.variables(context)).to eq(expected)
    end
  end
end
