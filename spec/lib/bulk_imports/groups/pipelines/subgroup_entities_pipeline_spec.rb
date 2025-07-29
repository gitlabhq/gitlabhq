# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::SubgroupEntitiesPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, path: 'group') }
  let_it_be(:parent) { create(:group, name: 'Imported Group', path: 'imported-group') }
  let_it_be(:parent_entity) { create(:bulk_import_entity, destination_namespace: parent.full_path, group: parent) }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: parent_entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let(:extracted_data) do
    BulkImports::Pipeline::ExtractedData.new(data: {
      'path' => 'sub-group',
      'full_path' => 'parent/sub-group'
    })
  end

  subject { described_class.new(context) }

  describe '#run', :clean_gitlab_redis_shared_state do
    before do
      allow_next_instance_of(BulkImports::Groups::Extractors::SubgroupsExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(extracted_data)
      end

      allow(subject).to receive(:set_source_objects_counter)

      parent.add_owner(user)
    end

    it 'creates entities for the subgroups' do
      expect { subject.run }.to change(BulkImports::Entity, :count).by(1)

      subgroup_entity = BulkImports::Entity.last

      expect(subgroup_entity.source_full_path).to eq 'parent/sub-group'
      expect(subgroup_entity.destination_namespace).to eq 'imported-group'
      expect(subgroup_entity.destination_name).to eq 'sub-group'
      expect(subgroup_entity.parent_id).to eq parent_entity.id
    end

    it 'does not create duplicate entities on rerun' do
      expect { subject.run }.to change(BulkImports::Entity, :count).by(1)
      expect { subject.run }.not_to change(BulkImports::Entity, :count)
    end
  end

  describe '#load' do
    let(:parent_entity) { create(:bulk_import_entity, group: group, bulk_import: create(:bulk_import)) }

    it 'creates entities for the given data' do
      data = {
        source_type: :group_entity,
        source_full_path: 'parent/subgroup',
        destination_name: 'subgroup',
        organization_id: parent_entity.group.organization_id,
        destination_namespace: parent_entity.group.full_path,
        parent_id: parent_entity.id
      }
      expect { subject.load(context, data) }.to change(BulkImports::Entity, :count).by(1)
      subgroup_entity = BulkImports::Entity.last

      expect(subgroup_entity.source_full_path).to eq 'parent/subgroup'
      expect(subgroup_entity.destination_namespace).to eq 'group'
      expect(subgroup_entity.destination_name).to eq 'subgroup'
      expect(subgroup_entity.parent_id).to eq parent_entity.id
    end
  end

  describe 'pipeline parts' do
    it { expect(described_class).to include_module(BulkImports::Pipeline) }
    it { expect(described_class).to include_module(BulkImports::Pipeline::Runner) }

    it 'has extractors' do
      expect(described_class.get_extractor).to eq(klass: BulkImports::Groups::Extractors::SubgroupsExtractor, options: nil)
    end

    it 'has transformers' do
      expect(described_class.transformers).to contain_exactly(
        { klass: BulkImports::Common::Transformers::ProhibitedAttributesTransformer, options: nil },
        { klass: BulkImports::Groups::Transformers::SubgroupToEntityTransformer, options: nil }
      )
    end
  end
end
