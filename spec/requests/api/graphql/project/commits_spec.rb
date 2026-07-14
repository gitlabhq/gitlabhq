# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project.repository.commit', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:current_user) { create(:user, developer_of: project) }

  let(:query) do
    graphql_query_for(
      'project',
      { fullPath: project.full_path },
      query_graphql_field('repository', {}, query_graphql_field('commit', { ref: 'HEAD' }, 'id sha'))
    )
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', [:read_project, :read_code] do
    let(:user) { current_user }
    let(:boundary_object) { project }
    let(:request) { post_graphql(query, token: { personal_access_token: pat }) }
  end
end
