# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::UpdateAssigneesService do
  include AfterNextHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :private, :repository, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:user3) { create(:user) }

  let_it_be_with_reload(:merge_request) do
    create(:merge_request, :simple, :unique_branches,
           title: 'Old title',
           description: "FYI #{user2.to_reference}",
           assignee_ids: [user3.id],
           source_project: project,
           author: create(:user))
  end

  before do
    project.add_maintainer(user)
    project.add_developer(user2)
    project.add_developer(user3)
  end

  let(:service) { described_class.new(project, user, opts) }
  let(:opts) { { assignee_ids: [user2.id] } }

  describe 'execute' do
    def update_merge_request
      service.execute(merge_request)
      merge_request.reload
    end

    context 'when the parameters are valid' do
      it 'updates the MR, and queues the more expensive work for later' do
        expect(MergeRequests::AssigneesChangeWorker)
          .to receive(:perform_async)
          .with(merge_request.id, user.id, [user3.id])

        expect { update_merge_request }
          .to change(merge_request, :assignees).to([user2])
          .and change(merge_request, :updated_at)
          .and change(merge_request, :updated_by).to(user)
      end

      it 'is more efficient than using the full update-service' do
        allow(MergeRequests::AssigneesChangeWorker)
          .to receive(:perform_async)
          .with(merge_request.id, user.id, [user3.id])

        other_mr = create(:merge_request, :simple, :unique_branches,
                          title: merge_request.title,
                          description: merge_request.description,
                          assignee_ids: merge_request.assignee_ids,
                          source_project: merge_request.project,
                          author: merge_request.author)

        update_service = ::MergeRequests::UpdateService.new(project, user, opts)

        expect { service.execute(merge_request) }
          .to issue_fewer_queries_than { update_service.execute(other_mr) }
      end
    end
  end

  describe '#handle_assignee_changes' do
    subject { service.handle_assignee_changes(merge_request, [user2]) }

    it 'calls UpdateService#handle_assignee_changes and executes hooks' do
      expect(service).to receive(:handle_assignees_change).with(merge_request, [user2])
      expect(merge_request.project).to receive(:execute_hooks).with(anything, :merge_request_hooks)
      expect(merge_request.project).to receive(:execute_services).with(anything, :merge_request_hooks)
      expect(service).to receive(:enqueue_jira_connect_messages_for).with(merge_request)

      subject
    end
  end
end
