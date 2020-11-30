# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::SubgroupEntitiesPipeline do
  describe '#run' do
    let_it_be(:user) { create(:user) }
    let(:parent) { create(:group, name: 'imported-group', path: 'imported-group') }
    let!(:parent_entity) do
      create(
        :bulk_import_entity,
        destination_namespace: parent.full_path,
        group: parent
      )
    end

    let(:context) do
      instance_double(
        BulkImports::Pipeline::Context,
        current_user: user,
        entity: parent_entity
      )
    end

    let(:subgroup_data) do
      [
        {
          "name" => "subgroup",
          "full_path" => "parent/subgroup"
        }
      ]
    end

    subject { described_class.new }

    before do
      allow_next_instance_of(BulkImports::Groups::Extractors::SubgroupsExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(subgroup_data)
      end

      parent.add_owner(user)
    end

    it 'creates entities for the subgroups' do
      expect { subject.run(context) }.to change(BulkImports::Entity, :count).by(1)

      subgroup_entity = BulkImports::Entity.last

      expect(subgroup_entity.source_full_path).to eq 'parent/subgroup'
      expect(subgroup_entity.destination_namespace).to eq 'imported-group'
      expect(subgroup_entity.destination_name).to eq 'subgroup'
      expect(subgroup_entity.parent_id).to eq parent_entity.id
    end
  end

  describe 'pipeline parts' do
    it { expect(described_class).to include_module(BulkImports::Pipeline) }
    it { expect(described_class).to include_module(BulkImports::Pipeline::Runner) }

    it 'has extractors' do
      expect(described_class.extractors).to contain_exactly(
        klass: BulkImports::Groups::Extractors::SubgroupsExtractor,
        options: nil
      )
    end

    it 'has transformers' do
      expect(described_class.transformers).to contain_exactly(
        klass: BulkImports::Groups::Transformers::SubgroupToEntityTransformer,
        options: nil
      )
    end

    it 'has loaders' do
      expect(described_class.loaders).to contain_exactly(
        klass: BulkImports::Common::Loaders::EntityLoader,
        options: nil
      )
    end
  end
end
