# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LoadedInGroupList, feature_category: :groups_and_projects do
  let_it_be(:parent) { create(:group) }
  let_it_be(:group) { create(:group, parent: parent) }
  let_it_be(:project) { create(:project, namespace: parent) }

  let_it_be(:params) { {} }

  before do
    parent.add_developer(create(:user))
  end

  subject(:found_group) { Group.with_selects_for_list(**params).find_by(id: parent.id) }

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

    context 'with archived parameter' do
      let_it_be(:non_archived_group) { group }
      let_it_be(:non_archived_project) { project }

      let_it_be(:archived_groups) { create_list(:group, 2, :archived, parent: parent) }
      let_it_be(:archived_projects) { create_list(:project, 2, :archived, group: parent) }

      context 'when true' do
        let_it_be(:params) { { archived: true } }

        it 'counts archived subgroups and projects' do
          expect(found_group.preloaded_project_count).to eq(2)
          expect(found_group.preloaded_subgroup_count).to eq(2)
        end
      end

      context 'when false' do
        let_it_be(:params) { { archived: false } }

        it 'count non-archived subgroups and projects' do
          expect(found_group.preloaded_project_count).to eq(1)
          expect(found_group.preloaded_subgroup_count).to eq(1)
        end
      end
    end

    context 'with active parameter' do
      let_it_be(:active_group) { group }
      let_it_be(:active_project) { project }

      let_it_be(:inactive_groups) { create_list(:group_with_deletion_schedule, 2, parent: parent) }
      let_it_be(:inactive_projects) { create_list(:project, 2, marked_for_deletion_at: Date.current, group: parent) }

      context 'when true' do
        let_it_be(:params) { { active: true } }

        it 'counts active subgroups and projects' do
          expect(found_group.preloaded_project_count).to eq(1)
          expect(found_group.preloaded_subgroup_count).to eq(1)
        end
      end

      context 'when false' do
        let_it_be(:params) { { active: false } }

        it 'counts inactive subgroups and projects' do
          expect(found_group.preloaded_project_count).to eq(2)
          expect(found_group.preloaded_subgroup_count).to eq(2)
        end
      end
    end
  end

  describe '#children_count' do
    it 'counts groups and projects' do
      expect(found_group.children_count).to eq(2)
    end
  end

  describe '#project_count' do
    let_it_be(:archived_project) { create(:project, :archived, namespace: parent) }

    it 'counts all child projects' do
      expect(found_group.project_count).to eq(2)
    end
  end

  describe 'has_subgroups' do
    it { expect(found_group.has_subgroups?).to be_truthy }
  end
end
