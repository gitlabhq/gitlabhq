require 'spec_helper'

describe LoadedInGroupList do
  let(:parent) { create(:group) }
  subject(:found_group) { Group.with_selects_for_list.find_by(id: parent.id) }

  before do
    create(:group, parent: parent)
    create(:project, namespace: parent)
    parent.add_developer(create(:user))
  end

  describe '.with_selects_for_list' do
    it 'includes the preloaded counts for groups' do
      found_group = Group.with_selects_for_list.find_by(id: parent.id)

      expect(found_group.preloaded_project_count).to eq(1)
      expect(found_group.preloaded_subgroup_count).to eq(1)
      expect(found_group.preloaded_member_count).to eq(1)
    end
  end

  describe '#children_count' do
    it 'counts groups and projects' do
      expect(found_group.children_count).to eq(2)
    end
  end
end
