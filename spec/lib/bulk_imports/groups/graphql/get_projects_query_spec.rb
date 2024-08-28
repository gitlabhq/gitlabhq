# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Graphql::GetProjectsQuery, feature_category: :importers do
  let_it_be(:entity) { create(:bulk_import_entity, :group_entity) }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject(:query) { described_class.new(context: context) }

  context 'when the test is flaky', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/454244' do
    it_behaves_like 'a valid Direct Transfer GraphQL query'
  end

  context 'with invalid variables' do
    it 'raises an error' do
      expect { GraphQL::Query.new(GitlabSchema, subject.to_s, variables: 'invalid') }.to raise_error(ArgumentError)
    end
  end

  describe '#data_path' do
    it 'returns data path' do
      expected = %w[data group projects nodes]

      expect(subject.data_path).to eq(expected)
    end
  end

  describe '#page_info_path' do
    it 'returns pagination information path' do
      expected = %w[data group projects page_info]

      expect(subject.page_info_path).to eq(expected)
    end
  end

  describe '#to_s' do
    context 'when the version is >= 16.1' do
      before do
        entity.bulk_import.update!(source_version: "16.1.0")
      end

      it 'includes notAimedForDeletion: true' do
        expect(subject.to_s).to include('notAimedForDeletion: true')
      end
    end

    context 'when the version is < 16.1' do
      before do
        entity.bulk_import.update!(source_version: "16.0.0")
      end

      it 'does not include notAimedForDeletion' do
        expect(subject.to_s).not_to include('notAimedForDeletion')
      end
    end
  end
end
