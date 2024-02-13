# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::AutoDevopsPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }
  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      :project_entity,
      project: project,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path',
      destination_slug: 'My-Destination-Project',
      destination_namespace: group.full_path
    )
  end

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let(:auto_devops) do
    {
      'created_at' => '2016-06-13T15:02:47.967Z',
      'updated_at' => '2016-06-14T15:02:47.967Z',
      'enabled' => true,
      'deploy_strategy' => 'continuous'
    }
  end

  subject(:pipeline) { described_class.new(context) }

  describe '#run' do
    it 'imports auto devops options into destination project' do
      group.add_owner(user)

      allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: [auto_devops]))
      end

      allow(pipeline).to receive(:set_source_objects_counter)

      pipeline.run

      expect(project.auto_devops.enabled).to be_truthy
      expect(project.auto_devops.deploy_strategy).to eq('continuous')
      expect(project.auto_devops.created_at).to eq('2016-06-13T15:02:47.967Z')
      expect(project.auto_devops.updated_at).to eq('2016-06-14T15:02:47.967Z')
    end
  end
end
