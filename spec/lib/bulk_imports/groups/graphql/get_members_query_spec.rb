# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Graphql::GetMembersQuery do
  it 'has a valid query' do
    entity = create(:bulk_import_entity)
    context = BulkImports::Pipeline::Context.new(entity)

    query = GraphQL::Query.new(
      GitlabSchema,
      described_class.to_s,
      variables: described_class.variables(context)
    )
    result = GitlabSchema.static_validator.validate(query)

    expect(result[:errors]).to be_empty
  end

  describe '#data_path' do
    it 'returns data path' do
      expected = %w[data group group_members nodes]

      expect(described_class.data_path).to eq(expected)
    end
  end

  describe '#page_info_path' do
    it 'returns pagination information path' do
      expected = %w[data group group_members page_info]

      expect(described_class.page_info_path).to eq(expected)
    end
  end
end
