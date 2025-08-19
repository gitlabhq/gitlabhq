# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::DestroyService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }

  subject(:service) { described_class.new(container: project, current_user: user) }

  context 'when issuable is an issue' do
    let!(:issue) { create(:issue, project: project, author: user, assignees: [user]) }

    it 'destroys the issue' do
      expect { service.execute(issue) }.to change { project.issues.count }.by(-1)
    end

    it 'publishes WorkItems::WorkItemDeletedEvent' do
      expect { service.execute(issue) }
        .to publish_event(::WorkItems::WorkItemDeletedEvent).with({
          id: issue.id,
          namespace_id: issue.namespace_id
        })
    end

    it 'updates open issues count cache' do
      expect_next_instance_of(Projects::OpenIssuesCountService) do |instance|
        expect(instance).to receive(:delete_cache)
      end

      service.execute(issue)
    end

    it 'invalidates the issues count cache for the assignees' do
      expect(user).to receive(:invalidate_cache_counts).once
      service.execute(issue)
    end

    it_behaves_like 'service deleting todos' do
      let(:issuable) { issue }
    end

    it_behaves_like 'service deleting label links' do
      let(:issuable) { issue }
    end
  end

  context 'when issuable is a work item' do
    let!(:work_item_parent) { create(:work_item, project: project) }
    let!(:work_item) { create(:work_item, :task, project: project) }

    before do
      create(:parent_link, work_item: work_item, work_item_parent: work_item_parent)
    end

    it 'publishes WorkItems::WorkItemDeletedEvent with the parent id' do
      expect { service.execute(work_item) }
        .to publish_event(::WorkItems::WorkItemDeletedEvent).with({
          id: work_item.id,
          namespace_id: work_item.namespace_id,
          previous_work_item_parent_id: work_item_parent.id
        })
    end
  end
end
