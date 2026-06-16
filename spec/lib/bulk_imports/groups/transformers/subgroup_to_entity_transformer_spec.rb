# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Transformers::SubgroupToEntityTransformer, feature_category: :importers do
  describe "#transform" do
    subject(:transformer) { described_class.new }

    it "transforms subgroups data in entity params" do
      parent = build_stubbed(:group)
      parent_entity = instance_double(BulkImports::Entity, group: parent, id: 1,
        migrate_projects: false, migrate_memberships: false)
      context = instance_double(BulkImports::Pipeline::Context, entity: parent_entity)
      subgroup_data = {
        "path" => "sub-group",
        "full_path" => "parent/sub-group"
      }

      expect(transformer.transform(context, subgroup_data)).to eq(
        source_type: :group_entity,
        source_full_path: "parent/sub-group",
        destination_name: "sub-group",
        destination_namespace: parent.full_path,
        organization_id: parent.organization_id,
        parent_id: 1,
        migrate_projects: false,
        migrate_memberships: false
      )
    end
  end
end
