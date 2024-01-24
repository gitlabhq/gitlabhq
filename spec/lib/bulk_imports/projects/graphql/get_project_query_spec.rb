# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Graphql::GetProjectQuery, feature_category: :importers do
  let_it_be(:tracker) { create(:bulk_import_tracker) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject(:query) { described_class.new(context: context) }

  it_behaves_like 'a valid Direct Transfer GraphQL query'

  it 'queries project based on source_full_path' do
    expected = { full_path: tracker.entity.source_full_path }

    expect(subject.variables).to eq(expected)
  end
end
