# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Graphql::GetProjectQuery do
  let_it_be(:tracker) { create(:bulk_import_tracker) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject(:query) { described_class.new(context: context) }

  it 'has a valid query' do
    parsed_query = GraphQL::Query.new(
      GitlabSchema,
      query.to_s,
      variables: query.variables
    )
    result = GitlabSchema.static_validator.validate(parsed_query)

    expect(result[:errors]).to be_empty
  end

  it 'queries project based on source_full_path' do
    expected = { full_path: tracker.entity.source_full_path }

    expect(subject.variables).to eq(expected)
  end
end
