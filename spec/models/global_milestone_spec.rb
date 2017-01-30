require 'spec_helper'

describe GlobalMilestone, models: true do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:group) { create(:group) }
  let(:project1) { create(:empty_project, group: group) }
  let(:project2) { create(:empty_project, path: 'gitlab-ci', group: group) }
  let(:project3) { create(:empty_project, path: 'cookbook-gitlab', group: group) }

  describe '.build_collection' do
    let(:milestone1_due_date) { 2.weeks.from_now.to_date }

    let!(:milestone1_project1) do
      create(
        :milestone,
        title: "Milestone v1.2",
        project: project1,
        due_date: milestone1_due_date
      )
    end

    let!(:milestone1_project2) do
      create(
        :milestone,
        title: "Milestone v1.2",
        project: project2,
        due_date: milestone1_due_date
      )
    end

    let!(:milestone1_project3) do
      create(
        :milestone,
        title: "Milestone v1.2",
        project: project3,
        due_date: milestone1_due_date
      )
    end

    let!(:milestone2_project1) do
      create(
        :milestone,
        title: "VD-123",
        project: project1,
        due_date: nil
      )
    end

    let!(:milestone2_project2) do
      create(
        :milestone,
        title: "VD-123",
        project: project2,
        due_date: nil
      )
    end

    let!(:milestone2_project3) do
      create(
        :milestone,
        title: "VD-123",
        project: project3,
        due_date: nil
      )
    end

    before do
      projects = [
        project1,
        project2,
        project3
      ]

      @global_milestones = GlobalMilestone.build_collection(projects, {})
    end

    it 'has all project milestones' do
      expect(@global_milestones.count).to eq(2)
    end

    it 'has all project milestones titles' do
      expect(@global_milestones.map(&:title)).to match_array(['Milestone v1.2', 'VD-123'])
    end

    it 'has all project milestones' do
      expect(@global_milestones.map { |group_milestone| group_milestone.milestones.count }.sum).to eq(6)
    end

    it 'sorts collection by due date' do
      expect(@global_milestones.map(&:due_date)).to eq [nil, milestone1_due_date]
    end
  end

  describe '#initialize' do
    let(:milestone1_project1) { create(:milestone, title: "Milestone v1.2", project: project1) }
    let(:milestone1_project2) { create(:milestone, title: "Milestone v1.2", project: project2) }
    let(:milestone1_project3) { create(:milestone, title: "Milestone v1.2", project: project3) }

    before do
      milestones =
        [
          milestone1_project1,
          milestone1_project2,
          milestone1_project3,
        ]
      milestones_relation = Milestone.where(id: milestones.map(&:id))

      @global_milestone = GlobalMilestone.new(milestone1_project1.title, milestones_relation)
    end

    it 'has exactly one group milestone' do
      expect(@global_milestone.title).to eq('Milestone v1.2')
    end

    it 'has all project milestones with the same title' do
      expect(@global_milestone.milestones.count).to eq(3)
    end
  end

  describe '#safe_title' do
    let(:milestone) { create(:milestone, title: "git / test", project: project1) }

    it 'strips out slashes and spaces' do
      global_milestone = GlobalMilestone.new(milestone.title, Milestone.where(id: milestone.id))

      expect(global_milestone.safe_title).to eq('git-test')
    end
  end
end
