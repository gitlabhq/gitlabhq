# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting assignees of a merge request', :assume_throttled, feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user, developer_of: project) }
  let_it_be(:assignee) { create(:user) }
  let_it_be(:assignee2) { create(:user) }
  let_it_be_with_reload(:merge_request) { create(:merge_request, source_project: project) }

  let(:input) { { assignee_usernames: [assignee.username] } }
  let(:expected_result) do
    [{ 'username' => assignee.username }]
  end

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: merge_request.iid.to_s
    }
    graphql_mutation(
      :merge_request_set_assignees,
      variables.merge(input),
      <<-QL.strip_heredoc
        clientMutationId
        errors
        mergeRequest {
          id
          assignees {
            nodes {
              username
            }
          }
        }
      QL
    )
  end

  def mutation_response
    graphql_mutation_response(:merge_request_set_assignees)
  end

  def mutation_assignee_nodes
    mutation_response['mergeRequest']['assignees']['nodes']
  end

  def run_mutation!
    recorder = ActiveRecord::QueryRecorder.new do
      post_graphql_mutation(mutation, current_user: current_user)
    end

    expect(recorder.count).to be <= db_query_limit
  end

  before do
    project.add_developer(assignee)
    project.add_developer(assignee2)

    merge_request.update!(assignees: [])
  end

  it 'returns an error if the user is not allowed to update the merge request' do
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).not_to be_empty
  end

  context 'when the current user does not have permission to add assignees' do
    let(:current_user) { create(:user) }
    let(:db_query_limit) { 29 }

    it 'does not change the assignees' do
      project.add_guest(current_user)

      expect { run_mutation! }.not_to change { merge_request.reset.assignees.pluck(:id) }

      expect(graphql_errors).not_to be_empty
    end
  end

  context 'with assignees already assigned' do
    let(:db_query_limit) { 39 }

    before do
      merge_request.assignees = [assignee2]
      merge_request.save!
    end

    it 'replaces the assignee', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/444646' do
      run_mutation!

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_assignee_nodes).to match_array(expected_result)
    end

    it 'triggers webhooks', :sidekiq_inline do
      hook = create(:project_hook, merge_requests_events: true, project: merge_request.project)

      expect(WebHookWorker).to receive(:perform_async).with(hook.id, anything, 'merge_request_hooks', anything)

      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
    end
  end

  context 'when passing an empty list of assignees' do
    let(:db_query_limit) { 35 }
    let(:input) { { assignee_usernames: [] } }

    before do
      merge_request.assignees = [assignee2]
      merge_request.save!
    end

    it 'removes assignee', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/446115' do
      run_mutation!

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_assignee_nodes).to eq([])
    end
  end

  context 'when passing append as true' do
    let(:mode) { Types::MutationOperationModeEnum.enum[:append] }
    let(:input) { { assignee_usernames: [assignee2.username], operation_mode: mode } }
    let(:db_query_limit) { 26 }

    before do
      # In CE, APPEND is a NOOP as you can't have multiple assignees
      # We test multiple assignment in EE specs
      stub_licensed_features(multiple_merge_request_assignees: false)

      merge_request.assignees = [assignee]
      merge_request.save!
    end

    it 'does not replace the assignee in CE', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/446115' do
      run_mutation!

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_assignee_nodes).to match_array(expected_result)
    end
  end

  context 'when passing remove as true' do
    let(:db_query_limit) { 34 }
    let(:mode) { Types::MutationOperationModeEnum.enum[:remove] }
    let(:input) { { assignee_usernames: [assignee.username], operation_mode: mode } }
    let(:expected_result) { [] }

    before do
      merge_request.assignees = [assignee]
      merge_request.save!
    end

    it 'removes the users in the list, while adding none',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/446115' do
      run_mutation!

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_assignee_nodes).to match_array(expected_result)
    end
  end
end
