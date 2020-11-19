# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Loaders::EntityLoader do
  describe '#load' do
    it "creates entities for the given data" do
      group = create(:group, path: "imported-group")
      parent_entity = create(:bulk_import_entity, group: group, bulk_import: create(:bulk_import))
      context = instance_double(BulkImports::Pipeline::Context, entity: parent_entity)

      data = {
        source_type: :group_entity,
        source_full_path: "parent/subgroup",
        destination_name: "subgroup",
        destination_namespace: parent_entity.group.full_path,
        parent_id: parent_entity.id
      }

      expect { subject.load(context, data) }.to change(BulkImports::Entity, :count).by(1)

      subgroup_entity = BulkImports::Entity.last

      expect(subgroup_entity.source_full_path).to eq 'parent/subgroup'
      expect(subgroup_entity.destination_namespace).to eq 'imported-group'
      expect(subgroup_entity.destination_name).to eq 'subgroup'
      expect(subgroup_entity.parent_id).to eq parent_entity.id
    end
  end
end
