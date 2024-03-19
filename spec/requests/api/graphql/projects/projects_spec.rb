# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a collection of projects', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, name: 'public-group') }
  let_it_be(:projects) { create_list(:project, 5, :public, group: group) }
  let_it_be(:other_project) { create(:project, :public, group: group) }

  let(:filters) { {} }

  let(:query) do
    graphql_query_for(
      :projects,
      filters,
      "nodes {#{all_graphql_fields_for('Project', max_depth: 1, excluded: ['productAnalyticsState'])} }"
    )
  end

  before_all do
    group.add_developer(current_user)
  end

  context 'when providing full_paths filter' do
    let(:project_full_paths) { projects.map(&:full_path) }
    let(:filters) { { full_paths: project_full_paths } }

    let(:single_project_query) do
      graphql_query_for(
        :projects,
        { full_paths: [project_full_paths.first] },
        "nodes {#{all_graphql_fields_for('Project', max_depth: 1, excluded: ['productAnalyticsState'])} }"
      )
    end

    it_behaves_like 'a working graphql query that returns data' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    it 'avoids N+1 queries', :use_sql_query_cache, :clean_gitlab_redis_cache do
      post_graphql(single_project_query, current_user: current_user)

      control = ActiveRecord::QueryRecorder.new do
        post_graphql(single_project_query, current_user: current_user)
      end

      # There is an N+1 query for max_member_access_for_user_ids
      # There is an N+1 query for duo_features_enabled cascading setting
      # https://gitlab.com/gitlab-org/gitlab/-/issues/442164
      expect do
        post_graphql(query, current_user: current_user)
      end.not_to exceed_all_query_limit(control).with_threshold(17)
    end

    it 'returns the expected projects' do
      post_graphql(query, current_user: current_user)
      returned_full_paths = graphql_data_at(:projects, :nodes).pluck('fullPath')

      expect(returned_full_paths).to match_array(project_full_paths)
    end

    context 'when users provides more than 50 full_paths' do
      let(:filters) { { full_paths: Array.new(51) { other_project.full_path } } }

      it 'returns an error' do
        post_graphql(query, current_user: current_user)

        expect(graphql_errors).to contain_exactly(
          hash_including('message' => _('You cannot provide more than 50 full_paths'))
        )
      end
    end
  end
end
