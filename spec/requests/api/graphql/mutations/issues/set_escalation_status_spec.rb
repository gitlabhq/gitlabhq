# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting the escalation status of an incident', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:incident, project: project) }
  let_it_be(:escalation_status) { create(:incident_management_issuable_escalation_status, issue: issue) }
  let_it_be(:user) { create(:user, developer_of: project) }

  let(:status) { 'ACKNOWLEDGED' }
  let(:input) { { project_path: project.full_path, iid: issue.iid.to_s, status: status } }

  let(:current_user) { user }
  let(:mutation) do
    graphql_mutation(:issue_set_escalation_status, input) do
      <<~QL
        clientMutationId
        errors
        issue {
          iid
          escalationStatus
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:issue_set_escalation_status) }

  context 'when user does not have permission to edit the escalation status' do
    let(:current_user) { create(:user) }

    before_all do
      project.add_reporter(user)
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'with non-incident issue is provided' do
    let_it_be(:issue) { create(:issue, project: project) }

    it_behaves_like 'a mutation that returns top-level errors', errors: ['Feature unavailable for provided issue']
  end

  it 'sets given escalation_policy to the escalation status for the issue' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['errors']).to be_empty
    expect(mutation_response['issue']['escalationStatus']).to eq(status)
    expect(escalation_status.reload.status_name).to eq(:acknowledged)
  end

  context 'when status argument is not given' do
    let(:input) { {} }

    it_behaves_like 'a mutation that returns top-level errors' do
      let(:match_errors) { contain_exactly(include('status (Expected value to not be null)')) }
    end
  end

  context 'when status argument is invalid' do
    let(:status) { 'INVALID' }

    it_behaves_like 'an invalid argument to the mutation', argument_name: :status
  end
end
