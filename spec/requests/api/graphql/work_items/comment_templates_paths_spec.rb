# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'work item comment templates', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:work_item) { create(:work_item, project: project) }

  let(:query) do
    graphql_query_for(
      'workItem',
      { 'id' => global_id_of(work_item) },
      query_nodes
    )
  end

  let(:query_nodes) do
    <<~GRAPHQL
      commentTemplatesPaths {
        href
        text
      }
    GRAPHQL
  end

  let(:templates_path_data) { graphql_data.dig('workItem', 'commentTemplatesPaths') }

  before_all do
    project.add_developer(user)
  end

  it 'returns the personal comment templates path' do
    post_graphql(query, current_user: user)

    expect(templates_path_data).to include(
      a_hash_including(
        'text' => 'Your comment templates',
        'href' => ::Gitlab::Routing.url_helpers.profile_comment_templates_path
      )
    )
  end
end
