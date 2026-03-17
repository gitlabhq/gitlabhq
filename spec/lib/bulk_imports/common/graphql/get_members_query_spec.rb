# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Graphql::GetMembersQuery, feature_category: :importers do
  let(:entity) { create(:bulk_import_entity, :group_entity) }
  let(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject(:query) { described_class.new(context: context) }

  it_behaves_like 'a valid Direct Transfer GraphQL query'

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
        expect(query.to_s).to include('DIRECT INHERITED')
      end

      context "when source version is past 14.7.0" do
        before do
          entity.bulk_import.update!(source_version: "14.8.0")
        end

        it 'includes SHARED_FROM_GROUPS' do
          expect(query.to_s).to include('DIRECT INHERITED SHARED_FROM_GROUPS')
        end
      end
    end

    context 'when entity is project' do
      let(:entity) { create(:bulk_import_entity, :project_entity) }

      it 'queries project & project members' do
        expect(query.to_s).to include('project')
        expect(query.to_s).to include('projectMembers')
        expect(query.to_s).to include('DIRECT INHERITED INVITED_GROUPS')
      end

      context "when source version is at least 16.0.0" do
        before do
          entity.bulk_import.update!(source_version: "16.0.0")
        end

        it 'includes SHARED_INTO_ANCESTORS' do
          expect(query.to_s).to include('DIRECT INHERITED INVITED_GROUPS SHARED_INTO_ANCESTORS')
        end
      end
    end
  end
end
