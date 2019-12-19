# frozen_string_literal: true

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

    let!(:projects) do
      [
        project1,
        project2,
        project3
      ]
    end

    let!(:global_milestones) { described_class.build_collection(projects, {}) }

    context 'when building a collection of milestones' do
      it 'has all project milestones' do
        expect(global_milestones.count).to eq(6)
      end

      it 'has all project milestones titles' do
        expect(global_milestones.map(&:title)).to match_array(['Milestone v1.2', 'Milestone v1.2', 'Milestone v1.2', 'VD-123', 'VD-123', 'VD-123'])
      end

      it 'has all project milestones' do
        expect(global_milestones.size).to eq(6)
      end

      it 'sorts collection by due date' do
        expect(global_milestones.map(&:due_date)).to eq [milestone1_due_date, milestone1_due_date, milestone1_due_date, nil, nil, nil]
      end

      it 'filters milestones by search_title when params[:search_title] is present' do
        global_milestones = described_class.build_collection(projects, { search_title: 'v1.2' })

        expect(global_milestones.map(&:title)).to match_array(['Milestone v1.2', 'Milestone v1.2', 'Milestone v1.2'])
      end
    end

    context 'when adding new milestones' do
      it 'does not add more queries' do
        control_count = ActiveRecord::QueryRecorder.new do
          described_class.build_collection(projects, {})
        end.count

        create_list(:milestone, 3, project: project3)

        expect do
          described_class.build_collection(projects, {})
        end.not_to exceed_all_query_limit(control_count)
      end
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
        create(:closed_milestone, title: 'Closed Group Milestone 4', group: group)
      end

      it 'returns the quantity of global milestones and group milestones in each possible state' do
        expected_count = { opened: 2, closed: 5, all: 7 }

        count = described_class.states_count(Project.all, group)

        expect(count).to eq(expected_count)
      end

      it 'returns the quantity of global milestones in each possible state' do
        expected_count = { opened: 2, closed: 4, all: 6 }

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

    subject(:global_milestone) { described_class.new(milestone1_project1) }

    it 'has exactly one group milestone' do
      expect(global_milestone.title).to eq('Milestone v1.2')
    end

    it 'has all project milestones with the same title' do
      expect(global_milestone.milestone).to eq(milestone1_project1)
    end
  end

  describe '#safe_title' do
    let(:milestone) { create(:milestone, title: "git / test", project: project1) }

    it 'strips out slashes and spaces' do
      global_milestone = described_class.new(milestone)

      expect(global_milestone.safe_title).to eq('git-test')
    end
  end

  describe '#state' do
    context 'when at least one milestone is active' do
      it 'returns active' do
        title = 'Active Group Milestone'

        global_milestone = described_class.new(create(:active_milestone, title: title))

        expect(global_milestone.state).to eq('active')
      end
    end

    context 'when all milestones are closed' do
      it 'returns closed' do
        title = 'Closed Group Milestone'

        global_milestone = described_class.new(create(:closed_milestone, title: title))

        expect(global_milestone.state).to eq('closed')
      end
    end
  end
end
