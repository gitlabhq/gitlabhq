require 'spec_helper'

describe Milestones::GroupService do
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

  describe 'execute' do
    context 'with valid projects' do
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
        @group_milestones = Milestones::GroupService.new(milestones).execute
      end

      it 'should have all project milestones' do
        expect(@group_milestones.count).to eq(2)
      end

      it 'should have all project milestones titles' do
        expect(@group_milestones.map { |group_milestone| group_milestone.title }).to match_array(['Milestone v1.2', 'VD-123'])
      end

      it 'should have all project milestones' do
        expect(@group_milestones.map { |group_milestone| group_milestone.milestones.count }.sum).to eq(6)
      end
    end
  end

  describe 'milestone' do
    context 'with valid title' do
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
        @group_milestones = Milestones::GroupService.new(milestones).milestone('Milestone v1.2')
      end

      it 'should have exactly one group milestone' do
        expect(@group_milestones.title).to eq('Milestone v1.2')
      end

      it 'should have all project milestones with the same title' do
        expect(@group_milestones.milestones.count).to eq(3)
      end
    end
  end
end
