# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Groups, :with_current_organization, feature_category: :groups_and_projects do
  include GroupAPIHelpers
  include UploadHelpers
  include WorkhorseHelpers

  let_it_be(:user1) { create(:user, can_create_group: false, organizations: [current_organization]) }
  let_it_be(:user2) { create(:user, organizations: [current_organization]) }
  let_it_be(:user3) { create(:user, organizations: [current_organization]) }
  let_it_be(:admin) { create(:admin, organizations: [current_organization]) }
  let_it_be(:group1) { create(:group, path: 'some_path', avatar: File.open(uploaded_image_temp_path), owners: user1, organization: current_organization) }
  let_it_be(:group2) { create(:group, :private, owners: user2, organization: current_organization) }
  let_it_be(:project1) { create(:project, namespace: group1) }
  let_it_be(:project2) { create(:project, namespace: group2, name: 'testing') }
  let_it_be(:project3) { create(:project, namespace: group1, path: 'test', visibility_level: Gitlab::VisibilityLevel::PRIVATE) }
  let_it_be(:archived_project) { create(:project, namespace: group1, archived: true) }

  def expect_log_keys(caller_id:, route:, root_namespace:)
    expect(API::API::LOG_FORMATTER).to receive(:call) do |_severity, _datetime, _, data|
      expect(data.stringify_keys).to include(
        'correlation_id' => an_instance_of(String),
        'meta.caller_id' => caller_id,
        'route' => route,
        'meta.root_namespace' => root_namespace
      )
    end
  end

  shared_examples 'group avatar upload' do
    context 'when valid' do
      let(:file_path) { 'spec/fixtures/banana_sample.gif' }

      it 'returns avatar url in response' do
        make_upload_request

        group_id = json_response['id']
        expect(json_response['avatar_url']).to eq('http://localhost/uploads/'\
                                                  '-/system/group/avatar/'\
                                                  "#{group_id}/banana_sample.gif")
      end
    end

    context 'when invalid' do
      shared_examples 'invalid file upload request' do
        it 'returns 400', :aggregate_failures do
          make_upload_request

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.message).to eq('Bad Request')
          expect(json_response['message'].to_s).to match(/#{message}/)
        end
      end

      context 'when file format is not supported' do
        let(:file_path) { 'spec/fixtures/doc_sample.txt' }
        let(:message)   { 'file format is not supported. Please try one of the following supported formats: image/png, image/jpeg, image/gif, image/bmp, image/tiff, image/vnd.microsoft.icon' }

        it_behaves_like 'invalid file upload request'
      end

      context 'when file is too large' do
        let(:file_path) { 'spec/fixtures/big-image.png' }
        let(:message)   { 'is too big' }

        it_behaves_like 'invalid file upload request'
      end
    end
  end

  shared_examples 'skips searching in full path' do
    it 'does not find groups by full path', :aggregate_failures do
      subgroup = create(:group, parent: parent, path: "#{parent.path}-subgroup")
      create(:group, parent: parent, path: 'not_matching_path')

      get endpoint, params: { search: parent.path }

      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(subgroup.id)
    end
  end

  shared_examples 'includes statistics when all_available is false' do
    let(:params) { { all_available: false, statistics: true } }

    before do
      group1.add_developer(admin)
      create(:group, parent: group1)
    end

    it 'returns the statistics', :aggregate_failures do
      get api(api_endpoint, admin, admin_mode: true), params: params

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_an Array
      expect(json_response.first).to include('statistics')
    end
  end

  describe "GET /groups" do
    shared_examples 'groups list N+1' do
      it 'avoids N+1 queries', :use_sql_query_cache do
        # warm-up
        get api("/groups", user)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          get api("/groups", user)
        end

        create(:group, :public)

        expect do
          get api("/groups", user)
        end.not_to exceed_all_query_limit(control)
      end
    end

    it_behaves_like 'rate limited endpoint', rate_limit_key: :groups_api do
      def request
        get api("/groups")
      end
    end

    context 'when rate_limit_groups_and_projects_api feature flag is disabled' do
      before do
        stub_feature_flags(rate_limit_groups_and_projects_api: false)
      end

      it_behaves_like 'unthrottled endpoint'

      def request
        get api("/groups")
      end
    end

    context "when unauthenticated" do
      it "returns public groups", :aggregate_failures do
        get api("/groups")

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['created_at']).to be_present
        expect(json_response)
          .to satisfy_one { |group| group['name'] == group1.name }
      end

      it_behaves_like 'groups list N+1' do
        let(:user) { nil }
      end

      context 'when statistics are requested' do
        it 'does not include statistics', :aggregate_failures do
          get api("/groups"), params: { statistics: true }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.first).not_to include 'statistics'
        end
      end
    end

    context "when authenticated as user" do
      it_behaves_like 'groups list N+1' do
        let(:user) { user1 }
      end

      it "normal user: returns an array of groups of user1", :aggregate_failures do
        get api("/groups", user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response)
          .to satisfy_one { |group| group['name'] == group1.name }
      end

      it "does not include runners_token information", :aggregate_failures do
        get api("/groups", user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first).not_to include('runners_token')
      end

      it "does not include statistics", :aggregate_failures do
        get api("/groups", user1), params: { statistics: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include 'statistics'
      end

      it "includes a created_at timestamp", :aggregate_failures do
        get api("/groups", user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['created_at']).to be_present
      end
    end

    context 'when using the visibility filter' do
      let_it_be(:group_1) { create(:group, :private) }
      let_it_be(:group_2) { create(:group, :internal) }
      let_it_be(:group_3) { create(:group, :public) }
      let_it_be(:group_4) { create(:group, :private) }
      let_it_be(:group_5) { create(:group, :public) }
      let(:response_groups) { json_response.map { |group| group['id'] } }

      before_all do
        group_1.add_owner(user1)
        group_2.add_owner(user1)
        group_3.add_owner(user1)
        group_4.add_owner(user1)
        group_5.add_owner(user1)
      end

      it 'filters based on private visibility param' do
        get api("/groups", user1), params: { visibility: 'private' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to contain_exactly(group_1.id, group_4.id)
      end

      it 'filters based on internal visibility param' do
        get api("/groups", user1), params: { visibility: 'internal' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to contain_exactly(group_2.id)
      end

      it 'filters based on public visibility param' do
        get api("/groups", user1), params: { visibility: 'public' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to contain_exactly(group1.id, group_3.id, group_5.id)
      end

      it 'filters based on no visibility param passed' do
        get api("/groups", user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to contain_exactly(group1.id, group_1.id, group_2.id, group_3.id, group_4.id, group_5.id)
      end

      it 'filters based on unknown visibility param' do
        get api("/groups", user1), params: { visibility: 'something' }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('visibility does not have a valid value')
      end
    end

    context 'pagination strategies' do
      let_it_be(:group_1) { create(:group, name: '1_group') }
      let_it_be(:group_2) { create(:group, name: '2_group') }

      context 'when the user is anonymous' do
        context 'offset pagination' do
          context 'on making requests beyond the allowed offset pagination threshold' do
            it 'returns error and suggests to use keyset pagination' do
              get api('/groups'), params: { page: 3000, per_page: 25 }

              expect(response).to have_gitlab_http_status(:method_not_allowed)
              expect(json_response['error']).to eq(
                'Offset pagination has a maximum allowed offset of 50000 for requests that return objects of type Group. '\
                'Remaining records can be retrieved using keyset pagination.'
              )
            end
          end

          context 'on making requests below the allowed offset pagination threshold' do
            it 'paginates the records', :aggregate_failures do
              get api('/groups'), params: { page: 1, per_page: 1 }

              expect(response).to have_gitlab_http_status(:ok)
              records = json_response
              expect(records.size).to eq(1)
              expect(records.first['id']).to eq(group_1.id)

              # next page

              get api('/groups'), params: { page: 2, per_page: 1 }

              expect(response).to have_gitlab_http_status(:ok)
              records = Gitlab::Json.parse(response.body)
              expect(records.size).to eq(1)
              expect(records.first['id']).to eq(group_2.id)
            end
          end
        end

        it_behaves_like 'an endpoint with keyset pagination', invalid_order: 'path' do
          let(:first_record) { group_1 }
          let(:second_record) { group_2 }
          let(:api_call) { api('/groups') }
        end
      end
    end

    context "when authenticated as admin" do
      it "admin: returns an array of all groups", :aggregate_failures do
        get api("/groups", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
      end

      it "does not include runners_token information", :aggregate_failures do
        get api("/groups", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
        expect(json_response.first).not_to include('runners_token')
      end

      it "does not include statistics by default", :aggregate_failures do
        get api("/groups", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include('statistics')
      end

      it "includes a created_at timestamp", :aggregate_failures do
        get api("/groups", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['created_at']).to be_present
      end

      it "includes statistics if requested", :aggregate_failures do
        stat_keys = %w[storage_size repository_size wiki_size
          lfs_objects_size job_artifacts_size pipeline_artifacts_size
          packages_size snippets_size uploads_size]

        get api("/groups", admin, admin_mode: true), params: { statistics: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array

        expect(json_response[0]["statistics"].keys).to match_array(stat_keys)
      end

      it_behaves_like 'includes statistics when all_available is false' do
        let(:api_endpoint) { "/groups" }
      end
    end

    context "when using skip_groups in request" do
      it "returns all groups excluding skipped groups", :aggregate_failures do
        get api("/groups", admin, admin_mode: true), params: { skip_groups: [group2.id] }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
      end
    end

    context "when using all_available in request" do
      let(:response_groups) { json_response.map { |group| group['name'] } }

      it "returns all groups you have access to", :aggregate_failures do
        public_group = create :group, :public

        get api("/groups", user1), params: { all_available: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to contain_exactly(public_group.name, group1.name)
      end
    end

    context "when using top_level_only" do
      let(:top_level_group) { create(:group, name: 'top-level-group') }
      let(:subgroup) { create(:group, :nested, name: 'subgroup') }
      let(:response_groups) { json_response.map { |group| group['name'] } }

      before do
        top_level_group.add_owner(user1)
        subgroup.add_owner(user1)
      end

      it "doesn't return subgroups", :aggregate_failures do
        get api("/groups", user1), params: { top_level_only: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to include(top_level_group.name)
        expect(response_groups).not_to include(subgroup.name)
      end
    end

    context "when using sorting" do
      let_it_be(:group3) { create(:group, name: "a#{group1.name}", path: "z#{group1.path}") }
      let_it_be(:group4) { create(:group, name: "same-name", path: "y#{group1.path}") }
      let_it_be(:group5) { create(:group, name: "same-name") }

      let(:response_groups) { json_response.map { |group| group['name'] } }
      let(:response_groups_ids) { json_response.map { |group| group['id'] } }

      before_all do
        group3.add_owner(user1)
        group4.add_owner(user1)
        group5.add_owner(user1)
      end

      it "sorts by name ascending by default", :aggregate_failures do
        get api("/groups", user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq(groups_visible_to_user(user1).order(:name).pluck(:name))
      end

      it "sorts in descending order when passed", :aggregate_failures do
        get api("/groups", user1), params: { sort: "desc" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq(groups_visible_to_user(user1).order(name: :desc).pluck(:name))
      end

      it "sorts by path in order_by param", :aggregate_failures do
        get api("/groups", user1), params: { order_by: "path" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq(groups_visible_to_user(user1).order(:path).pluck(:name))
      end

      it "sorts by id in the order_by param", :aggregate_failures do
        get api("/groups", user1), params: { order_by: "id" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq(groups_visible_to_user(user1).order(:id).pluck(:name))
      end

      it "sorts also by descending id with pagination fix", :aggregate_failures do
        get api("/groups", user1), params: { order_by: "id", sort: "desc" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq(groups_visible_to_user(user1).order(id: :desc).pluck(:name))
      end

      it "sorts identical keys by id for good pagination", :aggregate_failures do
        get api("/groups", user1), params: { search: "same-name", order_by: "name" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups_ids).to eq(Group.select { |group| group['name'] == 'same-name' }.map { |group| group['id'] }.sort)
      end

      it "sorts descending identical keys by id for good pagination", :aggregate_failures do
        get api("/groups", user1), params: { search: "same-name", order_by: "name", sort: "desc" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups_ids).to eq(Group.select { |group| group['name'] == 'same-name' }.map { |group| group['id'] }.sort)
      end

      context 'when searching with similarity ordering', :aggregate_failures do
        let_it_be(:group6) { create(:group, name: 'same-name subgroup', parent: group4) }
        let_it_be(:group7) { create(:group, name: 'same-name parent') }

        let(:params) { { order_by: 'similarity', search: 'same-name' } }

        before_all do
          group6.add_owner(user1)
          group7.add_owner(user1)
        end

        subject { get api('/groups', user1), params: params }

        it 'sorts top level groups before subgroups with exact matches first', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response.length).to eq(4)

          expect(response_groups).to eq(['same-name', 'same-name parent', 'same-name subgroup', 'same-name'])
        end

        context 'when `search` parameter is not given' do
          let(:params) { { order_by: 'similarity' } }

          it 'sorts items ordered by name', :aggregate_failures do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response.length).to eq(6)

            expect(response_groups).to eq(groups_visible_to_user(user1).order(:name).pluck(:name))
          end
        end
      end

      def groups_visible_to_user(user)
        Group.where(id: user.authorized_groups.select(:id).reorder(nil))
      end
    end

    context 'when using owned in the request' do
      it 'returns an array of groups the user owns', :aggregate_failures do
        group1.add_maintainer(user2)

        get api('/groups', user2), params: { owned: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(group2.name)
      end
    end

    context 'when using min_access_level in the request' do
      let!(:group3) { create(:group, :private) }
      let(:response_groups) { json_response.map { |group| group['id'] } }

      before do
        group1.add_developer(user2)
        group3.add_maintainer(user2)
      end

      context 'with min_access_level parameter' do
        it 'returns an array of groups the user has at least master access', :aggregate_failures do
          get api('/groups', user2), params: { min_access_level: 40 }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(response_groups).to contain_exactly(group2.id, group3.id)
        end

        context 'distinct count' do
          subject { get api('/groups', user2), params: { min_access_level: 40 } }

          # Prevent Rails from optimizing the count query and inadvertadly creating a poor performing databse query.
          # https://gitlab.com/gitlab-org/gitlab/-/issues/368969
          it 'counts with *' do
            count_sql = /#{Regexp.escape('SELECT count(*)')}/i
            expect { subject }.to make_queries_matching count_sql
          end
        end
      end
    end

    context 'when searching' do
      let_it_be(:subgroup1) { create(:group, parent: group1, path: 'some_path') }

      let(:response_groups) { json_response.map { |group| group['id'] } }

      subject { get api('/groups', user1), params: { search: group1.path } }

      it 'finds also groups with full path matching search param', :aggregate_failures do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(response_groups).to match_array([group1.id, subgroup1.id])
      end
    end
  end

  describe "GET /groups/:id" do
    # Given a group, create one project for each visibility level
    #
    # group      - Group to add projects to
    # share_with - If provided, each project will be shared with this Group
    #
    # Returns a Hash of visibility_level => Project pairs
    def add_projects_to_group(group, share_with: nil)
      projects = {
        public: create(:project, :public, namespace: group),
        internal: create(:project, :internal, namespace: group),
        private: create(:project, :private,  namespace: group)
      }

      if share_with
        create(:project_group_link, project: projects[:public],   group: share_with)
        create(:project_group_link, project: projects[:internal], group: share_with)
        create(:project_group_link, project: projects[:private],  group: share_with)
      end

      projects
    end

    def response_project_ids(json_response, key)
      json_response[key].map do |project|
        project['id'].to_i
      end
    end

    it_behaves_like 'rate limited endpoint', rate_limit_key: :group_api do
      def request
        get api("/groups/#{group2.id}")
      end
    end

    context 'when rate_limit_groups_and_projects_api feature flag is disabled' do
      before do
        stub_feature_flags(rate_limit_groups_and_projects_api: false)
      end

      it_behaves_like 'unthrottled endpoint'

      def request
        get api("/groups/#{group2.id}")
      end
    end

    context 'when unauthenticated' do
      it 'returns 404 for a private group' do
        get api("/groups/#{group2.id}")

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns 200 for a public group', :aggregate_failures do
        expect_log_keys(caller_id: "GET /api/:version/groups/:id",
          route: "/api/:version/groups/:id",
          root_namespace: group1.path)

        get api("/groups/#{group1.id}")

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to include('runners_token')
        expect(json_response).to include('created_at')
      end

      it 'returns only public projects in the group' do
        public_group = create(:group, :public)
        projects = add_projects_to_group(public_group)

        get api("/groups/#{public_group.id}")

        expect(response_project_ids(json_response, 'projects'))
          .to contain_exactly(projects[:public].id)
      end

      it 'returns only public projects shared with the group' do
        public_group = create(:group, :public)
        projects = add_projects_to_group(public_group, share_with: group1)

        get api("/groups/#{group1.id}")

        expect(response_project_ids(json_response, 'shared_projects'))
          .to contain_exactly(projects[:public].id)
      end
    end

    context "when authenticated as user" do
      it "returns one of user1's groups", :aggregate_failures do
        project = create(:project, namespace: group2, path: 'Foo')
        create(:project_group_link, project: project, group: group1)
        group = create(:group)
        link = create(:group_group_link, shared_group: group1, shared_with_group: group)

        get api("/groups/#{group1.id}", user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(group1.id)
        expect(json_response['name']).to eq(group1.name)
        expect(json_response['path']).to eq(group1.path)
        expect(json_response['description']).to eq(group1.description)
        expect(json_response['visibility']).to eq(Gitlab::VisibilityLevel.string_level(group1.visibility_level))
        expect(json_response['avatar_url']).to eq(group1.avatar_url(only_path: false))
        expect(json_response['share_with_group_lock']).to eq(group1.share_with_group_lock)
        expect(json_response['prevent_sharing_groups_outside_hierarchy']).to eq(group2.namespace_settings.prevent_sharing_groups_outside_hierarchy)
        expect(json_response['require_two_factor_authentication']).to eq(group1.require_two_factor_authentication)
        expect(json_response['two_factor_grace_period']).to eq(group1.two_factor_grace_period)
        expect(json_response['auto_devops_enabled']).to eq(group1.auto_devops_enabled)
        expect(json_response['emails_disabled']).to eq(group1.emails_disabled?)
        expect(json_response['emails_enabled']).to eq(group1.emails_enabled?)
        expect(json_response['mentions_disabled']).to eq(group1.mentions_disabled)
        expect(json_response['project_creation_level']).to eq('maintainer')
        expect(json_response['subgroup_creation_level']).to eq('maintainer')
        expect(json_response['web_url']).to eq(group1.web_url)
        expect(json_response['request_access_enabled']).to eq(group1.request_access_enabled)
        expect(json_response['full_name']).to eq(group1.full_name)
        expect(json_response['full_path']).to eq(group1.full_path)
        expect(json_response['parent_id']).to eq(group1.parent_id)
        expect(json_response['created_at']).to be_present
        expect(json_response['shared_with_groups']).to be_an Array
        expect(json_response['shared_with_groups'].length).to eq(1)
        expect(json_response['shared_with_groups'][0]['group_id']).to eq(group.id)
        expect(json_response['shared_with_groups'][0]['group_name']).to eq(group.name)
        expect(json_response['shared_with_groups'][0]['group_full_path']).to eq(group.full_path)
        expect(json_response['shared_with_groups'][0]['group_access_level']).to eq(link.group_access)
        expect(json_response['shared_with_groups'][0]).to have_key('expires_at')
        expect(json_response['projects']).to be_an Array
        expect(json_response['projects'].length).to eq(3)
        expect(json_response['shared_projects']).to be_an Array
        expect(json_response['shared_projects'].length).to eq(1)
        expect(json_response['shared_projects'][0]['id']).to eq(project.id)
        expect(json_response['math_rendering_limits_enabled']).to eq(group2.math_rendering_limits_enabled?)
      end

      it "returns one of user1's groups without projects when with_projects option is set to false", :aggregate_failures do
        project = create(:project, namespace: group2, path: 'Foo')
        create(:project_group_link, project: project, group: group1)

        get api("/groups/#{group2.id}", user1), params: { with_projects: false }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['projects']).to be_nil
        expect(json_response['shared_projects']).to be_nil
        expect(json_response).not_to include('runners_token')
      end

      it "doesn't return runners_token if the user is not the owner of the group", :aggregate_failures do
        get api("/groups/#{group1.id}", user3)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to include('runners_token')
      end

      it "returns runners_token if the user is the owner of the group", :aggregate_failures do
        group1.add_owner(user3)
        get api("/groups/#{group1.id}", user3)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include('runners_token')
      end

      it "does not return a non existing group" do
        get api("/groups/#{non_existing_record_id}", user1)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it "does not return a group not attached to user1" do
        get api("/groups/#{group2.id}", user1)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns only public and internal projects in the group' do
        public_group = create(:group, :public)
        projects = add_projects_to_group(public_group)

        get api("/groups/#{public_group.id}", user2)

        expect(response_project_ids(json_response, 'projects'))
          .to contain_exactly(projects[:public].id, projects[:internal].id)
      end

      it 'returns only public and internal projects shared with the group' do
        public_group = create(:group, :public)
        projects = add_projects_to_group(public_group, share_with: group1)

        get api("/groups/#{group1.id}", user2)

        expect(response_project_ids(json_response, 'shared_projects'))
          .to contain_exactly(projects[:public].id, projects[:internal].id)
      end

      it 'avoids N+1 queries with project links', :aggregate_failures do
        get api("/groups/#{group1.id}", user1)
        expect(response).to have_gitlab_http_status(:ok)

        control = ActiveRecord::QueryRecorder.new do
          get api("/groups/#{group1.id}", user1)
        end

        create(:project, namespace: group1)

        expect do
          get api("/groups/#{group1.id}", user1)
        end.not_to exceed_query_limit(control)
      end

      it 'avoids N+1 queries with shared group links' do
        # setup at least 1 shared group, so that we record the queries that preload the nested associations too.
        create(:group_group_link, shared_group: group1, shared_with_group: create(:group))

        control = ActiveRecord::QueryRecorder.new do
          get api("/groups/#{group1.id}", user1)
        end

        # setup "n" more shared groups
        create(:group_group_link, shared_group: group1, shared_with_group: create(:group))
        create(:group_group_link, shared_group: group1, shared_with_group: create(:group))

        # test that no of queries for 1 shared group is same as for n shared groups
        expect do
          get api("/groups/#{group1.id}", user1)
        end.not_to exceed_query_limit(control)
      end
    end

    context "when authenticated as admin" do
      it "returns any existing group", :aggregate_failures do
        get api("/groups/#{group2.id}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(group2.name)
      end

      it "returns information of the runners_token for the group", :aggregate_failures do
        get api("/groups/#{group2.id}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include('runners_token')
      end

      it "returns runners_token and no projects when with_projects option is set to false", :aggregate_failures do
        project = create(:project, namespace: group2, path: 'Foo')
        create(:project_group_link, project: project, group: group1)

        get api("/groups/#{group2.id}", admin, admin_mode: true), params: { with_projects: false }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['projects']).to be_nil
        expect(json_response['shared_projects']).to be_nil
        expect(json_response).to include('runners_token')
      end

      it "does not return a non existing group" do
        get api("/groups/#{non_existing_record_id}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when using group path in URL' do
      it 'returns any existing group', :aggregate_failures do
        get api("/groups/#{group1.path}", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(group1.name)
      end

      it 'does not return a non existing group' do
        get api('/groups/unknown', admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'does not return a group not attached to user1' do
        get api("/groups/#{group2.path}", user1)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'limiting the number of projects and shared_projects in the response' do
      let(:limit) { 1 }

      before do
        stub_const("GroupProjectsFinder::DEFAULT_PROJECTS_LIMIT", limit)

        # creates 3 public projects
        create_list(:project, 3, :public, namespace: group1)

        # creates 3 shared projects
        public_group = create(:group, :public)
        projects_to_be_shared = create_list(:project, 3, :public, namespace: public_group)

        projects_to_be_shared.each do |project|
          create(:project_group_link, project: project, group: group1)
        end
      end

      it 'limits projects and shared_projects', :aggregate_failures do
        get api("/groups/#{group1.id}")

        expect(json_response['projects'].count).to eq(limit)
        expect(json_response['shared_projects'].count).to eq(limit)
      end
    end

    context 'when a group is shared', :aggregate_failures do
      let_it_be(:shared_group) { create(:group) }
      let_it_be(:group2_sub) { create(:group, :private, parent: group2) }
      let_it_be(:group_link_1) { create(:group_group_link, shared_group: shared_group, shared_with_group: group1) }
      let_it_be(:group_link_2) { create(:group_group_link, shared_group: shared_group, shared_with_group: group2_sub) }

      subject(:shared_with_groups) { json_response['shared_with_groups'].map { _1['group_id'] } }

      context 'when authenticated as admin' do
        it 'returns all groups that share the group', :aggregate_failures do
          get api("/groups/#{shared_group.id}", admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:ok)
          expect(shared_with_groups).to contain_exactly(group_link_1.shared_with_group_id, group_link_2.shared_with_group_id)
        end
      end

      context 'when unauthenticated' do
        it 'returns only public groups that share the group', :aggregate_failures do
          get api("/groups/#{shared_group.id}")

          expect(response).to have_gitlab_http_status(:ok)
          expect(shared_with_groups).to contain_exactly(group_link_1.shared_with_group_id)
        end
      end

      context 'when authenticated as a member of a parent group that has shared the group' do
        it 'returns private group if direct member', :aggregate_failures do
          group2_sub.add_guest(user3)

          get api("/groups/#{shared_group.id}", user3)

          expect(response).to have_gitlab_http_status(:ok)
          expect(shared_with_groups).to contain_exactly(group_link_1.shared_with_group_id, group_link_2.shared_with_group_id)
        end

        it 'returns private group if inherited member', :aggregate_failures do
          inherited_guest_member = create(:user)
          group2.add_guest(inherited_guest_member)

          get api("/groups/#{shared_group.id}", inherited_guest_member)

          expect(response).to have_gitlab_http_status(:ok)
          expect(shared_with_groups).to contain_exactly(group_link_1.shared_with_group_id, group_link_2.shared_with_group_id)
        end
      end

      context "expose shared_runners_setting attribute" do
        let(:group) { create(:group, shared_runners_enabled: true) }

        before do
          group.add_owner(user1)
        end

        it "returns the group with shared_runners_setting as 'enabled'", :aggregate_failures do
          get api("/groups/#{group.id}", user1)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['shared_runners_setting']).to eq("enabled")
        end

        it "returns the group with shared_runners_setting as 'disabled_and_unoverridable'", :aggregate_failures do
          group.update!(shared_runners_enabled: false, allow_descendants_override_disabled_shared_runners: false)

          get api("/groups/#{group.id}", user1)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['shared_runners_setting']).to eq("disabled_and_unoverridable")
        end

        it "returns the group with shared_runners_setting as 'disabled_and_overridable'", :aggregate_failures do
          group.update!(shared_runners_enabled: false, allow_descendants_override_disabled_shared_runners: true)

          get api("/groups/#{group.id}", user1)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['shared_runners_setting']).to eq("disabled_and_overridable")
        end
      end
    end
  end

  describe 'PUT /groups/:id' do
    let(:new_group_name) { 'New Group' }
    let(:file_path) { 'spec/fixtures/dk.png' }

    it_behaves_like 'group avatar upload' do
      def make_upload_request
        group_param = {
          avatar: fixture_file_upload(file_path)
        }
        workhorse_form_with_file(
          api("/groups/#{group1.id}", user1),
          method: :put,
          file_key: :avatar,
          params: group_param
        )
      end
    end

    before do
      stub_application_setting(update_namespace_name_rate_limit: 1)
    end

    it 'increments the update_namespace_name rate limit' do
      put api("/groups/#{group1.id}", user1), params: { name: "#{new_group_name}_1" }

      expect(::Gitlab::ApplicationRateLimiter.peek(:update_namespace_name, scope: group1)).to be_falsey

      put api("/groups/#{group1.id}", user1), params: { name: "#{new_group_name}_2" }

      expect(::Gitlab::ApplicationRateLimiter.peek(:update_namespace_name, scope: group1)).to be_truthy
      expect(response).to have_gitlab_http_status(:ok)
      expect(group1.reload.name).to eq("#{new_group_name}_2")
    end

    it 'updates the max_artifacts_size for admin users' do
      expect(group1.max_artifacts_size).to be_nil

      put api("/groups/#{group1.id}", admin, admin_mode: true), params: { max_artifacts_size: 1 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(group1.reload.max_artifacts_size).to eq(1)
      expect(json_response['max_artifacts_size']).to eq(1)
    end

    it 'does not update the max_artifacts_size for non admin users' do
      put api("/groups/#{group1.id}", user1), params: { max_artifacts_size: 1 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(group1.reload.max_artifacts_size).not_to eq(1)
      expect(json_response['max_artifacts_size']).not_to eq(1)
    end

    context 'a name is not passed in' do
      it 'does not mark name update throttling' do
        expect(::Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)

        put api("/groups/#{group1.id}", user1), params: { path: 'another/path' }
      end
    end

    context 'an empty name is passed in' do
      it 'does not mark name update throttling' do
        expect(::Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)

        put api("/groups/#{group1.id}", user1), params: { name: '' }
      end
    end

    context 'when authenticated as the group owner' do
      it 'updates the group', :aggregate_failures do
        workhorse_form_with_file(
          api("/groups/#{group1.id}", user1),
          method: :put,
          file_key: :avatar,
          params: {
            name: new_group_name,
            request_access_enabled: true,
            project_creation_level: "noone",
            subgroup_creation_level: "maintainer",
            default_branch_protection: ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS,
            default_branch_protection_defaults: ::Gitlab::Access::BranchProtection.protected_after_initial_push.stringify_keys,
            prevent_sharing_groups_outside_hierarchy: true,
            avatar: fixture_file_upload(file_path),
            math_rendering_limits_enabled: false,
            lock_math_rendering_limits_enabled: true
          }
        )

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(new_group_name)
        expect(json_response['description']).to eq('')
        expect(json_response['visibility']).to eq('public')
        expect(json_response['share_with_group_lock']).to eq(false)
        expect(json_response['require_two_factor_authentication']).to eq(false)
        expect(json_response['two_factor_grace_period']).to eq(48)
        expect(json_response['auto_devops_enabled']).to eq(nil)
        expect(json_response['emails_disabled']).to eq(false)
        expect(json_response['emails_enabled']).to eq(true)
        expect(json_response['mentions_disabled']).to eq(nil)
        expect(json_response['project_creation_level']).to eq("noone")
        expect(json_response['subgroup_creation_level']).to eq("maintainer")
        expect(json_response['request_access_enabled']).to eq(true)
        expect(json_response['parent_id']).to eq(nil)
        expect(json_response['created_at']).to be_present
        expect(json_response['projects']).to be_an Array
        expect(json_response['projects'].length).to eq(3)
        expect(json_response['shared_projects']).to be_an Array
        expect(json_response['shared_projects'].length).to eq(0)
        expect(json_response['default_branch_protection']).to eq(::Gitlab::Access::MAINTAINER_PROJECT_ACCESS)
        expect(json_response['default_branch_protection_defaults']).to eq(::Gitlab::Access::BranchProtection.protected_after_initial_push.stringify_keys)
        expect(json_response['avatar_url']).to end_with('dk.png')
        expect(json_response['math_rendering_limits_enabled']).to eq(false)
        expect(json_response['lock_math_rendering_limits_enabled']).to eq(true)
      end

      context 'when updating :emails_disabled' do
        context 'when setting to true' do
          it 'sets :emails_enabled to false' do
            put api("/groups/#{group1.id}", user1), params: { emails_disabled: true }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['emails_enabled']).to eq(false)
          end
        end

        context 'when setting to nil' do
          it 'sets :emails_enabled to default true' do
            put api("/groups/#{group1.id}", user1), params: { emails_disabled: nil }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['emails_enabled']).to eq(true)
          end
        end

        context 'when setting to string "true"' do
          it 'sets :emails_enabled to false' do
            put api("/groups/#{group1.id}", user1), params: { emails_disabled: "true" }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['emails_enabled']).to eq(false)
          end
        end
      end

      context 'when default_branch_protection_defaults set to No one' do
        it 'updates default branch protection settings for the group' do
          put api("/groups/#{group1.id}", user1),
            params: {
              default_branch_protection_defaults: {
                allowed_to_push: [{ access_level: 0 }],
                allowed_to_merge: [{ access_level: 0 }]
              }
            }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['default_branch_protection_defaults']).to eq(
            "allowed_to_merge" => [{ "access_level" => 0 }],
            "allowed_to_push" => [{ "access_level" => 0 }]
          )
        end
      end

      it 'removes the group avatar', :aggregate_failures do
        put api("/groups/#{group1.id}", user1), params: { avatar: '' }

        aggregate_failures "testing response" do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['avatar_url']).to be_nil
          expect(group1.reload.avatar_url).to be_nil
        end
      end

      it 'does not update visibility_level if it is restricted', :aggregate_failures do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::INTERNAL])

        put api("/groups/#{group1.id}", user1), params: { visibility: 'internal' }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['visibility_level']).to include('internal has been restricted by your GitLab administrator')
      end

      context 'updating the `default_branch` attribute' do
        subject do
          put api("/groups/#{group1.id}", user1), params: { default_branch: default_branch }
        end

        let(:default_branch) { 'new' }

        it 'updates the attribute', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['default_branch']).to eq(default_branch)
        end

        context 'when "default_branch" attribute is removed' do
          before do
            group1.namespace_settings.update!(default_branch_name: 'new')
          end

          let(:default_branch) { '' }

          it 'removes the attribute', :aggregate_failures do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['default_branch']).to be_nil
          end
        end
      end

      context 'updating the `default_branch_protection` attribute' do
        subject do
          put api("/groups/#{group1.id}", user1), params: { default_branch_protection: ::Gitlab::Access::PROTECTION_NONE }
        end

        context 'for users who have the ability to update default_branch_protection' do
          it 'updates the attribute', :aggregate_failures do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['default_branch_protection']).to eq(Gitlab::Access::PROTECTION_NONE)
          end
        end

        context 'for users who does not have the ability to update default_branch_protection`' do
          it 'does not update the attribute', :aggregate_failures do
            allow(Ability).to receive(:allowed?).and_call_original
            allow(Ability).to receive(:allowed?).with(user1, :update_default_branch_protection, group1) { false }

            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['default_branch_protection']).not_to eq(Gitlab::Access::PROTECTION_NONE)
          end
        end
      end

      context 'updating the `enabled_git_access_protocol` attribute' do
        %w[ssh http all].each do |protocol|
          context "with #{protocol}" do
            subject do
              put api("/groups/#{group1.id}", user1), params: { enabled_git_access_protocol: protocol }
            end

            it 'updates the attribute', :aggregate_failures do
              subject

              expect(response).to have_gitlab_http_status(:ok)
              expect(json_response['enabled_git_access_protocol']).to eq(protocol)
            end
          end
        end
      end

      context 'malicious group name' do
        subject { put api("/groups/#{group1.id}", user1), params: { name: "<SCRIPT>alert('DOUBLE-ATTACK!')</SCRIPT>" } }

        it 'returns bad request' do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
        end

        it 'does not update group name' do
          expect { subject }.not_to change { group1.reload.name }
        end
      end

      it 'returns 404 for a non existing group' do
        put api("/groups/#{non_existing_record_id}", user1), params: { name: new_group_name }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'within a subgroup' do
        let(:group3) { create(:group, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
        let!(:subgroup) { create(:group, parent: group3, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }

        before do
          group3.add_owner(user3)
        end

        it 'does not change visibility when not requested', :aggregate_failures do
          put api("/groups/#{group3.id}", user3), params: { description: 'Bug #23083' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['visibility']).to eq('public')
        end

        it 'prevents making private a group containing public subgroups', :aggregate_failures do
          put api("/groups/#{group3.id}", user3), params: { visibility: 'private' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['visibility_level']).to contain_exactly('private is not allowed since there are sub-groups with higher visibility.')
        end

        it 'does not update prevent_sharing_groups_outside_hierarchy', :aggregate_failures do
          put api("/groups/#{subgroup.id}", user3), params: { description: 'it works', prevent_sharing_groups_outside_hierarchy: true }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.keys).not_to include('prevent_sharing_groups_outside_hierarchy')
          expect(subgroup.reload.prevent_sharing_groups_outside_hierarchy).to eq(false)
          expect(json_response['description']).to eq('it works')
        end
      end

      context 'update path with existing pages unique domain' do
        before do
          stub_pages_setting(enabled: true)

          create(
            :project_setting,
            project: project1,
            pages_unique_domain_enabled: true,
            pages_unique_domain: 'existing-domain')
        end

        it "returns 400 bad request error" do
          put api("/groups/#{group1.id}", user1), params: { path: 'existing-domain' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq({ "path" => ["has already been taken"] })
        end
      end
    end

    context 'when authenticated as the admin' do
      it 'updates the group', :aggregate_failures do
        put api("/groups/#{group1.id}", admin, admin_mode: true), params: { name: new_group_name }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(new_group_name)
      end

      it 'ignores visibility level restrictions', :aggregate_failures do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::INTERNAL])

        put api("/groups/#{group1.id}", admin, admin_mode: true), params: { visibility: 'internal' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['visibility']).to eq('internal')
      end
    end

    context 'when authenticated as an user that can see the group' do
      it 'does not updates the group' do
        put api("/groups/#{group1.id}", user2), params: { name: new_group_name }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as an user that cannot see the group' do
      it 'returns 404 when trying to update the group' do
        put api("/groups/#{group2.id}", user1), params: { name: new_group_name }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "GET /groups/:id/projects" do
    it_behaves_like 'rate limited endpoint', rate_limit_key: :group_projects_api do
      def request
        get api("/groups/#{group1.id}/projects")
      end
    end

    context 'when rate_limit_groups_and_projects_api feature flag is disabled' do
      before do
        stub_feature_flags(rate_limit_groups_and_projects_api: false)
      end

      it_behaves_like 'unthrottled endpoint'

      def request
        get api("/groups/#{group1.id}/projects")
      end
    end

    context "when authenticated as user" do
      context 'with min access level' do
        it 'returns projects with min access level or higher' do
          expect_log_keys(caller_id: "GET /api/:version/groups/:id/projects",
            route: "/api/:version/groups/:id/projects",
            root_namespace: group1.path)

          group_guest = create(:user)
          group1.add_guest(group_guest)
          project4 = create(:project, group: group1)
          project1.add_guest(group_guest)
          project3.add_reporter(group_guest)
          project4.add_developer(group_guest)

          get api("/groups/#{group1.id}/projects", group_guest), params: { min_access_level: Gitlab::Access::REPORTER }

          project_ids = json_response.map { |proj| proj['id'] }
          expect(project_ids).to match_array([project3.id, project4.id])
        end
      end

      context 'with owned' do
        let_it_be(:group) { create(:group) }

        let_it_be(:project1) { create(:project, group: group) }
        let_it_be(:project1_guest) { create(:user) }
        let_it_be(:project1_owner) { create(:user) }
        let_it_be(:project1_maintainer) { create(:user) }

        let_it_be(:project2) { create(:project, group: group) }

        before do
          project1.add_guest(project1_guest)
          project1.add_owner(project1_owner)
          project1.add_maintainer(project1_maintainer)

          project2_owner = project1_owner
          project2.add_owner(project2_owner)
        end

        context "as a guest" do
          it 'returns no projects' do
            get api("/groups/#{group.id}/projects", project1_guest), params: { owned: true }
            project_ids = json_response.map { |proj| proj['id'] }
            expect(project_ids).to be_empty
          end
        end

        context "as a maintainer" do
          it 'returns no projects' do
            get api("/groups/#{group.id}/projects", project1_maintainer), params: { owned: true }
            project_ids = json_response.map { |proj| proj['id'] }
            expect(project_ids).to be_empty
          end
        end

        context "as an owner" do
          it 'returns projects with owner access level' do
            get api("/groups/#{group.id}/projects", project1_owner), params: { owned: true }
            project_ids = json_response.map { |proj| proj['id'] }
            expect(project_ids).to match_array([project1.id, project2.id])
          end
        end
      end

      it "returns the group's projects", :aggregate_failures do
        get api("/groups/#{group1.id}/projects", user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(3)
        project_names = json_response.map { |proj| proj['name'] }
        expect(project_names).to match_array([project1.name, project3.name, archived_project.name])
        expect(json_response.first['visibility']).to be_present
      end

      context 'and using archived' do
        it "returns the group's archived projects", :aggregate_failures do
          get api("/groups/#{group1.id}/projects?archived=true", user1)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(Project.public_or_visible_to_user(user1).where(archived: true).size)
          expect(json_response.map { |project| project['id'] }).to include(archived_project.id)
        end

        it "returns the group's non-archived projects", :aggregate_failures do
          get api("/groups/#{group1.id}/projects?archived=false", user1)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(Project.public_or_visible_to_user(user1).where(archived: false).size)
          expect(json_response.map { |project| project['id'] }).not_to include(archived_project.id)
        end

        it "returns all of the group's projects", :aggregate_failures do
          get api("/groups/#{group1.id}/projects", user1)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |project| project['id'] }).to contain_exactly(*Project.public_or_visible_to_user(user1).pluck(:id))
        end
      end

      context 'with similarity ordering' do
        let_it_be(:group_with_projects) { create(:group) }
        let_it_be(:project_1) { create(:project, name: 'Project', path: 'project', group: group_with_projects) }
        let_it_be(:project_2) { create(:project, name: 'Test Project', path: 'test-project', group: group_with_projects) }
        let_it_be(:project_3) { create(:project, name: 'Test', path: 'test', group: group_with_projects) }

        let(:params) { { order_by: 'similarity', search: 'test' } }

        subject { get api("/groups/#{group_with_projects.id}/projects", user1), params: params }

        before do
          group_with_projects.add_owner(user1)
        end

        it 'returns items based ordered by similarity', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response.length).to eq(2)

          project_names = json_response.map { |proj| proj['name'] }
          expect(project_names).to eq(['Test', 'Test Project'])
        end

        context 'when `search` parameter is not given' do
          before do
            params.delete(:search)
          end

          it 'returns items ordered by name', :aggregate_failures do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response.length).to eq(3)

            project_names = json_response.map { |proj| proj['name'] }
            expect(project_names).to eq(['Project', 'Test', 'Test Project'])
          end
        end
      end

      context 'with star_count ordering' do
        let_it_be(:group_with_projects) { create(:group) }
        let_it_be(:project_1) { create(:project, name: 'Project Test', path: 'project-test', group: group_with_projects) }
        let_it_be(:project_2) { create(:project, name: 'Test Project', path: 'test-project', group: group_with_projects, star_count: 10) }
        let_it_be(:project_3) { create(:project, name: 'Test', path: 'test', group: group_with_projects, star_count: 5) }

        let(:params) { { order_by: 'star_count', search: 'test' } }

        subject { get api("/groups/#{group_with_projects.id}/projects", user1), params: params }

        before do
          group_with_projects.add_owner(user1)
        end

        it 'returns items based ordered by star_count', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          filtered_response = json_response.map { |h| h.slice('star_count', 'name') }
          expect(filtered_response).to eq([
            { "star_count" => 10, "name" => "Test Project" },
            { "star_count" => 5, "name" => "Test" },
            { "star_count" => 0, "name" => "Project Test" }
          ])
        end

        it 'returns items based ordered by star_count in ascending order', :aggregate_failures do
          params[:sort] = 'asc'
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          filtered_response = json_response.map { |h| h.slice('star_count', 'name') }
          expect(filtered_response).to eq([
            { "star_count" => 0, "name" => "Project Test" },
            { "star_count" => 5, "name" => "Test" },
            { "star_count" => 10, "name" => "Test Project" }
          ])
        end
      end

      it "returns the group's projects with simple representation", :aggregate_failures do
        get api("/groups/#{group1.id}/projects", user1), params: { simple: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(3)
        project_names = json_response.map { |proj| proj['name'] }
        expect(project_names).to match_array([project1.name, project3.name, archived_project.name])
        expect(json_response.first['visibility']).not_to be_present
      end

      it "filters the groups projects", :aggregate_failures do
        public_project = create(:project, :public, path: 'test1', group: group1)

        get api("/groups/#{group1.id}/projects", user1), params: { visibility: 'public' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(public_project.name)
      end

      it "returns projects excluding shared", :aggregate_failures do
        create(:project_group_link, project: create(:project), group: group1)
        create(:project_group_link, project: create(:project), group: group1)
        create(:project_group_link, project: create(:project), group: group1)

        get api("/groups/#{group1.id}/projects", user1), params: { with_shared: false }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(3)
      end

      context 'when include_subgroups is true' do
        before do
          subgroup = create(:group, parent: group1)
          subgroup2 = create(:group, parent: subgroup)

          create(:project, group: subgroup)
          create(:project, group: subgroup)
          create(:project, group: subgroup2)

          group1.reload
        end

        it "returns projects including those in subgroups", :aggregate_failures do
          get api("/groups/#{group1.id}/projects", user1), params: { include_subgroups: true }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an(Array)
          expect(json_response.length).to eq(6)
        end

        it 'avoids N+1 queries', :aggregate_failures do
          get api("/groups/#{group1.id}/projects", user1), params: { include_subgroups: true } # warm-up

          expect(response).to have_gitlab_http_status(:ok)

          control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
            get api("/groups/#{group1.id}/projects", user1), params: { include_subgroups: true }
          end

          create(:project, :public, namespace: group1)

          # threshold number 2 is the additional number of queries which are getting executed.
          # with this we are allowing some N+1 that may already exist but is not obvious.
          # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132246#note_1581106553
          expect do
            get api("/groups/#{group1.id}/projects", user1), params: { include_subgroups: true }
          end.to issue_same_number_of_queries_as(control).with_threshold(2)
        end
      end

      context 'when include_ancestor_groups is true' do
        it 'returns ancestors groups projects', :aggregate_failures do
          subgroup = create(:group, parent: group1)
          subgroup_project = create(:project, group: subgroup)

          get api("/groups/#{subgroup.id}/projects", user1), params: { include_ancestor_groups: true }

          records = Gitlab::Json.parse(response.body)
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(records.map { |r| r['id'] }).to match_array([project1.id, project3.id, subgroup_project.id, archived_project.id])
        end
      end

      it "does not return a non existing group" do
        get api("/groups/#{non_existing_record_id}/projects", user1)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it "does not return a group not attached to user1" do
        get api("/groups/#{group2.id}/projects", user1)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it "only returns projects to which user has access", :aggregate_failures do
        project3.add_developer(user3)

        get api("/groups/#{group1.id}/projects", user3)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project3.name)
      end

      it 'only returns the projects owned by user', :aggregate_failures do
        project2.group.add_owner(user3)

        get api("/groups/#{project2.group.id}/projects", user3), params: { owned: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project2.name)
      end

      it 'only returns the projects starred by user', :aggregate_failures do
        user1.starred_projects = [project1]

        get api("/groups/#{group1.id}/projects", user1), params: { starred: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project1.name)
      end

      it 'avoids N+1 queries', :aggregate_failures do
        get api("/groups/#{group1.id}/projects", user1)
        expect(response).to have_gitlab_http_status(:ok)

        control = ActiveRecord::QueryRecorder.new do
          get api("/groups/#{group1.id}/projects", user1)
        end

        create(:project, namespace: group1)

        expect do
          get api("/groups/#{group1.id}/projects", user1)
        end.not_to exceed_query_limit(control)
      end
    end

    context "when authenticated as admin" do
      it "returns any existing group", :aggregate_failures do
        get api("/groups/#{group2.id}/projects", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project2.name)
      end

      it "does not return a non existing group" do
        get api("/groups/#{non_existing_record_id}/projects", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when using group path in URL' do
      it 'returns any existing group', :aggregate_failures do
        get api("/groups/#{group1.path}/projects", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        project_names = json_response.map { |proj| proj['name'] }
        expect(project_names).to match_array([project1.name, project3.name, archived_project.name])
      end

      it 'does not return a non existing group' do
        get api('/groups/unknown/projects', admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'does not return a group not attached to user1' do
        get api("/groups/#{group2.path}/projects", user1)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "GET /groups/:id/projects/shared" do
    let!(:project4) do
      create(:project, namespace: group2, name: 'test project', path: 'test_project', visibility_level: Gitlab::VisibilityLevel::PRIVATE, star_count: 5)
    end

    let(:path) { "/groups/#{group1.id}/projects/shared" }

    before do
      create(:project_group_link, project: project2, group: group1)
      create(:project_group_link, project: project4, group: group1)
    end

    context 'when authenticated as user' do
      it 'returns the shared projects in the group', :aggregate_failures do
        get api(path, user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(2)
        project_ids = json_response.map { |project| project['id'] }
        expect(project_ids).to match_array([project2.id, project4.id])
        expect(json_response.first['visibility']).to be_present
      end

      it 'returns shared projects with min access level or higher', :aggregate_failures do
        user = create(:user)

        project2.add_guest(user)
        project4.add_reporter(user)

        get api(path, user), params: { min_access_level: Gitlab::Access::REPORTER }

        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(project4.id)
      end

      it 'returns the shared projects of the group with simple representation', :aggregate_failures do
        get api(path, user1), params: { simple: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(2)
        project_ids = json_response.map { |project| project['id'] }
        expect(project_ids).to match_array([project2.id, project4.id])
        expect(json_response.first['visibility']).not_to be_present
      end

      it 'filters the shared projects in the group based on visibility', :aggregate_failures do
        internal_project = create(:project, :internal, namespace: create(:group))

        create(:project_group_link, project: internal_project, group: group1)

        get api(path, user1), params: { visibility: 'internal' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(internal_project.id)
      end

      it 'filters the shared projects in the group based on search params', :aggregate_failures do
        get api(path, user1), params: { search: 'test_project' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(project4.id)
      end

      it 'returns the shared projects in the group ordered by star count', :aggregate_failures do
        get api(path, user1), params: { order_by: 'star_count', search: 'test' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        filtered_response = json_response.map { |h| h.slice('star_count', 'name') }
        expect(filtered_response).to eq([
          { "star_count" => 5, "name" => "test project" },
          { "star_count" => 0, "name" => "testing" }
        ])
      end

      it 'returns the shared projects in the group ordered by star count in ascending order', :aggregate_failures do
        get api(path, user1), params: { order_by: 'star_count', search: 'test', sort: 'asc' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        filtered_response = json_response.map { |h| h.slice('star_count', 'name') }
        expect(filtered_response).to eq([
          { "star_count" => 0, "name" => "testing" },
          { "star_count" => 5, "name" => "test project" }
        ])
      end

      it 'does not return the projects owned by the group', :aggregate_failures do
        get api(path, user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        project_ids = json_response.map { |project| project['id'] }

        expect(project_ids).not_to include(project1.id)
      end

      it 'returns 404 for a non-existing group' do
        get api("/groups/0000/projects/shared", user1)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'does not return a group not attached to the user' do
        group = create(:group, :private)

        get api("/groups/#{group.id}/projects/shared", user1)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'only returns shared projects to which user has access', :aggregate_failures do
        project4.add_developer(user3)

        get api(path, user3)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(project4.id)
      end

      it 'only returns the projects starred by user', :aggregate_failures do
        user1.starred_projects = [project2]

        get api(path, user1), params: { starred: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(project2.id)
      end
    end

    context "when authenticated as admin" do
      subject { get api(path, admin, admin_mode: true) }

      it "returns shared projects of an existing group", :aggregate_failures do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(2)
        project_ids = json_response.map { |project| project['id'] }
        expect(project_ids).to match_array([project2.id, project4.id])
      end

      context 'for a non-existent group' do
        let(:path) { "/groups/000/projects/shared" }

        it 'returns 404 for a non-existent group' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      it 'avoids N+1 queries', :aggregate_failures, :use_sql_query_cache do
        subject
        expect(response).to have_gitlab_http_status(:ok)

        control = ActiveRecord::QueryRecorder.new do
          subject
        end

        create(:project_group_link, project: create(:project), group: group1)

        expect do
          subject
        end.not_to exceed_query_limit(control)
      end
    end

    context 'when using group path in URL' do
      let(:path) { "/groups/#{group1.path}/projects/shared" }

      it 'returns the right details', :aggregate_failures do
        get api(path, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(2)
        project_ids = json_response.map { |project| project['id'] }
        expect(project_ids).to match_array([project2.id, project4.id])
      end

      it 'returns 404 for a non-existent group' do
        get api('/groups/unknown/projects/shared', admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "GET /groups/:id/groups/shared" do
    let_it_be(:main_group) do
      create(:group, :private, name: "b-group", path: "w#{group1.path}", owners: user1)
    end

    let_it_be(:shared_group1) do
      create(:group, :private, name: "a-group", path: "x#{group1.path}", owners: user1)
    end

    let_it_be(:shared_group2) do
      create(:group, :private, name: "d-group", path: "y#{group1.path}", owners: user1)
    end

    let_it_be(:other_group) { create(:group, :private, name: "c-group", path: "z#{group1.path}", owners: [user1, user2]) }

    let(:path) { "/groups/#{main_group.id}/groups/shared" }

    before do
      create(:group_group_link, shared_group: shared_group1, shared_with_group: main_group)
      create(:group_group_link, shared_group: shared_group2, shared_with_group: main_group)
      create(:group_group_link, shared_group: other_group, shared_with_group: main_group)
    end

    it_behaves_like 'rate limited endpoint', rate_limit_key: :group_shared_groups_api do
      def request
        get api(path)
      end
    end

    context 'when rate_limit_groups_and_projects_api feature flag is disabled' do
      before do
        stub_feature_flags(rate_limit_groups_and_projects_api: false)
      end

      it_behaves_like 'unthrottled endpoint'

      def request
        get api(path)
      end
    end

    context 'when authenticated as user' do
      it 'returns the shared groups in the group', :aggregate_failures do
        expect_log_keys(caller_id: "GET /api/:version/groups/:id/groups/shared",
          route: "/api/:version/groups/:id/groups/shared",
          root_namespace: main_group.path)

        get api(path, user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(3)
        group_ids = json_response.map { |group| group['id'] }
        expect(group_ids).to contain_exactly(shared_group1.id, shared_group2.id, other_group.id)
      end
    end

    context 'when authenticated and user does not have the access' do
      it 'does not return the shared groups in the group', :aggregate_failures do
        get api(path, user2)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when unauthenticated as user' do
      let_it_be(:main_group) { create(:group, :public, owners: user1) }
      let_it_be(:shared_group_1) { create(:group, :public, owners: user1) }
      let_it_be(:shared_group_2) { create(:group, :private, owners: user1) }

      before do
        create(:group_group_link, shared_group: shared_group_1, shared_with_group: main_group)
        create(:group_group_link, shared_group: shared_group_2, shared_with_group: main_group)
      end

      it 'only returns the shared public groups in the group', :aggregate_failures do
        get api(path)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(1)
        group_ids = json_response.map { |group| group['id'] }
        expect(group_ids).to contain_exactly(shared_group_1.id)
      end
    end

    context "when using skip_groups in request" do
      it "returns all shared groups excluding skipped groups", :aggregate_failures do
        get api(path, user1), params: { skip_groups: [shared_group1.id] }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
        expect(json_response.map { |group| group['id'] }).to contain_exactly(shared_group2.id, other_group.id)
      end
    end

    context "when search is present in request" do
      let_it_be(:new_shared_group) { create(:group, :public, name: "new search group", owners: user1) }
      let_it_be(:other_shared_group) { create(:group, :private, name: "other group", owners: user1) }

      before do
        create(:group_group_link, shared_group: new_shared_group, shared_with_group: main_group)
        create(:group_group_link, shared_group: other_shared_group, shared_with_group: main_group)
      end

      it 'filters the shared groups in the group based on search params', :aggregate_failures do
        get api(path, user1), params: { search: 'new' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(new_shared_group.id)
      end
    end

    context 'when using min_access_level in the request' do
      let_it_be(:new_main_group) do
        create(:group, :private, owners: user1)
      end

      let_it_be(:shared_group1) do
        create(:group, :private)
      end

      let_it_be(:shared_group2) do
        create(:group, :private)
      end

      before do
        shared_group1.add_developer(user1)
        shared_group2.add_reporter(user1)
        create(:group_group_link, shared_group: shared_group1, shared_with_group: new_main_group)
        create(:group_group_link, shared_group: shared_group2, shared_with_group: new_main_group)
      end

      context 'with min_access_level parameter' do
        it 'returns an array of groups the user has at least reporter access', :aggregate_failures do
          get api("/groups/#{new_main_group.id}/groups/shared", user1), params: { min_access_level: Gitlab::Access::REPORTER }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |group| group['id'] }).to contain_exactly(shared_group1.id, shared_group2.id)
        end
      end
    end

    context "when using sorting" do
      let(:response_groups) { json_response.map { |group| group['name'] } }
      let(:response_group_paths) { json_response.map { |group| group['path'] } }
      let(:response_group_ids) { json_response.map { |group| group['id'] } }
      let(:shared_group_names) { [shared_group1.name, shared_group2.name, other_group.name] }
      let(:shared_group_paths) { [shared_group1.path, shared_group2.path, other_group.path] }
      let(:shared_group_ids) { [shared_group1.id, shared_group2.id, other_group.id] }

      it "sorts by name ascending by default", :aggregate_failures do
        get api(path, user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(3)
        expect(json_response).to be_an Array
        expect(response_groups).to eq(shared_group_names.sort)
      end

      it "sorts in descending order when passed", :aggregate_failures do
        get api(path, user1), params: { sort: "desc" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(3)
        expect(json_response).to be_an Array
        expect(response_groups).to eq(shared_group_names.sort.reverse)
      end

      it "sorts by path in order_by param", :aggregate_failures do
        get api(path, user1), params: { order_by: "path" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_group_paths).to eq(shared_group_paths.sort)
      end

      it "sorts by id in the order_by param", :aggregate_failures do
        get api(path, user1), params: { order_by: "id" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_group_ids).to eq(shared_group_ids.sort)
      end
    end

    context 'when searching with similarity ordering', :aggregate_failures do
      let_it_be(:user2) { create(:user) }
      let_it_be(:main_group_2) { create(:group, name: 'same-name main', owners: user2) }
      let_it_be(:shared_group1) { create(:group, name: 'same-name shared', owners: user2) }
      let_it_be(:shared_group2) { create(:group, name: 'same-name shared_other', owners: user2) }
      let_it_be(:shared_group3) { create(:group, name: 'other-name', owners: user2) }

      let(:response_groups) { json_response.map { |group| group['name'] } }
      let(:shared_group_names) { [shared_group1.name, shared_group2.name, shared_group3.name] }
      let(:params) { { order_by: 'similarity', search: 'same-name' } }

      before do
        create(:group_group_link, shared_group: shared_group1, shared_with_group: main_group_2)
        create(:group_group_link, shared_group: shared_group2, shared_with_group: main_group_2)
        create(:group_group_link, shared_group: shared_group3, shared_with_group: main_group_2)
      end

      subject { get api("/groups/#{main_group_2.id}/groups/shared", user2), params: params }

      it 'sorts shared groups with exact matches first', :aggregate_failures do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(2)
        expect(response_groups).to eq(['same-name shared', 'same-name shared_other'])
      end

      context 'when `search` parameter is not given' do
        let(:params) { { order_by: 'similarity' } }

        it 'sorts items ordered by name', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response.length).to eq(3)
          expect(response_groups).to eq(shared_group_names.sort)
        end
      end
    end

    context 'when using visibility filter', :aggregate_failures do
      let_it_be(:user3) { create(:user) }
      let_it_be(:main_group_3) { create(:group, :private, owners: user3) }
      let_it_be(:shared_group1) { create(:group, :public, owners: user3) }
      let_it_be(:shared_group2) { create(:group, :internal, owners: user3) }
      let_it_be(:shared_group3) { create(:group, :private, owners: user3) }

      let(:response_groups) { json_response.map { |group| group['id'] } }

      before do
        create(:group_group_link, shared_group: shared_group1, shared_with_group: main_group_3)
        create(:group_group_link, shared_group: shared_group2, shared_with_group: main_group_3)
        create(:group_group_link, shared_group: shared_group3, shared_with_group: main_group_3)
      end

      it 'filters based on private visibility param' do
        get api("/groups/#{main_group_3.id}/groups/shared", user3), params: { visibility: 'private' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to contain_exactly(shared_group3.id)
      end

      it 'filters based on internal visibility param' do
        get api("/groups/#{main_group_3.id}/groups/shared", user3), params: { visibility: 'internal' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to contain_exactly(shared_group2.id)
      end

      it 'filters based on public visibility param' do
        get api("/groups/#{main_group_3.id}/groups/shared", user3), params: { visibility: 'public' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to contain_exactly(shared_group1.id)
      end

      it 'filters based on no visibility param passed' do
        get api("/groups/#{main_group_3.id}/groups/shared", user3)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to contain_exactly(shared_group1.id, shared_group2.id, shared_group3.id)
      end

      it 'filters based on unknown visibility param' do
        get api("/groups/#{main_group_3.id}/groups/shared", user3), params: { visibility: 'something' }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('visibility does not have a valid value')
      end
    end
  end

  describe "GET /groups/:id/invited_groups" do
    let_it_be(:main_group) do
      create(:group, :private, name: "b-group", path: "w#{group1.path}", owners: user1)
    end

    let_it_be(:shared_group1) do
      create(:group, :private, name: "a-group", path: "x#{group1.path}", owners: user1)
    end

    let_it_be(:shared_group2) do
      create(:group, :private, name: "d-group", path: "y#{group1.path}", owners: user1)
    end

    let_it_be(:other_group) { create(:group, :private, name: "c-group", path: "z#{group1.path}", owners: user1) }

    let(:path) { "/groups/#{main_group.id}/invited_groups" }

    before do
      create(:group_group_link, shared_group: main_group, shared_with_group: shared_group1)
      create(:group_group_link, shared_group: main_group, shared_with_group: shared_group2)
      create(:group_group_link, shared_group: main_group, shared_with_group: other_group)
    end

    it_behaves_like 'rate limited endpoint', rate_limit_key: :group_invited_groups_api do
      def request
        get api(path)
      end
    end

    context 'when authenticated as user' do
      it 'returns the invited groups in the group', :aggregate_failures do
        expect_log_keys(caller_id: "GET /api/:version/groups/:id/invited_groups",
          route: "/api/:version/groups/:id/invited_groups",
          root_namespace: main_group.path)

        get api(path, user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(3)
        group_ids = json_response.map { |group| group['id'] }
        expect(group_ids).to contain_exactly(shared_group1.id, shared_group2.id, other_group.id)
      end
    end

    context 'when authenticated and user does not have the access' do
      it 'does not return the invited groups in the group', :aggregate_failures do
        get api(path, user2)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when unauthenticated as user' do
      let_it_be(:main_group) { create(:group, :public, owners: user1) }
      let_it_be(:shared_group_1) { create(:group, :public, owners: user1) }
      let_it_be(:shared_group_2) { create(:group, :private, owners: user1) }

      before do
        create(:group_group_link, shared_group: main_group, shared_with_group: shared_group_1)
        create(:group_group_link, shared_group: main_group, shared_with_group: shared_group_2)
      end

      it 'only returns the invited public groups in the group', :aggregate_failures do
        get api(path)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(1)
        group_ids = json_response.map { |group| group['id'] }
        expect(group_ids).to contain_exactly(shared_group_1.id)
      end
    end

    context "when search is present in request" do
      let_it_be(:new_shared_group) { create(:group, :public, name: "new search group", owners: user1) }
      let_it_be(:other_shared_group) { create(:group, :private, name: "other group", owners: user1) }

      before do
        create(:group_group_link, shared_group: main_group, shared_with_group: new_shared_group)
        create(:group_group_link, shared_group: main_group, shared_with_group: other_shared_group)
      end

      it 'filters the invited groups in the group based on search params', :aggregate_failures do
        get api(path, user1), params: { search: 'new' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(new_shared_group.id)
      end
    end

    context 'when using min_access_level in the request' do
      let_it_be(:new_main_group) do
        create(:group, :private, owners: user1)
      end

      let_it_be(:shared_group1) do
        create(:group, :private)
      end

      let_it_be(:shared_group2) do
        create(:group, :private)
      end

      before do
        shared_group1.add_developer(user1)
        shared_group2.add_reporter(user1)
        create(:group_group_link, shared_group: new_main_group, shared_with_group: shared_group1)
        create(:group_group_link, shared_group: new_main_group, shared_with_group: shared_group2)
      end

      context 'with min_access_level parameter' do
        it 'returns an array of groups the user has at least reporter access', :aggregate_failures do
          get api("/groups/#{new_main_group.id}/invited_groups", user1), params: { min_access_level: Gitlab::Access::REPORTER }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |group| group['id'] }).to contain_exactly(shared_group1.id, shared_group2.id)
        end
      end
    end

    context "when include_relation is present in request" do
      let_it_be(:relation_main_group) do
        create(:group, :private, owners: user1)
      end

      let_it_be(:new_shared_group) { create(:group, :public, name: "new search group", owners: user1) }
      let_it_be(:other_shared_group) { create(:group, :private, name: "other group", owners: user1) }

      before do
        create(:group_group_link, shared_group: relation_main_group, shared_with_group: new_shared_group)
        create(:group_group_link, shared_group: relation_main_group, shared_with_group: other_shared_group)
      end

      it 'filters the invited groups in the group based on relation params', :aggregate_failures do
        get api("/groups/#{relation_main_group.id}/invited_groups", user1), params: { relation: ['direct'] }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.map { |group| group['id'] }).to contain_exactly(new_shared_group.id, other_shared_group.id)
      end

      it 'returns error message when include relation is invalid' do
        get api("/groups/#{relation_main_group.id}/invited_groups", user1), params: { relation: ['some random'] }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq("relation does not have a valid value")
      end
    end
  end

  describe 'GET /groups/:id/subgroups' do
    let!(:subgroup1) { create(:group, parent: group1) }
    let!(:subgroup2) { create(:group, :private, parent: group1) }
    let!(:subgroup3) { create(:group, :private, parent: group2) }

    context 'when unauthenticated' do
      it 'returns only public subgroups', :aggregate_failures do
        get api("/groups/#{group1.id}/subgroups")

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(subgroup1.id)
        expect(json_response.first['parent_id']).to eq(group1.id)
      end

      it 'returns 404 for a private group' do
        get api("/groups/#{group2.id}/subgroups")

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when statistics are requested' do
        it 'does not include statistics', :aggregate_failures do
          get api("/groups/#{group1.id}/subgroups"), params: { statistics: true }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.first).not_to include 'statistics'
        end
      end
    end

    context 'when authenticated as user' do
      context 'when user is not member of a public group' do
        it 'returns no subgroups for the public group', :aggregate_failures do
          expect_log_keys(caller_id: "GET /api/:version/groups/:id/subgroups",
            route: "/api/:version/groups/:id/subgroups",
            root_namespace: group1.path)

          get api("/groups/#{group1.id}/subgroups", user2)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(0)
        end

        context 'when using all_available in request' do
          it 'returns public subgroups', :aggregate_failures do
            get api("/groups/#{group1.id}/subgroups", user2), params: { all_available: true }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to be_an Array
            expect(json_response.length).to eq(1)
            expect(json_response[0]['id']).to eq(subgroup1.id)
            expect(json_response[0]['parent_id']).to eq(group1.id)
          end
        end
      end

      context 'when user is not member of a private group' do
        it 'returns 404 for the private group' do
          get api("/groups/#{group2.id}/subgroups", user1)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when user is member of public group' do
        before do
          group1.add_guest(user2)
        end

        it 'returns private subgroups', :aggregate_failures do
          get api("/groups/#{group1.id}/subgroups", user2)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(2)
          private_subgroups = json_response.select { |group| group['visibility'] == 'private' }
          expect(private_subgroups.length).to eq(1)
          expect(private_subgroups.first['id']).to eq(subgroup2.id)
          expect(private_subgroups.first['parent_id']).to eq(group1.id)
        end

        context 'when using statistics in request' do
          it 'does not include statistics', :aggregate_failures do
            get api("/groups/#{group1.id}/subgroups", user2), params: { statistics: true }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to be_an Array
            expect(json_response.first).not_to include 'statistics'
          end
        end
      end

      context 'when user is member of private group' do
        before do
          group2.add_guest(user1)
        end

        it 'returns subgroups', :aggregate_failures do
          get api("/groups/#{group2.id}/subgroups", user1)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(1)
          expect(json_response.first['id']).to eq(subgroup3.id)
          expect(json_response.first['parent_id']).to eq(group2.id)
        end
      end
    end

    context 'when authenticated as admin' do
      it 'returns private subgroups of a public group', :aggregate_failures do
        get api("/groups/#{group1.id}/subgroups", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
      end

      it 'returns subgroups of a private group', :aggregate_failures do
        get api("/groups/#{group2.id}/subgroups", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
      end

      it 'does not include statistics by default', :aggregate_failures do
        get api("/groups/#{group1.id}/subgroups", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include('statistics')
      end

      it 'includes statistics if requested', :aggregate_failures do
        get api("/groups/#{group1.id}/subgroups", admin, admin_mode: true), params: { statistics: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.first).to include('statistics')
      end

      it_behaves_like 'includes statistics when all_available is false' do
        let(:api_endpoint) { "/groups/#{group1.id}/subgroups" }
      end
    end

    it_behaves_like 'skips searching in full path' do
      let(:parent) { group1 }
      let(:endpoint) { api("/groups/#{group1.id}/subgroups", user1) }
    end
  end

  describe 'GET /groups/:id/descendant_groups' do
    let_it_be(:child_group1) { create(:group, parent: group1) }
    let_it_be(:private_child_group1) { create(:group, :private, parent: group1) }
    let_it_be(:sub_child_group1) { create(:group, parent: child_group1) }
    let_it_be(:child_group2) { create(:group, :private, parent: group2) }
    let_it_be(:sub_child_group2) { create(:group, :private, parent: child_group2) }

    let(:response_groups) { json_response.map { |group| group['name'] } }

    context 'when unauthenticated' do
      it 'returns only public descendants', :aggregate_failures do
        get api("/groups/#{group1.id}/descendant_groups")

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
        expect(response_groups).to contain_exactly(child_group1.name, sub_child_group1.name)
      end

      it 'returns 404 for a private group' do
        get api("/groups/#{group2.id}/descendant_groups")

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when authenticated as user' do
      context 'when user is not member of a public group' do
        it 'returns no descendants for the public group', :aggregate_failures do
          get api("/groups/#{group1.id}/descendant_groups", user2)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(0)
        end

        context 'when using all_available in request' do
          it 'returns public descendants', :aggregate_failures do
            get api("/groups/#{group1.id}/descendant_groups", user2), params: { all_available: true }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to be_an Array
            expect(json_response.length).to eq(2)
            expect(response_groups).to contain_exactly(child_group1.name, sub_child_group1.name)
          end
        end
      end

      context 'when user is not member of a private group' do
        it 'returns 404 for the private group' do
          get api("/groups/#{group2.id}/descendant_groups", user1)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when user is member of public group' do
        before do
          group1.add_guest(user2)
        end

        it 'returns private descendants', :aggregate_failures do
          get api("/groups/#{group1.id}/descendant_groups", user2)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(3)
          expect(response_groups).to contain_exactly(child_group1.name, sub_child_group1.name, private_child_group1.name)
        end

        context 'when using statistics in request' do
          it 'does not include statistics', :aggregate_failures do
            get api("/groups/#{group1.id}/descendant_groups", user2), params: { statistics: true }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to be_an Array
            expect(json_response.first).not_to include 'statistics'
          end
        end
      end

      context 'when user is member of private group' do
        before do
          group2.add_guest(user1)
        end

        it 'returns descendants', :aggregate_failures do
          get api("/groups/#{group2.id}/descendant_groups", user1)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(2)
          expect(response_groups).to contain_exactly(child_group2.name, sub_child_group2.name)
        end
      end
    end

    context 'when authenticated as admin' do
      it 'returns private descendants of a public group', :aggregate_failures do
        get api("/groups/#{group1.id}/descendant_groups", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(3)
      end

      it 'returns descendants of a private group', :aggregate_failures do
        get api("/groups/#{group2.id}/descendant_groups", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
      end

      it 'does not include statistics by default', :aggregate_failures do
        get api("/groups/#{group1.id}/descendant_groups", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include('statistics')
      end

      it 'includes statistics if requested', :aggregate_failures do
        get api("/groups/#{group1.id}/descendant_groups", admin, admin_mode: true), params: { statistics: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.first).to include('statistics')
      end

      it_behaves_like 'includes statistics when all_available is false' do
        let(:api_endpoint) { "/groups/#{group1.id}/descendant_groups" }
      end
    end

    it_behaves_like 'skips searching in full path' do
      let(:parent) { group1 }
      let(:endpoint) { api("/groups/#{group1.id}/descendant_groups", user1) }
    end
  end

  describe "POST /groups" do
    it_behaves_like 'group avatar upload' do
      def make_upload_request
        params = attributes_for_group_api(request_access_enabled: false).tap do |attrs|
          attrs[:avatar] = fixture_file_upload(file_path)
        end

        workhorse_form_with_file(
          api('/groups', user3),
          method: :post,
          file_key: :avatar,
          params: params
        )
      end
    end

    context "when authenticated as user without group permissions" do
      it "does not create group" do
        group = attributes_for_group_api

        post api("/groups", user1), params: group

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      context 'as owner' do
        before do
          group2.add_owner(user1)
        end

        it 'can create subgroups' do
          post api("/groups", user1), params: { parent_id: group2.id, name: 'foo', path: 'foo' }

          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context 'as maintainer' do
        before do
          group2.add_maintainer(user1)
        end

        it 'can create subgroups' do
          post api("/groups", user1), params: { parent_id: group2.id, name: 'foo', path: 'foo' }

          expect(response).to have_gitlab_http_status(:created)
        end
      end
    end

    context 'when group is within a provided organization' do
      let_it_be(:organization) { create(:organization) }

      context 'when user is an organization user' do
        before_all do
          create(:organization_user, user: user3, organization: organization)
        end

        context 'and organization_id is not passed' do
          context 'and current_organization is set' do
            it 'uses current_organization' do
              post api('/groups', user3), params: attributes_for_group_api

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response['organization_id']).to eq(current_organization.id)
            end
          end
        end

        context 'and organization_id is passed' do
          it 'creates group within organization' do
            post api('/groups', user3), params: attributes_for_group_api(organization_id: organization.id)

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['organization_id']).to eq(organization.id)
          end

          context 'when parent_group is not part of the organization' do
            it 'does not create the group with not_found' do
              post(
                api('/groups', user3),
                params: attributes_for_group_api(parent_id: group2.id, organization_id: organization.id)
              )

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end
      end

      context 'when organization does not exist' do
        it 'does not create the group with not_found' do
          post api('/groups', user3), params: attributes_for_group_api(organization_id: non_existing_record_id)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when user is not an organization user' do
        context 'when organization is public' do
          let_it_be(:organization) { create(:organization, :public) }

          it 'does not create the group' do
            post api('/groups', user3), params: attributes_for_group_api(organization_id: organization.id)

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when organization is private' do
          let_it_be(:organization) { create(:organization, :private) }

          it 'does not create the group' do
            post api('/groups', user3), params: attributes_for_group_api(organization_id: organization.id)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when user is an admin' do
        it 'creates group within organization' do
          post api('/groups', admin, admin_mode: true), params: attributes_for_group_api(organization_id: organization.id)

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['organization_id']).to eq(organization.id)
        end
      end
    end

    context "when authenticated as user with group permissions" do
      it "creates group", :aggregate_failures do
        group = attributes_for_group_api request_access_enabled: false

        post api("/groups", user3), params: group

        expect(response).to have_gitlab_http_status(:created)

        expect(json_response["name"]).to eq(group[:name])
        expect(json_response["path"]).to eq(group[:path])
        expect(json_response["request_access_enabled"]).to eq(group[:request_access_enabled])
        expect(json_response["visibility"]).to eq(Gitlab::VisibilityLevel.string_level(Gitlab::CurrentSettings.current_application_settings.default_group_visibility))
      end

      it "creates a nested group", :aggregate_failures do
        parent = create(:group, organization: current_organization)
        parent.add_owner(user3)
        group = attributes_for_group_api parent_id: parent.id

        post api("/groups", user3), params: group

        expect(response).to have_gitlab_http_status(:created)

        expect(json_response["full_path"]).to eq("#{parent.path}/#{group[:path]}")
        expect(json_response["parent_id"]).to eq(parent.id)
      end

      context 'malicious group name' do
        subject { post api("/groups", user3), params: group_params }

        let(:group_params) { attributes_for_group_api name: "<SCRIPT>alert('ATTACKED!')</SCRIPT>", path: "unique-url" }

        it 'returns bad request' do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
        end

        it { expect { subject }.not_to change { Group.count } }
      end

      context 'when creating a group with `default_branch_protection` attribute' do
        let(:params) { attributes_for_group_api default_branch_protection: Gitlab::Access::PROTECTION_NONE }

        subject { post api("/groups", user3), params: params }

        context 'for users who have the ability to create a group with `default_branch_protection`' do
          it 'creates group with the specified branch protection level', :aggregate_failures do
            subject

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['default_branch_protection']).to eq(Gitlab::Access::PROTECTION_NONE)
          end
        end

        context 'for users who do not have the ability to create a group with `default_branch_protection`' do
          it 'does not create the group with the specified branch protection level', :aggregate_failures do
            allow(Ability).to receive(:allowed?).and_call_original
            allow(Ability).to receive(:allowed?).with(user3, :create_group_with_default_branch_protection) { false }

            subject

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['default_branch_protection']).not_to eq(Gitlab::Access::PROTECTION_NONE)
          end
        end
      end

      context 'when creating a group with "default_branch" attribute' do
        let(:params) { attributes_for_group_api default_branch: 'main' }

        subject { post api("/groups", user3), params: params }

        it 'creates group with the specified default branch', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['default_branch']).to eq('main')
        end
      end

      context 'when creating a nested group with `default_branch_protection_defaults` attribute' do
        let_it_be(:parent) { create(:group, organization: current_organization) }
        let_it_be(:params) do
          attributes_for_group_api(
            default_branch_protection_defaults: {
              "allowed_to_push" => [{ "access_level" => Gitlab::Access::DEVELOPER }]
            },
            parent_id: parent.id
          )
        end

        subject { post api("/groups", user3), params: params }

        before do
          parent.add_owner(user3)
        end

        it 'creates group' do
          subject

          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context 'when creating a group with `enabled_git_access_protocol' do
        let(:params) { attributes_for_group_api enabled_git_access_protocol: 'all' }

        subject { post api("/groups", user3), params: params }

        it 'creates group with the specified Git access protocol', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['enabled_git_access_protocol']).to eq(nil)
        end
      end

      it "does not create group, duplicate", :aggregate_failures do
        post api("/groups", user3), params: { name: 'Duplicate Test', path: group2.path }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(response.message).to eq("Bad Request")
      end

      it "returns 400 bad request error if name not given" do
        post api("/groups", user3), params: { path: group2.path }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it "returns 400 bad request error if path not given" do
        post api("/groups", user3), params: { name: 'test' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      context 'with existing pages unique domain' do
        before do
          stub_pages_setting(enabled: true)

          create(
            :project_setting,
            project: project1,
            pages_unique_domain_enabled: true,
            pages_unique_domain: 'existing-domain')
        end

        it "returns 400 bad request error if path is already used by pages unique domain" do
          expect do
            post api("/groups", user3), params: { name: 'test', path: 'existing-domain' }
          end.not_to change { Group.count }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq("Failed to save group {:path=>[\"has already been taken\"]}")
        end
      end
    end
  end

  describe "DELETE /groups/:id" do
    context "when authenticated as user" do
      it "removes group" do
        Sidekiq::Testing.fake! do
          expect { delete api("/groups/#{group1.id}", user1) }.to change(GroupDestroyWorker.jobs, :size).by(1)
        end

        expect(response).to have_gitlab_http_status(:accepted)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/groups/#{group1.id}", user1) }
        let(:success_status) { 202 }
      end

      it "does not remove a group if not an owner" do
        user4 = create(:user)
        group1.add_maintainer(user4)

        delete api("/groups/#{group1.id}", user3)

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it "does not remove a non existing group" do
        delete api("/groups/#{non_existing_record_id}", user1)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it "does not remove a group not attached to user1" do
        delete api("/groups/#{group2.id}", user1)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "when authenticated as admin" do
      it "removes any existing group" do
        expect_log_keys(caller_id: "DELETE /api/:version/groups/:id",
          route: "/api/:version/groups/:id",
          root_namespace: group2.path)

        delete api("/groups/#{group2.id}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:accepted)
      end

      it "does not remove a non existing group" do
        delete api("/groups/#{non_existing_record_id}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "POST /groups/:id/projects/:project_id" do
    let(:project) { create(:project) }
    let(:project_path) { CGI.escape(project.full_path) }

    before do
      allow_next_instance_of(Projects::TransferService) do |instance|
        allow(instance).to receive(:execute).and_return(true)
      end
    end

    context "when authenticated as user" do
      it "does not transfer project to group" do
        post api("/groups/#{group1.id}/projects/#{project.id}", user2)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context "when authenticated as admin" do
      it "transfers project to group" do
        post api("/groups/#{group1.id}/projects/#{project.id}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:created)
      end

      context 'when using project path in URL' do
        context 'with a valid project path' do
          it "transfers project to group" do
            post api("/groups/#{group1.id}/projects/#{project_path}", admin, admin_mode: true)

            expect(response).to have_gitlab_http_status(:created)
          end
        end

        context 'with a non-existent project path' do
          it "does not transfer project to group" do
            post api("/groups/#{group1.id}/projects/nogroup%2Fnoproject", admin, admin_mode: true)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when using a group path in URL' do
        context 'with a valid group path' do
          it "transfers project to group" do
            post api("/groups/#{group1.path}/projects/#{project_path}", admin, admin_mode: true)

            expect(response).to have_gitlab_http_status(:created)
          end
        end

        context 'with a non-existent group path' do
          it "does not transfer project to group" do
            post api("/groups/noexist/projects/#{project_path}", admin, admin_mode: true)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end

  describe 'GET /groups/:id/transfer_locations' do
    let_it_be(:user) { create(:user) }
    let_it_be(:source_group) { create(:group, :private) }

    let(:params) { {} }

    subject(:request) do
      get api("/groups/#{source_group.id}/transfer_locations", user), params: params
    end

    context 'when the user has rights to transfer the group' do
      let_it_be(:guest_group) { create(:group) }
      let_it_be(:maintainer_group) { create(:group, name: 'maintainer group', path: 'maintainer-group') }
      let_it_be(:owner_group_1) { create(:group, name: 'owner group', path: 'owner-group') }
      let_it_be(:owner_group_2) { create(:group, name: 'gitlab group', path: 'gitlab-group') }
      let_it_be(:shared_with_group_where_direct_owner_as_owner) { create(:group) }

      before do
        source_group.add_owner(user)
        guest_group.add_guest(user)
        maintainer_group.add_maintainer(user)
        owner_group_1.add_owner(user)
        owner_group_2.add_owner(user)
        create(
          :group_group_link,
          :owner,
          shared_with_group: owner_group_1,
          shared_group: shared_with_group_where_direct_owner_as_owner
        )
      end

      it 'returns 200' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
      end

      it 'only includes groups where the user has permissions to transfer a group to' do
        expect_log_keys(caller_id: "GET /api/:version/groups/:id/transfer_locations",
          route: "/api/:version/groups/:id/transfer_locations",
          root_namespace: source_group.path)

        request

        expect(group_ids_from_response).to contain_exactly(
          owner_group_1.id,
          owner_group_2.id,
          shared_with_group_where_direct_owner_as_owner.id
        )
      end

      context 'with search' do
        let(:params) { { search: 'gitlab' } }

        it 'includes groups where the user has permissions to transfer a group to, matching the search term' do
          request

          expect(group_ids_from_response).to contain_exactly(owner_group_2.id)
        end
      end

      def group_ids_from_response
        json_response.map { |group| group['id'] }
      end
    end

    context 'when the user does not have permissions to transfer the group' do
      before do
        source_group.add_developer(user)
      end

      it 'returns 403' do
        request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'for an anonymous user' do
      let_it_be(:user) { nil }

      it 'returns 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /groups/:id/transfer' do
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:new_parent_group) { create(:group, :private) }
    let_it_be_with_reload(:group) { create(:group, :nested, :private) }

    before do
      new_parent_group.add_owner(user)
      group.add_owner(user)
    end

    def make_request(user)
      post api("/groups/#{group.id}/transfer", user), params: params
    end

    context 'when promoting a subgroup to a root group' do
      shared_examples_for 'promotes the subgroup to a root group' do
        it 'returns success', :aggregate_failures do
          expect_log_keys(caller_id: "POST /api/:version/groups/:id/transfer",
            route: "/api/:version/groups/:id/transfer",
            root_namespace: group.path)

          make_request(user)

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['parent_id']).to be_nil
        end
      end

      context 'when no group_id is specified' do
        let(:params) {}

        it_behaves_like 'promotes the subgroup to a root group'
      end

      context 'when group_id is specified as blank' do
        let(:params) { { group_id: '' } }

        it_behaves_like 'promotes the subgroup to a root group'
      end

      context 'when the group is already a root group' do
        let(:group) { create(:group) }
        let(:params) { { group_id: '' } }

        it 'returns error', :aggregate_failures do
          make_request(user)

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq('Transfer failed: Group is already a root group.')
        end
      end
    end

    context 'when transferring a subgroup to a different group' do
      let(:params) { { group_id: new_parent_group.id } }

      context 'when the user does not have admin rights to the group being transferred' do
        it 'forbids the operation' do
          developer_user = create(:user)
          group.add_developer(developer_user)

          make_request(developer_user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when the user does not have access to the new parent group' do
        it 'fails with 404' do
          user_without_access_to_new_parent_group = create(:user)
          group.add_owner(user_without_access_to_new_parent_group)

          make_request(user_without_access_to_new_parent_group)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when the ID of a non-existent group is mentioned as the new parent group' do
        let(:params) { { group_id: non_existing_record_id } }

        it 'fails with 404' do
          make_request(user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when the transfer fails due to an error' do
        before do
          expect_next_instance_of(::Groups::TransferService) do |service|
            expect(service).to receive(:proceed_to_transfer).and_raise(Gitlab::UpdatePathError, 'namespace directory cannot be moved')
          end
        end

        it 'returns error', :aggregate_failures do
          make_request(user)

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq('Transfer failed: namespace directory cannot be moved')
        end
      end

      context 'when the transfer succceds' do
        it 'returns success', :aggregate_failures do
          make_request(user)

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['parent_id']).to eq(new_parent_group.id)
        end
      end
    end
  end

  it_behaves_like 'custom attributes endpoints', 'groups' do
    let(:attributable) { group1 }
    let(:other_attributable) { group2 }
    let(:user) { user1 }

    before do
      group2.add_owner(user1)
    end
  end

  describe "POST /groups/:id/share" do
    shared_examples 'shares group with group' do
      let_it_be(:admin_mode) { false }

      it "shares group with group", :aggregate_failures do
        expires_at = 10.days.from_now.to_date

        expect do
          post api("/groups/#{group.id}/share", user, admin_mode: admin_mode), params: { group_id: shared_with_group.id, group_access: Gitlab::Access::DEVELOPER, expires_at: expires_at }
        end.to change { group.shared_with_group_links.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['shared_with_groups']).to be_an Array
        expect(json_response['shared_with_groups'].length).to eq(1)
        expect(json_response['shared_with_groups'][0]['group_id']).to eq(shared_with_group.id)
        expect(json_response['shared_with_groups'][0]['group_name']).to eq(shared_with_group.name)
        expect(json_response['shared_with_groups'][0]['group_full_path']).to eq(shared_with_group.full_path)
        expect(json_response['shared_with_groups'][0]['group_access_level']).to eq(Gitlab::Access::DEVELOPER)
        expect(json_response['shared_with_groups'][0]['expires_at']).to eq(expires_at.to_s)
      end

      it "returns a 400 error when group id is not given" do
        post api("/groups/#{group.id}/share", user), params: { group_access: Gitlab::Access::DEVELOPER }
        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it "returns a 400 error when access level is not given" do
        post api("/groups/#{group.id}/share", user), params: { group_id: shared_with_group.id }
        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns a 404 error when group does not exist' do
        post api("/groups/#{group.id}/share", user), params: { group_id: non_existing_record_id, group_access: Gitlab::Access::DEVELOPER }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it "returns a 400 error when wrong params passed", :aggregate_failures do
        post api("/groups/#{group.id}/share", user), params: { group_id: shared_with_group.id, group_access: non_existing_record_access_level }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq 'group_access does not have a valid value'
      end

      it "returns a 409 error when link is not saved" do
        allow(::Groups::GroupLinks::CreateService).to receive_message_chain(:new, :execute)
          .and_return({ status: :error, http_status: 409, message: 'error' })

        post api("/groups/#{group.id}/share", user), params: { group_id: shared_with_group.id, group_access: Gitlab::Access::DEVELOPER }

        expect(response).to have_gitlab_http_status(:conflict)
      end
    end

    context 'when authenticated as owner' do
      let(:owner_group) { create(:group) }
      let(:owner_user) { create(:user) }

      before do
        owner_group.add_owner(owner_user)
      end

      it_behaves_like 'shares group with group' do
        let(:user) { owner_user }
        let(:group) { owner_group }
        let(:shared_with_group) { create(:group) }
      end
    end

    context 'when the user is not the owner of the group' do
      let(:group) { create(:group) }
      let(:user4) { create(:user) }
      let(:expires_at) { 10.days.from_now.to_date }

      before do
        group1.add_maintainer(user4)
      end

      it 'does not create group share' do
        post api("/groups/#{group1.id}/share", user4), params: { group_id: group.id, group_access: Gitlab::Access::DEVELOPER, expires_at: expires_at }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when authenticated as admin' do
      it_behaves_like 'shares group with group' do
        let(:user) { admin }
        let(:group) { create(:group) }
        let(:shared_with_group) { create(:group) }
        let(:admin_mode) { true }
      end
    end
  end

  describe 'DELETE /groups/:id/share/:group_id' do
    shared_examples 'deletes group share' do
      let_it_be(:admin_mode) { false }

      it 'deletes a group share', :aggregate_failures do
        expect do
          delete api("/groups/#{shared_group.id}/share/#{shared_with_group.id}", user, admin_mode: admin_mode)

          expect(response).to have_gitlab_http_status(:no_content)
          expect(shared_group.shared_with_group_links).to be_empty
        end.to change { shared_group.shared_with_group_links.count }.by(-1)
      end

      it 'requires the group id to be an integer' do
        delete api("/groups/#{shared_group.id}/share/foo", user)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns a 404 error when group link does not exist' do
        delete api("/groups/#{shared_group.id}/share/#{non_existing_record_id}", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns a 404 error when group does not exist' do
        delete api("/groups/123/share/#{non_existing_record_id}", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when authenticated as owner' do
      let(:group_a) { create(:group) }

      before do
        create(:group_group_link, shared_group: group1, shared_with_group: group_a)
      end

      it_behaves_like 'deletes group share' do
        let(:user) { user1 }
        let(:shared_group) { group1 }
        let(:shared_with_group) { group_a }
      end
    end

    context 'when the user is not the owner of the group' do
      let(:group_a) { create(:group) }
      let(:user4) { create(:user) }

      before do
        group1.add_maintainer(user4)
        create(:group_group_link, shared_group: group1, shared_with_group: group_a)
      end

      it 'does not remove group share', :aggregate_failures do
        expect do
          delete api("/groups/#{group1.id}/share/#{group_a.id}", user4)

          expect(response).to have_gitlab_http_status(:no_content)
        end.not_to change { group1.shared_with_group_links }
      end
    end

    context 'when authenticated as admin' do
      let(:group_b) { create(:group) }

      before do
        create(:group_group_link, shared_group: group2, shared_with_group: group_b)
      end

      it_behaves_like 'deletes group share' do
        let(:user) { admin }
        let(:shared_group) { group2 }
        let(:shared_with_group) { group_b }
        let(:admin_mode) { true }
      end
    end
  end

  describe 'POST groups/:id/tokens/revoke' do
    let(:token) { 'glprefix-AABBCCDDEE1122334455' }
    let(:service_response) { ServiceResponse.error(message: '') }
    let(:service) { instance_double(service_class, execute: service_response) }
    let(:service_class) { Groups::AgnosticTokenRevocationService }
    let_it_be(:group) { create(:group, :with_hierarchy, children: 1) }

    let(:path) { "/groups/#{group.id}/tokens/revoke" }

    before do
      allow(service_class).to receive(:new).and_return(service)
    end

    shared_examples 'revoking token fails' do |status, message|
      it 'cannot revoke token' do
        revoke_token

        expect(response).to have_gitlab_http_status(status)
        expect(json_response['message'] || json_response['error']).to include(message)
      end
    end

    context 'when not a group owner' do
      subject(:revoke_token) { post api(path, user1), params: { token: token } }

      before do
        group.add_maintainer(user1)
      end

      it_behaves_like 'revoking token fails', :forbidden, 'Forbidden'
    end

    context 'when authenticated as a group owner' do
      subject(:revoke_token) { post api(path, user1), params: { token: token } }

      before do
        group.add_owner(user1)
      end

      context 'when group is a top level group' do
        it 'calls revocation service' do
          revoke_token
          expect(service_class).to have_received(:new).with(group, user1, token)
        end

        context 'when the service returns successfully' do
          let(:token) { create(:personal_access_token, :revoked) }
          let(:service_response) do
            ServiceResponse.success(
              message: 'PersonalAccessToken is revoked',
              payload: {
                revocable: token,
                type: 'PersonalAccessToken',
                api_entity: 'PersonalAccessToken'
              }
            )
          end

          it 'renders the token with a presenter', :aggregate_failures do
            revoke_token
            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.with_indifferent_access).to include(revoked: true, id: token.id)
            expect(json_response.keys).not_to include(%w[token token_digest])
          end
        end

        context 'when the service returns unsuccessfully' do
          let(:service_response) do
            ServiceResponse.error(
              message: 'Some error'
            )
          end

          it_behaves_like 'revoking token fails', :unprocessable_entity, 'Unprocessable Entity'
        end

        context 'when ff disabled' do
          before do
            Feature.disable(:group_agnostic_token_revocation, group)
          end

          it_behaves_like 'revoking token fails', :not_found, 'Not Found'

          it 'does not call revocation service' do
            revoke_token
            expect(service_class).not_to have_received(:new)
          end
        end
      end

      context 'when group does not exist' do
        let(:path) { "/groups/0/tokens/revoke" }

        it_behaves_like 'revoking token fails', :not_found, 'Group Not Found'

        it 'does not call revocation service' do
          revoke_token
          expect(service_class).not_to have_received(:new)
        end
      end

      context 'when group is a subgroup' do
        let(:path) { "/groups/#{group.children.first.id}/tokens/revoke" }

        it_behaves_like 'revoking token fails', :bad_request, 'Must be a top-level'

        it 'does not call revocation service' do
          revoke_token
          expect(service_class).not_to have_received(:new)
        end
      end
    end
  end
end
