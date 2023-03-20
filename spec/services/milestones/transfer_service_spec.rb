# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Milestones::TransferService, feature_category: :team_planning do
  describe '#execute' do
    subject(:service) { described_class.new(user, old_group, project) }

    context 'when old_group is present' do
      let(:user) { create(:admin) }
      let(:new_group) { create(:group) }
      let(:old_group) { create(:group) }
      let(:project) { create(:project, namespace: old_group) }
      let(:group_milestone) { create(:milestone, :closed, group: old_group) }
      let(:group_milestone2) { create(:milestone, group: old_group) }
      let(:project_milestone) { create(:milestone, project: project) }
      let!(:issue_with_group_milestone) { create(:issue, project: project, milestone: group_milestone) }
      let!(:issue_with_project_milestone) { create(:issue, project: project, milestone: project_milestone) }
      let!(:mr_with_group_milestone) { create(:merge_request, source_project: project, source_branch: 'branch-1', milestone: group_milestone) }
      let!(:mr_with_project_milestone) { create(:merge_request, source_project: project, source_branch: 'branch-2', milestone: project_milestone) }

      before do
        new_group.add_maintainer(user)
        project.add_maintainer(user)
        # simulate project transfer
        project.update!(group: new_group)
      end

      context 'without existing milestone at the new group level' do
        it 'recreates the missing group milestones at project level' do
          expect { service.execute }.to change(project.milestones, :count).by(1)
        end

        it 'applies new project milestone to issues with group milestone' do
          service.execute
          new_milestone = issue_with_group_milestone.reload.milestone

          expect(new_milestone).not_to eq(group_milestone)
          expect(new_milestone.title).to eq(group_milestone.title)
          expect(new_milestone.project_milestone?).to be_truthy
          expect(new_milestone.state).to eq("closed")
        end

        context 'when milestone is from an ancestor group' do
          let(:old_group_ancestor) { create(:group) }
          let(:old_group) { create(:group, parent: old_group_ancestor) }
          let(:group_milestone) { create(:milestone, group: old_group_ancestor) }

          it 'recreates the missing group milestones at project level' do
            expect { service.execute }.to change(project.milestones, :count).by(1)
          end
        end

        it 'deletes milestone counters cache for both milestones' do
          new_milestone = create(:milestone, project: project, title: group_milestone.title)

          expect_next_instance_of(Milestones::IssuesCountService, group_milestone) do |service|
            expect(service).to receive(:delete_cache).and_call_original
          end
          expect_next_instance_of(Milestones::ClosedIssuesCountService, group_milestone) do |service|
            expect(service).to receive(:delete_cache).and_call_original
          end
          expect_next_instance_of(Milestones::MergeRequestsCountService, group_milestone) do |service|
            expect(service).to receive(:delete_cache).and_call_original
          end
          expect_next_instance_of(Milestones::IssuesCountService, new_milestone) do |service|
            expect(service).to receive(:delete_cache).and_call_original
          end
          expect_next_instance_of(Milestones::ClosedIssuesCountService, new_milestone) do |service|
            expect(service).to receive(:delete_cache).and_call_original
          end
          expect_next_instance_of(Milestones::MergeRequestsCountService, new_milestone) do |service|
            expect(service).to receive(:delete_cache).and_call_original
          end

          service.execute
        end

        it 'does not apply new project milestone to issues with project milestone' do
          service.execute

          expect(issue_with_project_milestone.reload.milestone).to eq(project_milestone)
        end

        it 'applies new project milestone to merge_requests with group milestone' do
          service.execute
          new_milestone = mr_with_group_milestone.reload.milestone

          expect(new_milestone).not_to eq(group_milestone)
          expect(new_milestone.title).to eq(group_milestone.title)
          expect(new_milestone.project_milestone?).to be_truthy
          expect(new_milestone.state).to eq("closed")
        end

        it 'does not apply new project milestone to issuables with project milestone' do
          service.execute

          expect(mr_with_project_milestone.reload.milestone).to eq(project_milestone)
        end

        it 'does not recreate missing group milestones that are not applied to issues or merge requests' do
          service.execute
          new_milestone_title = project.reload.milestones.pluck(:title)

          expect(new_milestone_title).to include(group_milestone.title)
          expect(new_milestone_title).not_to include(group_milestone2.title)
        end

        context 'when find_or_create_milestone returns nil' do
          before do
            allow_next_instance_of(Milestones::FindOrCreateService) do |instance|
              allow(instance).to receive(:execute).and_return(nil)
            end
          end

          it 'removes issues group milestone' do
            service.execute

            expect(mr_with_group_milestone.reload.milestone).to be_nil
          end

          it 'removes merge requests group milestone' do
            service.execute

            expect(issue_with_group_milestone.reload.milestone).to be_nil
          end
        end
      end

      context 'with existing milestone at the new group level' do
        let!(:existing_milestone) { create(:milestone, group: new_group, title: group_milestone.title) }

        it 'does not create a new milestone' do
          expect { service.execute }.not_to change(project.milestones, :count)
        end

        it 'applies existing milestone to issues with group milestone' do
          service.execute

          expect(issue_with_group_milestone.reload.milestone).to eq(existing_milestone)
        end

        it 'applies existing milestone to merge_requests with group milestone' do
          service.execute

          expect(mr_with_group_milestone.reload.milestone).to eq(existing_milestone)
        end
      end
    end
  end

  context 'when old_group is not present' do
    let(:user)        { create(:admin) }
    let(:old_group)   { project.group }
    let(:project)     { create(:project, namespace: user.namespace) }

    it 'returns nil' do
      expect(described_class.new(user, old_group, project).execute).to be_nil
    end
  end
end
