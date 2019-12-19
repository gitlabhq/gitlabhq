# frozen_string_literal: true

require 'spec_helper'

describe LoadedInGroupList do
  let(:parent) { create(:group) }

  subject(:found_group) { Group.with_selects_for_list.find_by(id: parent.id) }

  describe '.with_selects_for_list' do
    it 'includes the preloaded counts for groups' do
      create(:group, parent: parent)
      create(:project, namespace: parent)
      parent.add_developer(create(:user))

      found_group = Group.with_selects_for_list.find_by(id: parent.id)

      expect(found_group.preloaded_project_count).to eq(1)
      expect(found_group.preloaded_subgroup_count).to eq(1)
      expect(found_group.preloaded_member_count).to eq(1)
    end

    context 'with archived projects' do
      it 'counts including archived projects when `true` is passed' do
        create(:project, namespace: parent, archived: true)
        create(:project, namespace: parent)

        found_group = Group.with_selects_for_list(archived: 'true').find_by(id: parent.id)

        expect(found_group.preloaded_project_count).to eq(2)
      end

      it 'counts only archived projects when `only` is passed' do
        create_list(:project, 2, namespace: parent, archived: true)
        create(:project, namespace: parent)

        found_group = Group.with_selects_for_list(archived: 'only').find_by(id: parent.id)

        expect(found_group.preloaded_project_count).to eq(2)
      end
    end
  end

  describe '#children_count' do
    it 'counts groups and projects' do
      create(:group, parent: parent)
      create(:project, namespace: parent)

      expect(found_group.children_count).to eq(2)
    end
  end
end
