# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::ServiceDeskSettingPipeline, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:entity) { create(:bulk_import_entity, :project_entity, project: project) }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }
  let_it_be(:setting) { { 'issue_template_key' => 'test', 'project_key' => 'key' } }

  subject(:pipeline) { described_class.new(context) }

  describe '#run' do
    it 'imports project feature', :aggregate_failures do
      allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: [[setting, 0]]))
      end

      allow(pipeline).to receive(:set_source_objects_counter)

      pipeline.run

      setting.each_pair do |key, value|
        expect(entity.project.service_desk_setting.public_send(key)).to eq(value)
      end
    end
  end
end
