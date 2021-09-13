# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Graphql::GetProjectsQuery do
  describe '#variables' do
    it 'returns valid variables based on entity information' do
      tracker = create(:bulk_import_tracker)
      context = BulkImports::Pipeline::Context.new(tracker)

      query = GraphQL::Query.new(
        GitlabSchema,
        described_class.to_s,
        variables: described_class.variables(context)
      )
      result = GitlabSchema.static_validator.validate(query)

      expect(result[:errors]).to be_empty
    end

    context 'with invalid variables' do
      it 'raises an error' do
        expect { GraphQL::Query.new(GitlabSchema, described_class.to_s, variables: 'invalid') }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#data_path' do
    it 'returns data path' do
      expected = %w[data group projects nodes]

      expect(described_class.data_path).to eq(expected)
    end
  end

  describe '#page_info_path' do
    it 'returns pagination information path' do
      expected = %w[data group projects page_info]

      expect(described_class.page_info_path).to eq(expected)
    end
  end
end
