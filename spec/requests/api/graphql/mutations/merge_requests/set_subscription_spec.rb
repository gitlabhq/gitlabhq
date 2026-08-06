# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting subscribed status of a merge request', feature_category: :code_review_workflow do
  include GraphqlHelpers

  it_behaves_like 'a subscribable resource api' do
    let_it_be(:resource) { create(:merge_request) }
    let(:mutation_name) { :merge_request_set_subscription }
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :subscribe_merge_request do
    let_it_be(:merge_request) { create(:merge_request) }

    let(:project) { merge_request.project }
    let(:user) { create(:user, developer_of: project) }
    let(:boundary_object) { project }
    let(:request) do
      variables = {
        project_path: project.full_path,
        iid: merge_request.iid.to_s,
        subscribed_state: true
      }

      post_graphql_mutation(
        graphql_mutation(:merge_request_set_subscription, variables, 'errors'),
        token: { personal_access_token: pat }
      )
    end
  end
end
