require 'spec_helper'

describe Milestones::PromoteService do
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }
  let(:user) { create(:user) }
  let(:milestone_title) { 'project milestone' }
  let(:milestone) { create(:milestone, project: project, title: milestone_title) }
  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    before do
      group.add_master(user)
    end

    context 'validations' do
      it 'raises error if milestone does not belong to a project' do
        allow(milestone).to receive(:project_milestone?).and_return(false)

        expect { service.execute(milestone) }.to raise_error(described_class::PromoteMilestoneError)
      end

      it 'raises error if project does not belong to a group' do
        project.update(namespace: user.namespace)

        expect { service.execute(milestone) }.to raise_error(described_class::PromoteMilestoneError)
      end
    end

    context 'without duplicated milestone titles across projects' do
      it 'promotes project milestone to group milestone' do
        promoted_milestone = service.execute(milestone)

        expect(promoted_milestone).to be_group_milestone
      end

      it 'sets issuables with new promoted milestone' do
        issue = create(:issue, milestone: milestone, project: project)
        merge_request = create(:merge_request, milestone: milestone, source_project: project)

        promoted_milestone = service.execute(milestone)

        expect(promoted_milestone).to be_group_milestone
        expect(issue.reload.milestone).to eq(promoted_milestone)
        expect(merge_request.reload.milestone).to eq(promoted_milestone)
      end
    end

    context 'with duplicated milestone titles across projects' do
      let(:project_2) { create(:project, namespace: group) }
      let!(:milestone_2) { create(:milestone, project: project_2, title: milestone_title) }

      it 'deletes project milestones with the same title' do
        promoted_milestone = service.execute(milestone)

        expect(promoted_milestone).to be_group_milestone
        expect(promoted_milestone).to be_valid
        expect(Milestone.exists?(milestone.id)).to be_falsy
        expect(Milestone.exists?(milestone_2.id)).to be_falsy
      end

      it 'sets all issuables with new promoted milestone' do
        issue = create(:issue, milestone: milestone, project: project)
        issue_2 = create(:issue, milestone: milestone_2, project: project_2)
        merge_request = create(:merge_request, milestone: milestone, source_project: project)
        merge_request_2 = create(:merge_request, milestone: milestone_2, source_project: project_2)

        promoted_milestone = service.execute(milestone)

        expect(issue.reload.milestone).to eq(promoted_milestone)
        expect(issue_2.reload.milestone).to eq(promoted_milestone)
        expect(merge_request.reload.milestone).to eq(promoted_milestone)
        expect(merge_request_2.reload.milestone).to eq(promoted_milestone)
      end
    end
  end
end
