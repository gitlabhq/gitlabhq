require 'spec_helper'

describe GlobalMilestone do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:group) { create(:group) }
  let(:project1) { create(:project, group: group) }
  let(:project2) { create(:project, path: 'gitlab-ci', group: group) }
  let(:project3) { create(:project, path: 'cookbook-gitlab', group: group) }

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

      @global_milestones = described_class.build_collection(projects, {})
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

  describe '.states_count' do
    context 'when the projects have milestones' do
      before do
        create(:closed_milestone, title: 'Active Group Milestone', project: project3)
        create(:active_milestone, title: 'Active Group Milestone', project: project1)
        create(:active_milestone, title: 'Active Group Milestone', project: project2)
        create(:closed_milestone, title: 'Closed Group Milestone', project: project1)
        create(:closed_milestone, title: 'Closed Group Milestone', project: project2)
        create(:closed_milestone, title: 'Closed Group Milestone', project: project3)
      end

      it 'returns the quantity of global milestones in each possible state' do
        expected_count = { opened: 1, closed: 2, all: 2 }

        count = described_class.states_count(Project.all)

        expect(count).to eq(expected_count)
      end
    end

    context 'when the projects do not have milestones' do
      before do
        project1
      end

      it 'returns 0 as the quantity of global milestones in each state' do
        expected_count = { opened: 0, closed: 0, all: 0 }

        count = described_class.states_count(Project.all)

        expect(count).to eq(expected_count)
      end
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
          milestone1_project3
        ]
      milestones_relation = Milestone.where(id: milestones.map(&:id))

      @global_milestone = described_class.new(milestone1_project1.title, milestones_relation)
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
      global_milestone = described_class.new(milestone.title, Milestone.where(id: milestone.id))

      expect(global_milestone.safe_title).to eq('git-test')
    end
  end

  describe '#state' do
    context 'when at least one milestone is active' do
      it 'returns active' do
        title = 'Active Group Milestone'
        milestones = [
          create(:active_milestone, title: title),
          create(:closed_milestone, title: title)
        ]
        global_milestone = described_class.new(title, milestones)

        expect(global_milestone.state).to eq('active')
      end
    end

    context 'when all milestones are closed' do
      it 'returns closed' do
        title = 'Closed Group Milestone'
        milestones = [
          create(:closed_milestone, title: title),
          create(:closed_milestone, title: title)
        ]
        global_milestone = described_class.new(title, milestones)

        expect(global_milestone.state).to eq('closed')
      end
    end
  end
end
