# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::ProtectedBranchesPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }
  let_it_be(:entity) { create(:bulk_import_entity, :project_entity, project: project, bulk_import: bulk_import) }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }
  let_it_be(:protected_branch) do
    {
      'name' => 'main',
      'created_at' => '2016-06-14T15:02:47.967Z',
      'updated_at' => '2016-06-14T15:02:47.967Z',
      'merge_access_levels' => [
        {
          'access_level' => 40,
          'created_at' => '2016-06-15T15:02:47.967Z',
          'updated_at' => '2016-06-15T15:02:47.967Z'
        }
      ],
      'push_access_levels' => [
        {
          'access_level' => 30,
          'created_at' => '2016-06-16T15:02:47.967Z',
          'updated_at' => '2016-06-16T15:02:47.967Z'
        }
      ]
    }
  end

  subject(:pipeline) { described_class.new(context) }

  describe '#run' do
    it 'imports protected branch information' do
      allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: [protected_branch, 0]))
      end

      allow(pipeline).to receive(:set_source_objects_counter)

      pipeline.run

      imported_protected_branch = project.protected_branches.last
      merge_access_level = imported_protected_branch.merge_access_levels.first
      push_access_level = imported_protected_branch.push_access_levels.first

      aggregate_failures do
        expect(imported_protected_branch.name).to eq(protected_branch['name'])
        expect(imported_protected_branch.updated_at).to eq(protected_branch['updated_at'])
        expect(imported_protected_branch.created_at).to eq(protected_branch['created_at'])
        expect(merge_access_level.access_level).to eq(protected_branch['merge_access_levels'].first['access_level'])
        expect(merge_access_level.created_at).to eq(protected_branch['merge_access_levels'].first['created_at'])
        expect(merge_access_level.updated_at).to eq(protected_branch['merge_access_levels'].first['updated_at'])
        expect(push_access_level.access_level).to eq(protected_branch['push_access_levels'].first['access_level'])
        expect(push_access_level.created_at).to eq(protected_branch['push_access_levels'].first['created_at'])
        expect(push_access_level.updated_at).to eq(protected_branch['push_access_levels'].first['updated_at'])
      end
    end
  end
end
