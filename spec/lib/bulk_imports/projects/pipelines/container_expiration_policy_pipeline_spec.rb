# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::ContainerExpirationPolicyPipeline, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:entity) { create(:bulk_import_entity, :project_entity, project: project) }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity, pipeline_name: described_class) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let_it_be(:policy) do
    {
      'created_at' => '2019-12-13 13:45:04 UTC',
      'updated_at' => '2019-12-14 13:45:04 UTC',
      'next_run_at' => '2019-12-15 13:45:04 UTC',
      'name_regex' => 'test',
      'name_regex_keep' => 'regex_keep',
      'cadence' => '3month',
      'older_than' => '1month',
      'keep_n' => 100,
      'enabled' => true
    }
  end

  subject(:pipeline) { described_class.new(context) }

  describe '#run' do
    it 'imports project feature', :aggregate_failures do
      allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: [[policy, 0]]))
      end

      allow(pipeline).to receive(:set_source_objects_counter)

      pipeline.run

      policy.each_pair do |key, value|
        expect(entity.project.container_expiration_policy.public_send(key)).to eq(value)
      end
    end
  end
end
