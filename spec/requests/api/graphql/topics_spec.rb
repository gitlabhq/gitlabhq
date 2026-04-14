# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.topics', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:topic) { create(:topic, name: 'GitLab') }

  def topics_query
    <<~QUERY
    {
      topics {
        nodes { __typename }
      }
    }
    QUERY
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :read_topic do
    let(:user) { current_user }
    let(:boundary_object) { :instance }
    let(:request) { post_graphql(topics_query, token: { personal_access_token: pat }) }
  end
end
