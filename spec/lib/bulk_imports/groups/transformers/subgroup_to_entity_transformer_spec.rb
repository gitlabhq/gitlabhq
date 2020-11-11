# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Transformers::SubgroupToEntityTransformer do
  describe "#transform" do
    it "transforms subgroups data in entity params" do
      parent = create(:group)
      parent_entity = instance_double(BulkImports::Entity, group: parent, id: 1)
      context = instance_double(BulkImports::Pipeline::Context, entity: parent_entity)
      subgroup_data = {
        "name" => "subgroup",
        "full_path" => "parent/subgroup"
      }

      expect(subject.transform(context, subgroup_data)).to eq(
        source_type: :group_entity,
        source_full_path: "parent/subgroup",
        destination_name: "subgroup",
        destination_namespace: parent.full_path,
        parent_id: 1
      )
    end
  end
end
