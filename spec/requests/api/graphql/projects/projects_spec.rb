# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a collection of projects', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, name: 'public-group', developers: current_user) }
  let_it_be(:projects) { create_list(:project, 5, :public, group: group) }
  let_it_be(:other_project) { create(:project, :public, group: group) }
  let_it_be(:archived_project) { create(:project, :archived, group: group) }

  let(:filters) { {} }

  let(:query) do
    graphql_query_for(
      :projects,
      filters,
      "nodes {#{all_graphql_fields_for('Project', max_depth: 1, excluded: ['productAnalyticsState'])} }"
    )
  end

  context 'when archived argument is ONLY' do
    let(:filters) { { archived: :ONLY } }

    it 'returns only archived projects' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(:projects, :nodes))
        .to contain_exactly(a_graphql_entity_for(archived_project))
    end
  end

  context 'when archived argument is INCLUDE' do
    let(:filters) { { archived: :INCLUDE } }

    it 'returns archived and non-archived projects' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(:projects, :nodes))
      .to contain_exactly(
        *projects.map { |project| a_graphql_entity_for(project) },
        a_graphql_entity_for(other_project),
        a_graphql_entity_for(archived_project)
      )
    end
  end

  context 'when archived argument is EXCLUDE' do
    let(:filters) { { archived: :EXCLUDE } }

    it 'returns only non-archived projects' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(:projects, :nodes))
      .to contain_exactly(
        *projects.map { |project| a_graphql_entity_for(project) },
        a_graphql_entity_for(other_project)
      )
    end
  end

  describe 'min_access_level' do
    let_it_be(:project_with_owner_access) { create(:project, :private) }

    before_all do
      project_with_owner_access.add_owner(current_user)
    end

    context 'when min_access_level is OWNER' do
      let(:filters) { { min_access_level: :OWNER } }

      it 'returns only projects user has owner access to' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(:projects, :nodes))
          .to contain_exactly(a_graphql_entity_for(project_with_owner_access))
      end
    end

    context 'when min_access_level is DEVELOPER' do
      let(:filters) { { min_access_level: :DEVELOPER } }

      it 'returns only projects user has developer or higher access to' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(:projects, :nodes))
        .to contain_exactly(
          *projects.map { |project| a_graphql_entity_for(project) },
          a_graphql_entity_for(other_project),
          a_graphql_entity_for(project_with_owner_access)
        )
      end
    end
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

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post_graphql(single_project_query, current_user: current_user)
      end

      # There is an N+1 query related to custom roles - https://gitlab.com/gitlab-org/gitlab/-/issues/515675
      # There is an N+1 query for duo_features_enabled cascading setting - https://gitlab.com/gitlab-org/gitlab/-/issues/442164
      # There is an N+1 query related to pipelines - https://gitlab.com/gitlab-org/gitlab/-/issues/515677
      expect do
        post_graphql(query, current_user: current_user)
      end.not_to exceed_all_query_limit(control).with_threshold(8)
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

  context 'when providing the programming_language_name argument' do
    let_it_be(:project) { projects.first }
    let_it_be(:ruby) { create(:programming_language, name: 'Ruby') }
    let_it_be(:repository_language) do
      create(:repository_language, project: project, programming_language: ruby, share: 1)
    end

    let(:filters) { { programming_language_name: 'ruby' } }

    it 'returns the expected projects' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(:projects, :nodes))
        .to contain_exactly(a_graphql_entity_for(project))
    end
  end
end
