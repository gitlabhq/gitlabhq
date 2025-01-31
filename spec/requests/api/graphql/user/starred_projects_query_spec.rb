# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting starredProjects of the user', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let(:query) do
    graphql_query_for(:user, user_params, user_fields)
  end

  let(:user_params) { { username: user.username } }

  let_it_be(:project_a) { create(:project, :public, name: 'ProjectA', path: 'Project-A', star_count: 30) }
  let_it_be(:project_b) { create(:project, :private, name: 'ProjectB', path: 'Project-B', star_count: 20) }
  let_it_be(:project_c) { create(:project, :private, name: 'ProjectC', path: 'Project-C', star_count: 10) }
  let_it_be(:user, reload: true) { create(:user) }

  let_it_be(:path) { %i[user starred_projects nodes] }

  let(:user_fields) { 'starredProjects { nodes { id } }' }

  let(:starred_projects) do
    post_graphql(query, current_user: current_user)

    graphql_data_at(*path)
  end

  before do
    project_b.add_reporter(user)
    project_c.add_reporter(user)

    user.toggle_star(project_a)
    user.toggle_star(project_b)
    user.toggle_star(project_c)
  end

  context 'anonymous access' do
    let(:current_user) { nil }

    it 'returns nothing' do
      expect(starred_projects).to be_nil
    end
  end

  context 'the current user is the user' do
    let(:current_user) { user }

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    it 'found all projects' do
      expect(starred_projects).to contain_exactly(
        a_graphql_entity_for(project_a),
        a_graphql_entity_for(project_b),
        a_graphql_entity_for(project_c)
      )
    end

    context 'when all fields are requested' do
      let(:user_fields) do
        "starredProjects { nodes {#{all_graphql_fields_for('Project', max_depth: 1,
          excluded: ['productAnalyticsState'])} } }"
      end

      it 'avoids N+1 queries', :use_sql_query_cache, :clean_gitlab_redis_cache do
        post_graphql(query, current_user: current_user)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          post_graphql(query, current_user: current_user)
        end

        project_d = create(:project, :public, name: 'ProjectD', path: 'Project-D', star_count: 30)
        project_d.add_reporter(user)
        user.toggle_star(project_d)

        # There is an N+1 query related to custom roles - https://gitlab.com/gitlab-org/gitlab/-/issues/515675
        # There is an N+1 query for duo_features_enabled cascading setting - https://gitlab.com/gitlab-org/gitlab/-/issues/442164
        # There is an N+1 query related to pipelines - https://gitlab.com/gitlab-org/gitlab/-/issues/515677
        expect do
          post_graphql(query, current_user: current_user)
        end.not_to exceed_all_query_limit(control).with_threshold(5)
      end
    end
  end

  context 'the current user is a member of a private project the user starred' do
    let_it_be(:other_user) { create(:user) }

    let(:current_user) { other_user }

    before do
      project_b.add_reporter(other_user)
    end

    it 'finds public and member projects' do
      expect(starred_projects).to contain_exactly(
        a_graphql_entity_for(project_a),
        a_graphql_entity_for(project_b)
      )
    end
  end

  context 'the user has a private profile' do
    before do
      user.update!(private_profile: true)
    end

    context 'the current user does not have access to view the private profile of the user' do
      let(:current_user) { create(:user) }

      it 'finds no projects' do
        expect(starred_projects).to be_empty
      end
    end

    context 'the current user has access to view the private profile of the user' do
      let(:current_user) { create(:admin) }

      it 'finds all projects starred by the user, which the current user has access to' do
        expect(starred_projects).to contain_exactly(
          a_graphql_entity_for(project_a),
          a_graphql_entity_for(project_b),
          a_graphql_entity_for(project_c)
        )
      end
    end

    context 'when sort parameter is provided' do
      let(:user_fields_with_sort) { "starredProjects(sort: #{sort_parameter}) { nodes { id name } }" }
      let(:query_with_sort) { graphql_query_for(:user, user_params, user_fields_with_sort) }
      let(:current_user) { user }

      context 'when sort parameter provided is invalid' do
        let(:sort_parameter) { 'does_not_exist' }

        it 'raises an exception' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_errors).to include(
            a_hash_including(
              'message' => "Argument 'sort' on Field 'starredProjects' has an invalid value (#{sort_parameter}). " \
                "Expected type 'ProjectSort'."
            )
          )
        end
      end

      context 'when sort parameter for id is provided' do
        context 'when ID_ASC is provided' do
          let(:sort_parameter) { 'ID_ASC' }

          it 'sorts starred projects by id in ascending order' do
            post_graphql(query_with_sort, current_user: current_user)

            expect(graphql_data_at(*path).pluck('id')).to eq([
              project_a.to_global_id.to_s,
              project_b.to_global_id.to_s,
              project_c.to_global_id.to_s
            ])
          end
        end

        context 'when ID_DESC is provided' do
          let(:sort_parameter) { 'ID_DESC' }

          it 'sorts starred projects by id in descending order' do
            post_graphql(query_with_sort, current_user: current_user)

            expect(graphql_data_at(*path).pluck('id')).to eq([
              project_c.to_global_id.to_s,
              project_b.to_global_id.to_s,
              project_a.to_global_id.to_s
            ])
          end
        end
      end

      context 'when sort parameter for latest activity is provided' do
        before do
          project_a.update!(last_activity_at: 2.hours.from_now)
          project_b.update!(last_activity_at: 3.hours.from_now)
          project_c.update!(last_activity_at: 4.hours.from_now)
        end

        context 'when LATEST_ACTIVITY_ASC is provided' do
          let(:sort_parameter) { 'LATEST_ACTIVITY_ASC' }

          it 'sorts starred projects by latest activity in ascending order' do
            post_graphql(query_with_sort, current_user: current_user)

            expect(graphql_data_at(*path).pluck('id')).to eq([
              project_a.to_global_id.to_s,
              project_b.to_global_id.to_s,
              project_c.to_global_id.to_s
            ])
          end
        end

        context 'when LATEST_ACTIVITY_DESC is provided' do
          let(:sort_parameter) { 'LATEST_ACTIVITY_DESC' }

          it 'sorts starred projects by latest activity in descending order' do
            post_graphql(query_with_sort, current_user: current_user)

            expect(graphql_data_at(*path).pluck('id')).to eq([
              project_c.to_global_id.to_s,
              project_b.to_global_id.to_s,
              project_a.to_global_id.to_s
            ])
          end
        end
      end

      context 'when sort parameter for name is provided' do
        context 'when NAME_ASC is provided' do
          let(:sort_parameter) { 'NAME_ASC' }

          it 'sorts starred projects by name in ascending order' do
            post_graphql(query_with_sort, current_user: current_user)

            expect(graphql_data_at(*path).pluck('id')).to eq([
              project_a.to_global_id.to_s,
              project_b.to_global_id.to_s,
              project_c.to_global_id.to_s
            ])
          end
        end

        context 'when NAME_DESC is provided' do
          let(:sort_parameter) { 'NAME_DESC' }

          it 'sorts starred projects by name in descending order' do
            post_graphql(query_with_sort, current_user: current_user)

            expect(graphql_data_at(*path).pluck('id')).to eq([
              project_c.to_global_id.to_s,
              project_b.to_global_id.to_s,
              project_a.to_global_id.to_s
            ])
          end
        end
      end

      context 'when sort parameter for path is provided' do
        context 'when PATH_ASC is provided' do
          let(:sort_parameter) { 'PATH_ASC' }

          it 'sorts starred projects by path in ascending order' do
            post_graphql(query_with_sort, current_user: current_user)

            expect(graphql_data_at(*path).pluck('id')).to eq([
              project_a.to_global_id.to_s,
              project_b.to_global_id.to_s,
              project_c.to_global_id.to_s
            ])
          end
        end

        context 'when PATH_DESC is provided' do
          let(:sort_parameter) { 'PATH_DESC' }

          it 'sorts starred projects by path in descending order' do
            post_graphql(query_with_sort, current_user: current_user)

            expect(graphql_data_at(*path).pluck('id')).to eq([
              project_c.to_global_id.to_s,
              project_b.to_global_id.to_s,
              project_a.to_global_id.to_s
            ])
          end
        end
      end

      context 'when sort parameter for stars is provided' do
        context 'when STARS_ASC is provided' do
          let(:sort_parameter) { 'STARS_ASC' }

          it 'sorts starred projects by stars in ascending order' do
            post_graphql(query_with_sort, current_user: current_user)

            expect(graphql_data_at(*path).pluck('id')).to eq([
              project_c.to_global_id.to_s,
              project_b.to_global_id.to_s,
              project_a.to_global_id.to_s
            ])
          end
        end

        context 'when STARS_DESC is provided' do
          let(:sort_parameter) { 'STARS_DESC' }

          it 'sorts starred projects by stars in descending order' do
            post_graphql(query_with_sort, current_user: current_user)

            expect(graphql_data_at(*path).pluck('id')).to eq([
              project_a.to_global_id.to_s,
              project_b.to_global_id.to_s,
              project_c.to_global_id.to_s
            ])
          end
        end
      end
    end
  end

  describe 'min_access_level' do
    let(:current_user) { user }

    let_it_be(:project_with_owner_access) { create(:project, :private) }

    let(:user_fields_with_min_access_level) do
      "starredProjects(minAccessLevel: #{min_access_level}) { nodes { id name } }"
    end

    let(:query_with_min_access_level) { graphql_query_for(:user, user_params, user_fields_with_min_access_level) }

    before_all do
      project_with_owner_access.add_owner(user)
      user.toggle_star(project_with_owner_access)
    end

    context 'when min_access_level is OWNER' do
      let(:min_access_level) { :OWNER }

      it 'returns only projects user has owner access to' do
        post_graphql(query_with_min_access_level, current_user: current_user)

        expect(graphql_data_at(*path))
          .to contain_exactly(a_graphql_entity_for(project_with_owner_access))
      end
    end

    context 'when min_access_level is REPORTER' do
      let(:min_access_level) { :REPORTER }

      it 'returns only projects user has reporter or higher access to' do
        post_graphql(query_with_min_access_level, current_user: current_user)

        expect(graphql_data_at(*path))
          .to contain_exactly(
            a_graphql_entity_for(project_with_owner_access),
            a_graphql_entity_for(project_b),
            a_graphql_entity_for(project_c)
          )
      end
    end
  end

  describe 'programming_language_name' do
    let(:current_user) { user }

    let_it_be(:ruby) { create(:programming_language, name: 'Ruby') }
    let_it_be(:repository_language) do
      create(:repository_language, project: project_b, programming_language: ruby, share: 1)
    end

    let(:query_with_programming_language_name) do
      graphql_query_for(:user, user_params, 'starredProjects(programmingLanguageName: "ruby") { nodes { id } }')
    end

    it 'returns only projects with ruby programming language' do
      post_graphql(query_with_programming_language_name, current_user: current_user)

      expect(graphql_data_at(*path))
        .to contain_exactly(
          a_graphql_entity_for(project_b)
        )
    end
  end
end
