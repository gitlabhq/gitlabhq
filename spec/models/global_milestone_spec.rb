require 'spec_helper'

describe GlobalMilestone, models: true do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:group) { create(:group) }
  let(:project1) { create(:project, group: group) }
  let(:project2) { create(:project, path: 'gitlab-ci', group: group) }
  let(:project3) { create(:project, path: 'cookbook-gitlab', group: group) }
  let(:milestone1_project1) { create(:milestone, title: "Milestone v1.2", project: project1) }
  let(:milestone1_project2) { create(:milestone, title: "Milestone v1.2", project: project2) }
  let(:milestone1_project3) { create(:milestone, title: "Milestone v1.2", project: project3) }
  let(:milestone2_project1) { create(:milestone, title: "VD-123", project: project1) }
  let(:milestone2_project2) { create(:milestone, title: "VD-123", project: project2) }
  let(:milestone2_project3) { create(:milestone, title: "VD-123", project: project3) }

  describe :build_collection do
    before do
      milestones =
        [
          milestone1_project1,
          milestone1_project2,
          milestone1_project3,
          milestone2_project1,
          milestone2_project2,
          milestone2_project3
        ]

      @global_milestones = GlobalMilestone.build_collection(milestones)
    end

    it 'should have all project milestones' do
      expect(@global_milestones.count).to eq(2)
    end

    it 'should have all project milestones titles' do
      expect(@global_milestones.map(&:title)).to match_array(['Milestone v1.2', 'VD-123'])
    end

    it 'should have all project milestones' do
      expect(@global_milestones.map { |group_milestone| group_milestone.milestones.count }.sum).to eq(6)
    end
  end

  describe :initialize do
    before do
      milestones =
        [
          milestone1_project1,
          milestone1_project2,
          milestone1_project3,
        ]

      @global_milestone = GlobalMilestone.new(milestone1_project1.title, milestones)
    end

    it 'should have exactly one group milestone' do
      expect(@global_milestone.title).to eq('Milestone v1.2')
    end

    it 'should have all project milestones with the same title' do
      expect(@global_milestone.milestones.count).to eq(3)
    end
  end

  describe :safe_title do
    let(:milestone) { create(:milestone, title: "git / test", project: project1) }

    it 'should strip out slashes and spaces' do
      global_milestone = GlobalMilestone.new(milestone.title, [milestone])

      expect(global_milestone.safe_title).to eq('git-test')
    end
  end
end
