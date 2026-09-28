# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting subscribed status of an issue', feature_category: :team_planning do
  include GraphqlHelpers

  it_behaves_like 'a subscribable resource api' do
    let_it_be(:resource) { create(:issue) }
    let(:mutation_name) { :issue_set_subscription }
  end

  describe 'granular PAT authorization' do
    it_behaves_like 'authorizing granular token permissions for GraphQL', :subscribe_issue do
      let_it_be(:issue) { create(:issue) }
      let_it_be(:project) { issue.project }
      let_it_be(:user) { create(:user, developer_of: project) }

      let(:boundary_object) { project }
      let(:mutation) do
        graphql_mutation(
          :issue_set_subscription,
          { project_path: project.full_path, iid: issue.iid.to_s, subscribed_state: true },
          'errors'
        )
      end

      let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
    end
  end
end
