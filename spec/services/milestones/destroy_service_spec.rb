require 'spec_helper'

describe Milestones::DestroyService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:milestone) { create(:milestone, title: 'Milestone v1.0', project: project) }
  let!(:issue) { create(:issue, project: project, milestone: milestone) }
  let!(:merge_request) { create(:merge_request, source_project: project, milestone: milestone) }

  before do
    project.add_master(user)
  end

  def service
    described_class.new(project, user, {})
  end

  describe '#execute' do
    it 'deletes milestone' do
      service.execute(milestone)

      expect { milestone.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'deletes milestone id from issuables' do
      service.execute(milestone)

      expect(issue.reload.milestone).to be_nil
      expect(merge_request.reload.milestone).to be_nil
    end

    context 'group milestones' do
      let(:group) { create(:group) }
      let(:group_milestone) { create(:milestone, group: group) }

      before do
        project.update(namespace: group)
        group.add_developer(user)
      end

      it { expect(service.execute(group_milestone)).to be_nil }

      it 'does not update milestone issuables' do
        expect(MergeRequests::UpdateService).not_to receive(:new)
        expect(Issues::UpdateService).not_to receive(:new)

        service.execute(group_milestone)
      end
    end
  end
end
