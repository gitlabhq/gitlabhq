# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LoadedInGroupList do
  let_it_be(:parent) { create(:group) }
  let_it_be(:group) { create(:group, parent: parent) }
  let_it_be(:project) { create(:project, namespace: parent) }

  let(:archived_parameter) { nil }

  before do
    parent.add_developer(create(:user))
  end

  subject(:found_group) { Group.with_selects_for_list(archived: archived_parameter).find_by(id: parent.id) }

  describe '.with_selects_for_list' do
    it 'includes the preloaded counts for groups' do
      expect(found_group.preloaded_project_count).to eq(1)
      expect(found_group.preloaded_subgroup_count).to eq(1)
      expect(found_group.preloaded_member_count).to eq(1)
    end

    context 'with project namespaces' do
      let_it_be(:group1) { create(:group, parent: parent) }
      let_it_be(:group2) { create(:group, parent: parent) }
      let_it_be(:project_namespace) { project.project_namespace }

      it 'does not include project_namespaces in the count of subgroups' do
        expect(found_group.preloaded_subgroup_count).to eq(3)
        expect(parent.subgroup_count).to eq(3)
      end
    end

    context 'with archived projects' do
      let_it_be(:archived_project) { create(:project, namespace: parent, archived: true) }

      let(:archived_parameter) { true }

      it 'counts including archived projects when `true` is passed' do
        expect(found_group.preloaded_project_count).to eq(2)
      end

      context 'when not counting archived projects' do
        let(:archived_parameter) { false }

        it 'counts projects without archived ones' do
          expect(found_group.preloaded_project_count).to eq(1)
        end
      end

      context 'with archived only' do
        let_it_be(:archived_project2) { create(:project, namespace: parent, archived: true) }

        let(:archived_parameter) { 'only' }

        it 'counts only archived projects when `only` is passed' do
          expect(found_group.preloaded_project_count).to eq(2)
        end
      end
    end
  end

  describe '#children_count' do
    it 'counts groups and projects' do
      expect(found_group.children_count).to eq(2)
    end
  end

  describe 'has_subgroups' do
    it { expect(found_group.has_subgroups?).to be_truthy }
  end
end
