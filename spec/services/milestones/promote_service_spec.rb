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

      it 'does not promote milestone and update issuables if promoted milestone is not valid' do
        issue = create(:issue, milestone: milestone, project: project)
        merge_request = create(:merge_request, milestone: milestone, source_project: project)
        allow_any_instance_of(Milestone).to receive(:valid?).and_return(false)

        expect { service.execute(milestone) }.to raise_error(described_class::PromoteMilestoneError)

        expect(milestone.reload).to be_persisted
        expect(issue.reload.milestone).to eq(milestone)
        expect(merge_request.reload.milestone).to eq(milestone)
      end
    end

    context 'without duplicated milestone titles across projects' do
      it 'promotes project milestone to group milestone' do
        promoted_milestone = service.execute(milestone)

        expect(promoted_milestone).to be_group_milestone
      end

      it 'does not update issuables without milestone with the new promoted milestone' do
        issue_without_milestone = create(:issue, project: project, milestone: nil)
        merge_request_without_milestone = create(:merge_request, milestone: nil, source_project: project)

        service.execute(milestone)

        expect(issue_without_milestone.reload.milestone).to be_nil
        expect(merge_request_without_milestone.reload.milestone).to be_nil
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

      it 'does not update issuables without milestone with the new promoted milestone' do
        issue_without_milestone_1 = create(:issue, project: project, milestone: nil)
        issue_without_milestone_2 = create(:issue, project: project_2, milestone: nil)
        merge_request_without_milestone_1 = create(:merge_request, milestone: nil, source_project: project)
        merge_request_without_milestone_2 = create(:merge_request, milestone: nil, source_project: project_2)

        service.execute(milestone)

        expect(issue_without_milestone_1.reload.milestone).to be_nil
        expect(issue_without_milestone_2.reload.milestone).to be_nil
        expect(merge_request_without_milestone_1.reload.milestone).to be_nil
        expect(merge_request_without_milestone_2.reload.milestone).to be_nil
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
