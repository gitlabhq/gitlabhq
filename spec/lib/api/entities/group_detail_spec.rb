# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::GroupDetail do
  describe '#as_json' do
    it 'includes prevent_sharing_groups_outside_hierarchy for a root group' do
      group = create(:group)

      expect(described_class.new(group).as_json).to include(prevent_sharing_groups_outside_hierarchy: false)
    end

    it 'excludes prevent_sharing_groups_outside_hierarchy for a subgroup' do
      subgroup = build(:group, :nested)

      expect(described_class.new(subgroup).as_json.keys).not_to include(:prevent_sharing_groups_outside_hierarchy)
    end
  end
end
