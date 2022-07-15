# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Issuable::Clone::AttributesRewriter do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project1) { create(:project, :public, group: group) }
  let_it_be(:project2) { create(:project, :public, group: group) }
  let_it_be(:original_issue) { create(:issue, project: project1) }

  let(:new_attributes) { described_class.new(user, original_issue, project2).execute }

  context 'with missing target parent' do
    it 'raises an ArgumentError' do
      expect { described_class.new(user, original_issue, nil) }.to raise_error ArgumentError
    end
  end

  context 'setting labels' do
    it 'sets labels present in the new project and group labels' do
      project1_label_1 = create(:label, title: 'label1', project: project1)
      project1_label_2 = create(:label, title: 'label2', project: project1)
      project2_label_1 = create(:label, title: 'label1', project: project2)
      group_label = create(:group_label, title: 'group_label', group: group)
      create(:label, title: 'label3', project: project2)

      original_issue.update!(labels: [project1_label_1, project1_label_2, group_label])

      expect(new_attributes[:label_ids]).to match_array([project2_label_1.id, group_label.id])
    end

    it 'does not set any labels when not used on the original issue' do
      expect(new_attributes[:label_ids]).to be_empty
    end
  end

  context 'setting milestones' do
    it 'sets milestone to nil when old issue milestone is not in the new project' do
      milestone = create(:milestone, title: 'milestone', project: project1)

      original_issue.update!(milestone: milestone)

      expect(new_attributes[:milestone_id]).to be_nil
    end

    it 'copies the milestone when old issue milestone title is in the new project' do
      milestone_project1 = create(:milestone, title: 'milestone', project: project1)
      milestone_project2 = create(:milestone, title: 'milestone', project: project2)

      original_issue.update!(milestone: milestone_project1)

      expect(new_attributes[:milestone_id]).to eq(milestone_project2.id)
    end

    it 'copies the milestone when old issue milestone is a group milestone' do
      milestone = create(:milestone, title: 'milestone', group: group)

      original_issue.update!(milestone: milestone)

      expect(new_attributes[:milestone_id]).to eq(milestone.id)
    end

    context 'when include_milestone is false' do
      let(:new_attributes) { described_class.new(user, original_issue, project2).execute(include_milestone: false) }

      it 'does not return any milestone' do
        milestone = create(:milestone, title: 'milestone', group: group)

        original_issue.update!(milestone: milestone)

        expect(new_attributes[:milestone_id]).to be_nil
      end
    end
  end

  context 'when target parent is a group' do
    let(:new_attributes) { described_class.new(user, original_issue, group).execute }

    context 'setting labels' do
      let(:project_label1) { create(:label, title: 'label1', project: project1) }
      let!(:project_label2) { create(:label, title: 'label2', project: project1) }
      let(:group_label1) { create(:group_label, title: 'group_label', group: group) }
      let!(:group_label2) { create(:group_label, title: 'label2', group: group) }

      it 'keeps group labels and merges project labels where possible' do
        original_issue.update!(labels: [project_label1, project_label2, group_label1])

        expect(new_attributes[:label_ids]).to match_array([group_label1.id, group_label2.id])
      end
    end
  end
end
