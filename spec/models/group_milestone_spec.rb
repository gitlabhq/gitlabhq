# frozen_string_literal: true

require 'spec_helper'

describe GroupMilestone do
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:project_milestone) do
    create(:milestone, title: "Milestone v1.2", project: project)
  end

  describe '.build' do
    it 'returns milestone with group assigned' do
      milestone = described_class.build(
        group,
        [project],
        project_milestone.title
      )

      expect(milestone.group).to eq group
    end
  end

  describe '.build_collection' do
    let(:group) { create(:group) }
    let(:project1) { create(:project, group: group) }
    let(:project2) { create(:project, path: 'gitlab-ci', group: group) }
    let(:project3) { create(:project, path: 'cookbook-gitlab', group: group) }

    let!(:projects) do
      [
          project1,
          project2,
          project3
      ]
    end

    it 'returns array of milestones, each with group assigned' do
      milestones = described_class.build_collection(group, [project], {})
      expect(milestones).to all(have_attributes(group: group))
    end

    context 'when adding new milestones' do
      it 'does not add more queries' do
        control_count = ActiveRecord::QueryRecorder.new do
          described_class.build_collection(group, projects, {})
        end.count

        create(:milestone, title: 'This title', project: project1)

        expect do
          described_class.build_collection(group, projects, {})
        end.not_to exceed_all_query_limit(control_count)
      end
    end
  end
end
