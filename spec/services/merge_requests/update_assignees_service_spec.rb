# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::UpdateAssigneesService, feature_category: :code_review_workflow do
  include AfterNextHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :private, :repository, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:user3) { create(:user) }

  let_it_be_with_reload(:merge_request) do
    create(
      :merge_request,
      :simple,
      :unique_branches,
      title: 'Old title',
      description: "FYI #{user2.to_reference}",
      assignee_ids: [user3.id],
      source_project: project,
      target_project: project,
      author: create(:user)
    )
  end

  let(:service) { described_class.new(project: project, current_user: user, params: opts) }
  let(:opts) { { assignee_ids: [user2.id] } }

  before do
    project.add_maintainer(user)
    project.add_developer(user2)
    project.add_developer(user3)
    merge_request.errors.clear
  end

  describe 'execute' do
    def update_merge_request
      service.execute(merge_request)
    end

    shared_examples 'it updates and enqueues the job' do
      it 'correctly updates the MR and enqueues the job' do
        expect_next(MergeRequests::HandleAssigneesChangeService, project: project, current_user: user) do |service|
          expect(service)
            .to receive(:async_execute).with(merge_request, [user3], execute_hooks: true)
        end

        expect { update_merge_request }
          .to change { merge_request.reload.assignees }.from([user3]).to(new_users)
          .and change(merge_request, :updated_at)
          .and change(merge_request, :updated_by).to(user)
      end
    end

    shared_examples 'removing all assignees' do
      it 'removes all assignees' do
        expect(update_merge_request).to have_attributes(assignees: be_empty, errors: be_none)
      end

      it 'enqueues the correct background work' do
        expect_next(MergeRequests::HandleAssigneesChangeService, project: project, current_user: user) do |service|
          expect(service)
            .to receive(:async_execute)
            .with(merge_request, [user3], execute_hooks: true)
        end

        update_merge_request
      end
    end

    context 'when the parameters are valid' do
      context 'when using sentinel values' do
        context 'when using assignee_ids' do
          let(:opts) { { assignee_ids: [0] } }

          it_behaves_like 'removing all assignees'
        end

        context 'when using assignee_id' do
          let(:opts) { { assignee_id: 0 } }

          it_behaves_like 'removing all assignees'
        end
      end

      context 'when the assignee_ids parameter is the empty list' do
        let(:opts) { { assignee_ids: [] } }

        it_behaves_like 'removing all assignees'
      end

      it_behaves_like 'it updates and enqueues the job' do
        let(:new_users) { [user2] }
      end

      it 'does not update the assignees if they do not have access' do
        opts[:assignee_ids] = [create(:user).id]

        expect(update_merge_request).to have_attributes(
          assignees: [user3],
          errors: be_any
        )
      end

      it 'is more efficient than using the full update-service' do
        allow_next(MergeRequests::HandleAssigneesChangeService, project: project, current_user: user) do |service|
          expect(service)
            .to receive(:async_execute)
            .with(merge_request, [user3], execute_hooks: true)
        end

        other_mr = create(
          :merge_request,
          :simple,
          :unique_branches,
          title: merge_request.title,
          description: merge_request.description,
          assignee_ids: merge_request.assignee_ids,
          source_project: merge_request.project,
          author: merge_request.author
        )

        update_service = ::MergeRequests::UpdateService.new(project: project, current_user: user, params: opts)

        expect { service.execute(merge_request) }
          .to issue_fewer_queries_than { update_service.execute(other_mr) }
      end
    end

    context 'when user has no set_merge_request_metadata permissions' do
      before do
        allow(user).to receive(:can?).and_call_original

        allow(user)
          .to receive(:can?)
          .with(:set_merge_request_metadata, merge_request)
          .and_return(false)
      end

      it 'does not update the MR assignees' do
        expect { update_merge_request }
          .not_to change { merge_request.reload.assignees.to_a }
      end
    end
  end
end
