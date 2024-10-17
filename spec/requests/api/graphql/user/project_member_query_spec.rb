# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ProjectMember', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:member) { create(:project_member, :developer) }
  let_it_be(:fields) do
    <<~HEREDOC
      nodes {
        accessLevel {
          integerValue
          stringValue
        }
        project {
          id
        }
      }
    HEREDOC
  end

  let_it_be(:query) do
    graphql_query_for('user', { id: member.user.to_global_id.to_s }, query_graphql_field("projectMemberships", {}, fields))
  end

  before do
    post_graphql(query, current_user: member.user)
  end

  it_behaves_like 'a working graphql query'
  it_behaves_like 'a working membership object query'
end
