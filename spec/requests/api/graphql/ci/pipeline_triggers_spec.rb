# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.pipelineTriggers', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:trigger) { create(:ci_trigger, project: project, owner: user) }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          pipelineTriggers {
            nodes {
              id
              description
              token
              canAccessProject
              hasTokenExposed
              lastUsed
            }
          }
        }
      }
    )
  end

  before_all do
    project.add_owner(user)
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', [:read_project, :read_trigger] do
    let(:boundary_object) { project }
    let(:request) { post_graphql(query, token: { personal_access_token: pat }) }
  end
end
