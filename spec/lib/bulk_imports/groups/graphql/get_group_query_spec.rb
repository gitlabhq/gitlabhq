# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Graphql::GetGroupQuery do
  describe '#variables' do
    it 'returns query variables based on entity information' do
      entity = double(source_full_path: 'test', bulk_import: nil)
      tracker = double(entity: entity)
      context = BulkImports::Pipeline::Context.new(tracker)
      expected = { full_path: entity.source_full_path }

      expect(described_class.variables(context)).to eq(expected)
    end
  end

  describe '#data_path' do
    it 'returns data path' do
      expected = %w[data group]

      expect(described_class.data_path).to eq(expected)
    end
  end

  describe '#page_info_path' do
    it 'returns pagination information path' do
      expected = %w[data group page_info]

      expect(described_class.page_info_path).to eq(expected)
    end
  end
end
