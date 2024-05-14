# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::ProjectFeaturePipeline, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:entity) { create(:bulk_import_entity, :project_entity, project: project) }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }
  let_it_be(:project_feature) do
    {
      "builds_access_level": 10,
      "wiki_access_level": 10,
      "issues_access_level": 10,
      "merge_requests_access_level": 10,
      "snippets_access_level": 10,
      "repository_access_level": 10,
      "pages_access_level": 10,
      "forking_access_level": 10,
      "metrics_dashboard_access_level": 10,
      "operations_access_level": 10,
      "analytics_access_level": 10,
      "security_and_compliance_access_level": 10,
      "container_registry_access_level": 10,
      "updated_at": "2016-09-23T11:58:28.000Z",
      "created_at": "2014-12-26T09:26:45.000Z"
    }
  end

  subject(:pipeline) { described_class.new(context) }

  describe '#run' do
    it 'imports project feature', :aggregate_failures do
      allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: [[project_feature, 0]]))
      end

      allow(pipeline).to receive(:set_source_objects_counter)

      pipeline.run

      project_feature.each_pair do |key, value|
        expect(entity.project.project_feature.public_send(key)).to eq(value)
      end
    end
  end
end
