# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Position, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }

  describe 'associations' do
    it { is_expected.to belong_to(:work_item) }
    it { is_expected.to belong_to(:namespace) }
  end

  it 'ensures to use work_item namespace' do
    work_item = create(:work_item, project: project)
    position = build(:work_item_position, work_item: work_item, namespace: nil)

    expect(position).to be_valid
    expect(position.namespace).to eq(work_item.namespace)
  end

  it 'syncs work_item_positions from issue' do
    work_item = create(:work_item, project: project, relative_position: nil)

    expect(work_item.work_item_position.relative_position).to be_nil

    work_item.update!(relative_position: 5)

    expect(work_item.reload.work_item_position.relative_position).to eq(5)
  end

  describe 'relative_positioning_namespace_id sync (positioning root)' do
    it 'populates the root ancestor for a project under a group' do
      group = create(:group)
      work_item = create(:work_item, project: create(:project, group: group), relative_position: 10)

      expect(work_item.work_item_position.relative_positioning_namespace_id).to eq(group.id)
    end

    it 'populates the project namespace itself for a personal project' do
      personal_project = create(:project)
      work_item = create(:work_item, project: personal_project, relative_position: 10)

      expect(work_item.work_item_position.relative_positioning_namespace_id)
        .to eq(personal_project.project_namespace.id)
    end

    it 'keeps it in sync on update' do
      work_item = create(:work_item, project: project)

      work_item.update!(relative_position: 5)

      expect(work_item.reload.work_item_position.relative_positioning_namespace_id)
        .to eq(work_item.namespace.work_item_positioning_root.id)
    end
  end
end
