# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'StarProject', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:current_user) { create(:user, developer_of: project) }

  let(:input) { { project_id: project.to_global_id.to_s, starred: true } }
  let(:mutation) { graphql_mutation(:star_project, input, 'count errors') }

  it 'stars the project' do
    expect { post_graphql_mutation(mutation, current_user: current_user) }
      .to change { current_user.starred?(project) }.from(false).to(true)
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :star_project do
    let(:user) { current_user }
    let(:boundary_object) { project }
    let(:mutation) { graphql_mutation(:star_project, input, 'count') }
    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end
end
