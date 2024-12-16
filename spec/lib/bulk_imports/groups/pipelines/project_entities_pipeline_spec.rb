# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::ProjectEntitiesPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:destination_group) { create(:group) }

  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      group: destination_group,
      destination_namespace: destination_group.full_path
    )
  end

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject { described_class.new(context) }

  describe '#run', :clean_gitlab_redis_shared_state do
    let(:extracted_data) do
      BulkImports::Pipeline::ExtractedData.new(data: {
        'id' => 'gid://gitlab/Project/1234567',
        'name' => 'My Project',
        'path' => 'my-project',
        'full_path' => 'group/my-project'
      })
    end

    before do
      allow_next_instance_of(BulkImports::Common::Extractors::GraphqlExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(extracted_data)
      end

      allow(subject).to receive(:set_source_objects_counter)

      destination_group.add_owner(user)
    end

    it 'creates project entity' do
      expect { subject.run }.to change(BulkImports::Entity, :count).by(1)

      project_entity = BulkImports::Entity.last

      expect(project_entity.source_type).to eq('project_entity')
      expect(project_entity.source_full_path).to eq('group/my-project')
      expect(project_entity.destination_slug).to eq('my-project')
      expect(project_entity.destination_name).to eq('my-project')
      expect(project_entity.destination_namespace).to eq(destination_group.full_path)
      expect(project_entity.organization).to eq(destination_group.organization)
      expect(project_entity.source_xid).to eq(1234567)
    end

    it 'does not create duplicate entities on rerun' do
      expect { subject.run }.to change(BulkImports::Entity, :count).by(1)
      expect { subject.run }.not_to change(BulkImports::Entity, :count)
    end
  end

  describe 'pipeline parts' do
    it { expect(described_class).to include_module(BulkImports::Pipeline) }
    it { expect(described_class).to include_module(BulkImports::Pipeline::Runner) }

    it 'has extractors' do
      expect(described_class.get_extractor).to eq(
        klass: BulkImports::Common::Extractors::GraphqlExtractor,
        options: {
          query: BulkImports::Groups::Graphql::GetProjectsQuery
        }
      )
    end

    it 'has transformers' do
      expect(described_class.transformers).to contain_exactly(
        { klass: BulkImports::Common::Transformers::ProhibitedAttributesTransformer, options: nil }
      )
    end
  end
end
