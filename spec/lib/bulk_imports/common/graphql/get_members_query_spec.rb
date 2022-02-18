# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Graphql::GetMembersQuery do
  let(:entity) { create(:bulk_import_entity, :group_entity) }
  let(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let(:context) { BulkImports::Pipeline::Context.new(tracker) }

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

  describe '#data_path' do
    it 'returns data path' do
      expected = %w[data portable members nodes]

      expect(query.data_path).to eq(expected)
    end
  end

  describe '#page_info_path' do
    it 'returns pagination information path' do
      expected = %w[data portable members page_info]

      expect(query.page_info_path).to eq(expected)
    end
  end

  describe '#to_s' do
    context 'when entity is group' do
      it 'queries group & group members' do
        expect(query.to_s).to include('group')
        expect(query.to_s).to include('groupMembers')
      end
    end

    context 'when entity is project' do
      let(:entity) { create(:bulk_import_entity, :project_entity) }

      it 'queries project & project members' do
        expect(query.to_s).to include('project')
        expect(query.to_s).to include('projectMembers')
      end
    end
  end
end
