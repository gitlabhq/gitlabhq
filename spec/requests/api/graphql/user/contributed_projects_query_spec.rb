# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting contributedProjects of the user', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let(:query) { graphql_query_for(:user, user_params, user_fields) }
  let(:user_params) { { username: user.username } }
  let(:user_fields) { 'contributedProjects { nodes { id } }' }

  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:public_project) { create(:project, :public, name: 'foo') }
  let_it_be(:private_project) { create(:project, :private, name: 'bar') }
  let_it_be(:internal_project) { create(:project, :internal, name: 'baz') }
  let_it_be(:personal_project) { create(:project, namespace: user.namespace, name: 'biz') }

  let(:path) { %i[user contributed_projects nodes] }

  before_all do
    private_project.add_developer(user)
    private_project.add_developer(current_user)
    personal_project.add_developer(current_user)

    travel_to(4.hours.from_now) { create(:push_event, project: private_project, author: user) }
    travel_to(3.hours.from_now) { create(:push_event, project: internal_project, author: user) }
    travel_to(2.hours.from_now) { create(:push_event, project: public_project, author: user) }
    travel_to(2.hours.from_now) { create(:push_event, project: personal_project, author: user) }
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  context 'when all fields are requested' do
    let(:user_fields) do
      "contributedProjects { nodes {#{all_graphql_fields_for('Project', max_depth: 1,
        excluded: ['productAnalyticsState'])} } }"
    end

    it 'avoids N+1 queries', :use_sql_query_cache, :clean_gitlab_redis_cache do
      post_graphql(query, current_user: current_user)

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post_graphql(query, current_user: current_user)
      end

      new_project = create(:project, :public, name: 'New project', path: 'new-project')
      new_project.add_developer(user)
      travel_to(4.hours.from_now) { create(:push_event, project: new_project, author: user) }

      # There is an N+1 query related to custom roles - https://gitlab.com/gitlab-org/gitlab/-/issues/515675
      # There is an N+1 query for duo_features_enabled cascading setting - https://gitlab.com/gitlab-org/gitlab/-/issues/442164
      # There is an N+1 query related to pipelines - https://gitlab.com/gitlab-org/gitlab/-/issues/515677
      expect do
        post_graphql(query, current_user: current_user)
      end.not_to exceed_all_query_limit(control).with_threshold(5)
    end
  end

  describe 'sorting' do
    let(:user_fields_with_sort) { "contributedProjects(sort: #{sort_parameter}) { nodes { id } }" }
    let(:query_with_sort) { graphql_query_for(:user, user_params, user_fields_with_sort) }

    context 'when sort parameter is not provided' do
      it 'returns contributed projects in default order(LATEST_ACTIVITY_DESC)' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(*path).pluck('id')).to eq([
          private_project.to_global_id.to_s,
          internal_project.to_global_id.to_s,
          public_project.to_global_id.to_s
        ])
      end
    end

    context 'when sort parameter for id is provided' do
      context 'when ID_ASC is provided' do
        let(:sort_parameter) { 'ID_ASC' }

        it 'returns contributed projects in id ascending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            public_project.to_global_id.to_s,
            private_project.to_global_id.to_s,
            internal_project.to_global_id.to_s
          ])
        end
      end

      context 'when ID_DESC is provided' do
        let(:sort_parameter) { 'ID_DESC' }

        it 'returns contributed projects in id descending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            internal_project.to_global_id.to_s,
            private_project.to_global_id.to_s,
            public_project.to_global_id.to_s
          ])
        end
      end
    end

    context 'when sort parameter for name is provided' do
      before_all do
        public_project.update!(name: 'Project A')
        internal_project.update!(name: 'Project B')
        private_project.update!(name: 'Project C')
      end

      context 'when NAME_ASC is provided' do
        let(:sort_parameter) { 'NAME_ASC' }

        it 'returns contributed projects in name ascending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            public_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            private_project.to_global_id.to_s
          ])
        end
      end

      context 'when NAME_DESC is provided' do
        let(:sort_parameter) { 'NAME_DESC' }

        it 'returns contributed projects in name descending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            private_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            public_project.to_global_id.to_s
          ])
        end
      end
    end

    context 'when sort parameter for path is provided' do
      before_all do
        public_project.update!(path: 'Project-1')
        internal_project.update!(path: 'Project-2')
        private_project.update!(path: 'Project-3')
      end

      context 'when PATH_ASC is provided' do
        let(:sort_parameter) { 'PATH_ASC' }

        it 'returns contributed projects in path ascending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            public_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            private_project.to_global_id.to_s
          ])
        end
      end

      context 'when PATH_DESC is provided' do
        let(:sort_parameter) { 'PATH_DESC' }

        it 'returns contributed projects in path descending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            private_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            public_project.to_global_id.to_s
          ])
        end
      end
    end

    context 'when sort parameter for stars is provided' do
      before_all do
        public_project.update!(star_count: 10)
        internal_project.update!(star_count: 20)
        private_project.update!(star_count: 30)
      end

      context 'when STARS_ASC is provided' do
        let(:sort_parameter) { 'STARS_ASC' }

        it 'returns contributed projects in stars ascending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            public_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            private_project.to_global_id.to_s
          ])
        end
      end

      context 'when STARS_DESC is provided' do
        let(:sort_parameter) { 'STARS_DESC' }

        it 'returns contributed projects in stars descending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            private_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            public_project.to_global_id.to_s
          ])
        end
      end
    end

    context 'when sort parameter for latest activity is provided' do
      context 'when LATEST_ACTIVITY_ASC is provided' do
        let(:sort_parameter) { 'LATEST_ACTIVITY_ASC' }

        it 'returns contributed projects in latest activity ascending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            public_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            private_project.to_global_id.to_s
          ])
        end
      end

      context 'when LATEST_ACTIVITY_DESC is provided' do
        let(:sort_parameter) { 'LATEST_ACTIVITY_DESC' }

        it 'returns contributed projects in latest activity descending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            private_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            public_project.to_global_id.to_s
          ])
        end
      end
    end

    context 'when sort parameter for created_at is provided' do
      before_all do
        public_project.update!(created_at: Time.current + 1.hour)
        internal_project.update!(created_at: Time.current + 2.hours)
        private_project.update!(created_at: Time.current + 3.hours)
      end

      context 'when CREATED_ASC is provided' do
        let(:sort_parameter) { 'CREATED_ASC' }

        it 'returns contributed projects in created_at ascending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            public_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            private_project.to_global_id.to_s
          ])
        end
      end

      context 'when CREATED_DESC is provided' do
        let(:sort_parameter) { 'CREATED_DESC' }

        it 'returns contributed projects in created_at descending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            private_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            public_project.to_global_id.to_s
          ])
        end
      end
    end

    context 'when sort parameter for updated_at is provided' do
      before_all do
        public_project.update!(updated_at: Time.current + 1.hour)
        internal_project.update!(updated_at: Time.current + 2.hours)
        private_project.update!(updated_at: Time.current + 3.hours)
      end

      context 'when UPDATED_ASC is provided' do
        let(:sort_parameter) { 'UPDATED_ASC' }

        it 'returns contributed projects in updated_at ascending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            public_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            private_project.to_global_id.to_s
          ])
        end
      end

      context 'when UPDATED_DESC is provided' do
        let(:sort_parameter) { 'UPDATED_DESC' }

        it 'returns contributed projects in updated_at descending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            private_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            public_project.to_global_id.to_s
          ])
        end
      end
    end
  end

  describe 'min_access_level' do
    let_it_be(:project_with_owner_access) { create(:project, :private) }

    let(:user_fields_with_min_access_level) do
      "contributedProjects(minAccessLevel: #{min_access_level}) { nodes { id } }"
    end

    let(:query_with_min_access_level) { graphql_query_for(:user, user_params, user_fields_with_min_access_level) }

    before_all do
      project_with_owner_access.add_owner(user)
      project_with_owner_access.add_owner(current_user)
      travel_to(4.hours.from_now) { create(:push_event, project: project_with_owner_access, author: user) }
    end

    context 'when min_access_level is OWNER' do
      let(:min_access_level) { :OWNER }

      it 'returns only projects user has owner access to' do
        post_graphql(query_with_min_access_level, current_user: current_user)

        expect(graphql_data_at(*path))
          .to contain_exactly(a_graphql_entity_for(project_with_owner_access))
      end
    end

    context 'when min_access_level is DEVELOPER' do
      let(:min_access_level) { :DEVELOPER }

      it 'returns only projects user has developer or higher access to' do
        post_graphql(query_with_min_access_level, current_user: current_user)

        expect(graphql_data_at(*path))
          .to contain_exactly(
            a_graphql_entity_for(project_with_owner_access),
            a_graphql_entity_for(private_project)
          )
      end
    end
  end

  describe 'programming_language_name' do
    let_it_be(:ruby) { create(:programming_language, name: 'Ruby') }
    let_it_be(:repository_language) do
      create(:repository_language, project: internal_project, programming_language: ruby, share: 1)
    end

    let(:query_with_programming_language_name) do
      graphql_query_for(:user, user_params, 'contributedProjects(programmingLanguageName: "ruby") { nodes { id } }')
    end

    it 'returns only projects with ruby programming language' do
      post_graphql(query_with_programming_language_name, current_user: current_user)

      expect(graphql_data_at(*path))
        .to contain_exactly(
          a_graphql_entity_for(internal_project)
        )
    end
  end

  describe 'search' do
    let(:query_with_search) do
      graphql_query_for(:user, user_params, 'contributedProjects(search: "foo") { nodes { id } }')
    end

    it 'returns only projects that match search query' do
      post_graphql(query_with_search, current_user: current_user)

      expect(graphql_data_at(*path))
        .to contain_exactly(
          a_graphql_entity_for(public_project)
        )
    end
  end

  describe 'accessible' do
    context 'when user profile is public' do
      context 'when a logged in user with membership in the private project' do
        it 'returns contributed projects with visibility to the logged in user' do
          post_graphql(query, current_user: current_user)

          expect(graphql_data_at(*path)).to contain_exactly(
            a_graphql_entity_for(private_project),
            a_graphql_entity_for(internal_project),
            a_graphql_entity_for(public_project)
          )
        end
      end

      context 'when a logged in user with no visibility to the private project' do
        let_it_be(:current_user_2) { create(:user) }

        it 'returns contributed projects with visibility to the logged in user' do
          post_graphql(query, current_user: current_user_2)

          expect(graphql_data_at(*path)).to contain_exactly(
            a_graphql_entity_for(internal_project),
            a_graphql_entity_for(public_project)
          )
        end
      end

      context 'when an anonymous user' do
        it 'returns nothing' do
          post_graphql(query, current_user: nil)

          expect(graphql_data_at(*path)).to be_nil
        end
      end
    end

    context 'when user profile is private' do
      let(:user_params) { { username: private_user.username } }
      let_it_be(:private_user) { create(:user, :private_profile) }

      before_all do
        private_project.add_developer(private_user)
        private_project.add_developer(current_user)

        create(:push_event, project: private_project, author: private_user)
        create(:push_event, project: internal_project, author: private_user)
        create(:push_event, project: public_project, author: private_user)
      end

      context 'when a logged in user' do
        it 'returns no project' do
          post_graphql(query, current_user: current_user)

          expect(graphql_data_at(*path)).to be_empty
        end
      end

      context 'when an anonymous user' do
        it 'returns nothing' do
          post_graphql(query, current_user: nil)

          expect(graphql_data_at(*path)).to be_nil
        end
      end

      context 'when a logged in user is the user' do
        it 'returns the user\'s all contributed projects' do
          post_graphql(query, current_user: private_user)

          expect(graphql_data_at(*path)).to contain_exactly(
            a_graphql_entity_for(private_project),
            a_graphql_entity_for(internal_project),
            a_graphql_entity_for(public_project)
          )
        end
      end
    end
  end

  context 'when include_personal argument is false' do
    it 'does not include personal projects' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(*path))
      .to contain_exactly(
        a_graphql_entity_for(private_project),
        a_graphql_entity_for(internal_project),
        a_graphql_entity_for(public_project)
      )
    end
  end

  context 'when include_personal argument is true' do
    let(:query_with_include_personal) do
      graphql_query_for(:user, user_params, 'contributedProjects(includePersonal: true) { nodes { id } }')
    end

    it 'includes personal projects' do
      post_graphql(query_with_include_personal, current_user: current_user)

      expect(graphql_data_at(*path))
        .to contain_exactly(
          a_graphql_entity_for(private_project),
          a_graphql_entity_for(internal_project),
          a_graphql_entity_for(public_project),
          a_graphql_entity_for(personal_project)
        )
    end
  end

  describe 'sorting and pagination' do
    let(:data_path) { [:user, :contributed_projects] }

    def pagination_query(params)
      graphql_query_for(:user, user_params, "contributedProjects(#{params}) { #{page_info} nodes { id } }")
    end

    context 'when sorting in latest activity ascending order' do
      it_behaves_like 'sorted paginated query' do
        let(:sort_param) { :LATEST_ACTIVITY_ASC }
        let(:first_param) { 1 }
        let(:all_records) do
          [
            public_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            private_project.to_global_id.to_s
          ]
        end
      end
    end

    context 'when sorting in latest activity descending order' do
      it_behaves_like 'sorted paginated query' do
        let(:sort_param) { :LATEST_ACTIVITY_DESC }
        let(:first_param) { 1 }
        let(:all_records) do
          [
            private_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            public_project.to_global_id.to_s
          ]
        end
      end
    end
  end
end
