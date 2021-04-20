# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Milestones::DestroyService do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:milestone) { create(:milestone, title: 'Milestone v1.0', project: project) }

  before do
    project.add_maintainer(user)
  end

  def service
    described_class.new(project, user, {})
  end

  describe '#execute' do
    it 'deletes milestone' do
      service.execute(milestone)

      expect { milestone.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    context 'with an existing merge request' do
      let!(:issue) { create(:issue, project: project, milestone: milestone) }
      let!(:merge_request) { create(:merge_request, source_project: project, milestone: milestone) }

      it 'deletes milestone id from issuables' do
        service.execute(milestone)

        expect(issue.reload.milestone).to be_nil
        expect(merge_request.reload.milestone).to be_nil
      end
    end

    it 'logs destroy event' do
      service.execute(milestone)

      event = Event.where(project_id: milestone.project_id, target_type: 'Milestone')

      expect(event.count).to eq(1)
    end

    context 'group milestones' do
      let(:group) { create(:group) }
      let(:group_milestone) { create(:milestone, group: group) }

      before do
        project.update!(namespace: group)
        group.add_developer(user)
      end

      it { expect(service.execute(group_milestone)).to eq(group_milestone) }

      it 'deletes milestone id from issuables' do
        issue = create(:issue, project: project, milestone: group_milestone)
        merge_request = create(:merge_request, source_project: project, milestone: group_milestone)

        service.execute(group_milestone)

        expect(issue.reload.milestone).to be_nil
        expect(merge_request.reload.milestone).to be_nil
      end

      it 'does not log destroy event' do
        expect { service.execute(group_milestone) }.not_to change { Event.count }
      end
    end

    context 'when a release is tied to a milestone' do
      it 'destroys the milestone but not the associated release' do
        release = create(
          :release,
          tag: 'v1.0',
          project: project,
          milestones: [milestone]
        )

        expect { service.execute(milestone) }.not_to change { Release.count }
        expect(release.reload).to be_persisted
      end
    end
  end
end
