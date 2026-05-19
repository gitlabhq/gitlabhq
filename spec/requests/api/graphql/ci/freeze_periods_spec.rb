# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.environment.deployFreezes', feature_category: :release_orchestration do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:freeze_period) { create(:ci_freeze_period, project: project) }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          environment(name: "#{environment.name}") {
            deployFreezes {
              status
              startCron
              endCron
              cronTimezone
            }
          }
        }
      }
    )
  end

  before_all do
    project.add_maintainer(user)
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', [:read_project, :read_freeze_period] do
    let(:boundary_object) { project }
    let(:request) { post_graphql(query, token: { personal_access_token: pat }) }
  end
end
