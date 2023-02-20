# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Bulk update issues', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:group) { create(:group).tap { |group| group.add_developer(developer) } }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:updatable_issues, reload: true) { create_list(:issue, 2, project: project) }
  let_it_be(:milestone) { create(:milestone, group: group) }

  let(:parent) { project }
  let(:max_issues) { Mutations::Issues::BulkUpdate::MAX_ISSUES }
  let(:mutation) { graphql_mutation(:issues_bulk_update, base_arguments.merge(additional_arguments)) }
  let(:mutation_response) { graphql_mutation_response(:issues_bulk_update) }
  let(:current_user) { developer }
  let(:base_arguments) { { parent_id: parent.to_gid.to_s, ids: updatable_issues.map { |i| i.to_gid.to_s } } }

  let(:additional_arguments) do
    {
      assignee_ids: [current_user.to_gid.to_s],
      milestone_id: milestone.to_gid.to_s
    }
  end

  context 'when the `bulk_update_issues_mutation` feature flag is disabled' do
    before do
      stub_feature_flags(bulk_update_issues_mutation: false)
    end

    it 'returns a resource not available error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_errors).to contain_exactly(
        hash_including(
          'message' => '`bulk_update_issues_mutation` feature flag is disabled.'
        )
      )
    end
  end

  context 'when user can not update all issues' do
    let_it_be(:forbidden_issue) { create(:issue) }

    it 'updates only issues that the user can update' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)

        updatable_issues.each(&:reset)
        forbidden_issue.reset
      end.to change { updatable_issues.flat_map(&:assignee_ids) }.from([]).to([current_user.id] * 2).and(
        not_change(forbidden_issue, :assignee_ids).from([])
      )

      expect(mutation_response).to include(
        'updatedIssueCount' => updatable_issues.count
      )
    end
  end

  context 'when user can update all issues' do
    it 'updates all issues' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        updatable_issues.each(&:reload)
      end.to change { updatable_issues.flat_map(&:assignee_ids) }.from([]).to([current_user.id] * 2)
        .and(change { updatable_issues.map(&:milestone_id) }.from([nil] * 2).to([milestone.id] * 2))

      expect(mutation_response).to include(
        'updatedIssueCount' => updatable_issues.count
      )
    end

    context 'when current user cannot read the specified project' do
      let_it_be(:parent) { create(:project, :private) }

      it 'returns a resource not found error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors).to contain_exactly(
          hash_including(
            'message' => "The resource that you are attempting to access does not exist or you don't have " \
                         'permission to perform this action'
          )
        )
      end
    end

    context 'when scoping to a parent group' do
      let(:parent) { group }

      it 'updates all issues' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          updatable_issues.each(&:reload)
        end.to change { updatable_issues.flat_map(&:assignee_ids) }.from([]).to([current_user.id] * 2)
          .and(change { updatable_issues.map(&:milestone_id) }.from([nil] * 2).to([milestone.id] * 2))

        expect(mutation_response).to include(
          'updatedIssueCount' => updatable_issues.count
        )
      end

      context 'when current user cannot read the specified group' do
        let(:parent) { create(:group, :private) }

        it 'returns a resource not found error' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(graphql_errors).to contain_exactly(
            hash_including(
              'message' => "The resource that you are attempting to access does not exist or you don't have " \
                           'permission to perform this action'
            )
          )
        end
      end
    end

    context 'when setting arguments to null or none' do
      let(:additional_arguments) { { assignee_ids: [], milestone_id: nil } }

      before do
        updatable_issues.each do |issue|
          issue.update!(assignees: [current_user], milestone: milestone)
        end
      end

      it 'updates all issues' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          updatable_issues.each(&:reload)
        end.to change { updatable_issues.flat_map(&:assignee_ids) }.from([current_user.id] * 2).to([])
          .and(change { updatable_issues.map(&:milestone_id) }.from([milestone.id] * 2).to([nil] * 2))

        expect(mutation_response).to include(
          'updatedIssueCount' => updatable_issues.count
        )
      end
    end
  end

  context 'when update service returns an error' do
    before do
      allow_next_instance_of(Issuable::BulkUpdateService) do |update_service|
        allow(update_service).to receive(:execute).and_return(
          ServiceResponse.error(message: 'update error', http_status: 422) # rubocop:disable Gitlab/ServiceResponse
        )
      end
    end

    it 'returns an error message' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_data.dig('issuesBulkUpdate', 'errors')).to contain_exactly('update error')
    end
  end

  context 'when trying to update more than the max allowed' do
    before do
      stub_const('Mutations::Issues::BulkUpdate::MAX_ISSUES', updatable_issues.count - 1)
    end

    it "restricts updating more than #{Mutations::Issues::BulkUpdate::MAX_ISSUES} issues at the same time" do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_errors).to contain_exactly(
        hash_including(
          'message' =>
            format(_('No more than %{max_issues} issues can be updated at the same time'), max_issues: max_issues)
        )
      )
    end
  end
end
