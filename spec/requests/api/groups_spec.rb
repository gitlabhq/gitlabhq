# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Groups do
  include GroupAPIHelpers
  include UploadHelpers

  let_it_be(:user1) { create(:user, can_create_group: false) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:user3) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:group1) { create(:group, avatar: File.open(uploaded_image_temp_path)) }
  let_it_be(:group2) { create(:group, :private) }
  let_it_be(:project1) { create(:project, namespace: group1) }
  let_it_be(:project2) { create(:project, namespace: group2) }
  let_it_be(:project3) { create(:project, namespace: group1, path: 'test', visibility_level: Gitlab::VisibilityLevel::PRIVATE) }
  let_it_be(:archived_project) { create(:project, namespace: group1, archived: true) }

  before_all do
    group1.add_owner(user1)
    group2.add_owner(user2)
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
        it 'returns 400' do
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
    it 'does not find groups by full path' do
      subgroup = create(:group, parent: parent, path: "#{parent.path}-subgroup")
      create(:group, parent: parent, path: 'not_matching_path')

      get endpoint, params: { search: parent.path }

      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(subgroup.id)
    end
  end

  describe "GET /groups" do
    context "when unauthenticated" do
      it "returns public groups" do
        get api("/groups")

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['created_at']).to be_present
        expect(json_response)
          .to satisfy_one { |group| group['name'] == group1.name }
      end

      it 'avoids N+1 queries' do
        # Establish baseline
        get api("/groups", admin)

        control = ActiveRecord::QueryRecorder.new do
          get api("/groups", admin)
        end

        create(:group)

        expect do
          get api("/groups", admin)
        end.not_to exceed_query_limit(control)
      end

      context 'when statistics are requested' do
        it 'does not include statistics' do
          get api("/groups"), params: { statistics: true }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.first).not_to include 'statistics'
        end
      end
    end

    context "when authenticated as user" do
      it "normal user: returns an array of groups of user1" do
        get api("/groups", user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response)
          .to satisfy_one { |group| group['name'] == group1.name }
      end

      it "does not include runners_token information" do
        get api("/groups", user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first).not_to include('runners_token')
      end

      it "does not include statistics" do
        get api("/groups", user1), params: { statistics: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include 'statistics'
      end

      it "includes a created_at timestamp" do
        get api("/groups", user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['created_at']).to be_present
      end
    end

    context "when authenticated as admin" do
      it "admin: returns an array of all groups" do
        get api("/groups", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
      end

      it "does not include runners_token information" do
        get api("/groups", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
        expect(json_response.first).not_to include('runners_token')
      end

      it "does not include statistics by default" do
        get api("/groups", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include('statistics')
      end

      it "includes a created_at timestamp" do
        get api("/groups", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['created_at']).to be_present
      end

      it "includes statistics if requested" do
        attributes = {
          storage_size: 2392,
          repository_size: 123,
          wiki_size: 456,
          lfs_objects_size: 234,
          build_artifacts_size: 345,
          snippets_size: 1234
        }.stringify_keys
        exposed_attributes = attributes.dup
        exposed_attributes['job_artifacts_size'] = exposed_attributes.delete('build_artifacts_size')

        project1.statistics.update!(attributes)

        get api("/groups", admin), params: { statistics: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response)
          .to satisfy_one { |group| group['statistics'] == exposed_attributes }
      end
    end

    context "when using skip_groups in request" do
      it "returns all groups excluding skipped groups" do
        get api("/groups", admin), params: { skip_groups: [group2.id] }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
      end
    end

    context "when using all_available in request" do
      let(:response_groups) { json_response.map { |group| group['name'] } }

      it "returns all groups you have access to" do
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

      it "doesn't return subgroups" do
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

      it "sorts by name ascending by default" do
        get api("/groups", user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq(groups_visible_to_user(user1).order(:name).pluck(:name))
      end

      it "sorts in descending order when passed" do
        get api("/groups", user1), params: { sort: "desc" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq(groups_visible_to_user(user1).order(name: :desc).pluck(:name))
      end

      it "sorts by path in order_by param" do
        get api("/groups", user1), params: { order_by: "path" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq(groups_visible_to_user(user1).order(:path).pluck(:name))
      end

      it "sorts by id in the order_by param" do
        get api("/groups", user1), params: { order_by: "id" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq(groups_visible_to_user(user1).order(:id).pluck(:name))
      end

      it "sorts also by descending id with pagination fix" do
        get api("/groups", user1), params: { order_by: "id", sort: "desc" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq(groups_visible_to_user(user1).order(id: :desc).pluck(:name))
      end

      it "sorts identical keys by id for good pagination" do
        get api("/groups", user1), params: { search: "same-name", order_by: "name" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups_ids).to eq(Group.select { |group| group['name'] == 'same-name' }.map { |group| group['id'] }.sort)
      end

      it "sorts descending identical keys by id for good pagination" do
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

        it 'sorts top level groups before subgroups with exact matches first' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response.length).to eq(4)

          expect(response_groups).to eq(['same-name', 'same-name parent', 'same-name subgroup', 'same-name'])
        end

        context 'when `search` parameter is not given' do
          let(:params) { { order_by: 'similarity' } }

          it 'sorts items ordered by name' do
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
      it 'returns an array of groups the user owns' do
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

      it 'returns an array of groups the user has at least master access' do
        get api('/groups', user2), params: { min_access_level: 40 }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to contain_exactly(group2.id, group3.id)
      end
    end

    context 'when searching' do
      let_it_be(:subgroup1) { create(:group, parent: group1, path: 'some_path') }

      let(:response_groups) { json_response.map { |group| group['id'] } }

      subject { get api('/groups', user1), params: { search: group1.path } }

      it 'finds also groups with full path matching search param' do
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
        public:   create(:project, :public,   namespace: group),
        internal: create(:project, :internal, namespace: group),
        private:  create(:project, :private,  namespace: group)
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

    context 'when unauthenticated' do
      it 'returns 404 for a private group' do
        get api("/groups/#{group2.id}")

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns 200 for a public group' do
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
      it "returns one of user1's groups" do
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
        expect(json_response['emails_disabled']).to eq(group1.emails_disabled)
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
      end

      it "returns one of user1's groups without projects when with_projects option is set to false" do
        project = create(:project, namespace: group2, path: 'Foo')
        create(:project_group_link, project: project, group: group1)

        get api("/groups/#{group1.id}", user1), params: { with_projects: false }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['projects']).to be_nil
        expect(json_response['shared_projects']).to be_nil
        expect(json_response).not_to include('runners_token')
      end

      it "doesn't return runners_token if the user is not the owner of the group" do
        get api("/groups/#{group1.id}", user3)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to include('runners_token')
      end

      it "returns runners_token if the user is the owner of the group" do
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

      it 'avoids N+1 queries with project links' do
        get api("/groups/#{group1.id}", admin)

        control_count = ActiveRecord::QueryRecorder.new do
          get api("/groups/#{group1.id}", admin)
        end.count

        create(:project, namespace: group1)

        expect do
          get api("/groups/#{group1.id}", admin)
        end.not_to exceed_query_limit(control_count)
      end

      it 'avoids N+1 queries with shared group links' do
        # setup at least 1 shared group, so that we record the queries that preload the nested associations too.
        create(:group_group_link, shared_group: group1, shared_with_group: create(:group))

        control_count = ActiveRecord::QueryRecorder.new do
          get api("/groups/#{group1.id}", admin)
        end.count

        # setup "n" more shared groups
        create(:group_group_link, shared_group: group1, shared_with_group: create(:group))
        create(:group_group_link, shared_group: group1, shared_with_group: create(:group))

        # test that no of queries for 1 shared group is same as for n shared groups
        expect do
          get api("/groups/#{group1.id}", admin)
        end.not_to exceed_query_limit(control_count)
      end
    end

    context "when authenticated as admin" do
      it "returns any existing group" do
        get api("/groups/#{group2.id}", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(group2.name)
      end

      it "returns information of the runners_token for the group" do
        get api("/groups/#{group2.id}", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include('runners_token')
      end

      it "does not return a non existing group" do
        get api("/groups/#{non_existing_record_id}", admin)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when using group path in URL' do
      it 'returns any existing group' do
        get api("/groups/#{group1.path}", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(group1.name)
      end

      it 'does not return a non existing group' do
        get api('/groups/unknown', admin)

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

      it 'limits projects and shared_projects' do
        get api("/groups/#{group1.id}")

        expect(json_response['projects'].count).to eq(limit)
        expect(json_response['shared_projects'].count).to eq(limit)
      end
    end
  end

  describe 'PUT /groups/:id' do
    let(:new_group_name) { 'New Group'}
    let(:file_path) { 'spec/fixtures/dk.png' }

    it_behaves_like 'group avatar upload' do
      def make_upload_request
        group_param = {
          avatar: fixture_file_upload(file_path)
        }
        put api("/groups/#{group1.id}", user1), params: group_param
      end
    end

    context 'when authenticated as the group owner' do
      it 'updates the group' do
        put api("/groups/#{group1.id}", user1), params: {
          name: new_group_name,
          request_access_enabled: true,
          project_creation_level: "noone",
          subgroup_creation_level: "maintainer",
          default_branch_protection: ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS,
          prevent_sharing_groups_outside_hierarchy: true,
          avatar: fixture_file_upload(file_path)
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(new_group_name)
        expect(json_response['description']).to eq('')
        expect(json_response['visibility']).to eq('public')
        expect(json_response['share_with_group_lock']).to eq(false)
        expect(json_response['require_two_factor_authentication']).to eq(false)
        expect(json_response['two_factor_grace_period']).to eq(48)
        expect(json_response['auto_devops_enabled']).to eq(nil)
        expect(json_response['emails_disabled']).to eq(nil)
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
        expect(json_response['avatar_url']).to end_with('dk.png')
        expect(json_response['prevent_sharing_groups_outside_hierarchy']).to eq(true)
      end

      context 'updating the `default_branch_protection` attribute' do
        subject do
          put api("/groups/#{group1.id}", user1), params: { default_branch_protection: ::Gitlab::Access::PROTECTION_NONE }
        end

        context 'for users who have the ability to update default_branch_protection' do
          it 'updates the attribute' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['default_branch_protection']).to eq(Gitlab::Access::PROTECTION_NONE)
          end
        end

        context 'for users who does not have the ability to update default_branch_protection`' do
          it 'does not update the attribute' do
            allow(Ability).to receive(:allowed?).and_call_original
            allow(Ability).to receive(:allowed?).with(user1, :update_default_branch_protection, group1) { false }

            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['default_branch_protection']).not_to eq(Gitlab::Access::PROTECTION_NONE)
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

        it 'does not change visibility when not requested' do
          put api("/groups/#{group3.id}", user3), params: { description: 'Bug #23083' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['visibility']).to eq('public')
        end

        it 'prevents making private a group containing public subgroups' do
          put api("/groups/#{group3.id}", user3), params: { visibility: 'private' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['visibility_level']).to contain_exactly('private is not allowed since there are sub-groups with higher visibility.')
        end

        it 'does not update prevent_sharing_groups_outside_hierarchy' do
          put api("/groups/#{subgroup.id}", user3), params: { description: 'it works', prevent_sharing_groups_outside_hierarchy: true }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.keys).not_to include('prevent_sharing_groups_outside_hierarchy')
          expect(subgroup.reload.prevent_sharing_groups_outside_hierarchy).to eq(false)
          expect(json_response['description']).to eq('it works')
        end
      end
    end

    context 'when authenticated as the admin' do
      it 'updates the group' do
        put api("/groups/#{group1.id}", admin), params: { name: new_group_name }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(new_group_name)
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
    context "when authenticated as user" do
      context 'with min access level' do
        it 'returns projects with min access level or higher' do
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

      it "returns the group's projects" do
        get api("/groups/#{group1.id}/projects", user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(3)
        project_names = json_response.map { |proj| proj['name'] }
        expect(project_names).to match_array([project1.name, project3.name, archived_project.name])
        expect(json_response.first['visibility']).to be_present
      end

      context 'and using archived' do
        it "returns the group's archived projects" do
          get api("/groups/#{group1.id}/projects?archived=true", user1)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(Project.public_or_visible_to_user(user1).where(archived: true).size)
          expect(json_response.map { |project| project['id'] }).to include(archived_project.id)
        end

        it "returns the group's non-archived projects" do
          get api("/groups/#{group1.id}/projects?archived=false", user1)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(Project.public_or_visible_to_user(user1).where(archived: false).size)
          expect(json_response.map { |project| project['id'] }).not_to include(archived_project.id)
        end

        it "returns all of the group's projects" do
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

        it 'returns items based ordered by similarity' do
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

          it 'returns items ordered by name' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response.length).to eq(3)

            project_names = json_response.map { |proj| proj['name'] }
            expect(project_names).to eq(['Project', 'Test', 'Test Project'])
          end
        end

        context 'when `similarity_search` feature flag is off' do
          before do
            stub_feature_flags(similarity_search: false)
          end

          it 'returns items ordered by name' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response.length).to eq(2)

            project_names = json_response.map { |proj| proj['name'] }
            expect(project_names).to eq(['Test', 'Test Project'])
          end
        end
      end

      it "returns the group's projects with simple representation" do
        get api("/groups/#{group1.id}/projects", user1), params: { simple: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(3)
        project_names = json_response.map { |proj| proj['name'] }
        expect(project_names).to match_array([project1.name, project3.name, archived_project.name])
        expect(json_response.first['visibility']).not_to be_present
      end

      it "filters the groups projects" do
        public_project = create(:project, :public, path: 'test1', group: group1)

        get api("/groups/#{group1.id}/projects", user1), params: { visibility: 'public' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(public_project.name)
      end

      it "returns projects excluding shared" do
        create(:project_group_link, project: create(:project), group: group1)
        create(:project_group_link, project: create(:project), group: group1)
        create(:project_group_link, project: create(:project), group: group1)

        get api("/groups/#{group1.id}/projects", user1), params: { with_shared: false }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(3)
      end

      it "returns projects including those in subgroups" do
        subgroup = create(:group, parent: group1)
        create(:project, group: subgroup)
        create(:project, group: subgroup)

        get api("/groups/#{group1.id}/projects", user1), params: { include_subgroups: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(5)
      end

      it "does not return a non existing group" do
        get api("/groups/#{non_existing_record_id}/projects", user1)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it "does not return a group not attached to user1" do
        get api("/groups/#{group2.id}/projects", user1)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it "only returns projects to which user has access" do
        project3.add_developer(user3)

        get api("/groups/#{group1.id}/projects", user3)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project3.name)
      end

      it 'only returns the projects owned by user' do
        project2.group.add_owner(user3)

        get api("/groups/#{project2.group.id}/projects", user3), params: { owned: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project2.name)
      end

      it 'only returns the projects starred by user' do
        user1.starred_projects = [project1]

        get api("/groups/#{group1.id}/projects", user1), params: { starred: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project1.name)
      end
    end

    context "when authenticated as admin" do
      it "returns any existing group" do
        get api("/groups/#{group2.id}/projects", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project2.name)
      end

      it "does not return a non existing group" do
        get api("/groups/#{non_existing_record_id}/projects", admin)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'avoids N+1 queries' do
        get api("/groups/#{group1.id}/projects", admin)

        control_count = ActiveRecord::QueryRecorder.new do
          get api("/groups/#{group1.id}/projects", admin)
        end.count

        create(:project, namespace: group1)

        expect do
          get api("/groups/#{group1.id}/projects", admin)
        end.not_to exceed_query_limit(control_count)
      end
    end

    context 'when using group path in URL' do
      it 'returns any existing group' do
        get api("/groups/#{group1.path}/projects", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        project_names = json_response.map { |proj| proj['name'] }
        expect(project_names).to match_array([project1.name, project3.name, archived_project.name])
      end

      it 'does not return a non existing group' do
        get api('/groups/unknown/projects', admin)

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
      create(:project, namespace: group2, path: 'test_project', visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    end

    let(:path) { "/groups/#{group1.id}/projects/shared" }

    before do
      create(:project_group_link, project: project2, group: group1)
      create(:project_group_link, project: project4, group: group1)
    end

    context 'when authenticated as user' do
      it 'returns the shared projects in the group' do
        get api(path, user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(2)
        project_ids = json_response.map { |project| project['id'] }
        expect(project_ids).to match_array([project2.id, project4.id])
        expect(json_response.first['visibility']).to be_present
      end

      it 'returns shared projects with min access level or higher' do
        user = create(:user)

        project2.add_guest(user)
        project4.add_reporter(user)

        get api(path, user), params: { min_access_level: Gitlab::Access::REPORTER }

        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(project4.id)
      end

      it 'returns the shared projects of the group with simple representation' do
        get api(path, user1), params: { simple: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(2)
        project_ids = json_response.map { |project| project['id'] }
        expect(project_ids).to match_array([project2.id, project4.id])
        expect(json_response.first['visibility']).not_to be_present
      end

      it 'filters the shared projects in the group based on visibility' do
        internal_project = create(:project, :internal, namespace: create(:group))

        create(:project_group_link, project: internal_project, group: group1)

        get api(path, user1), params: { visibility: 'internal' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(internal_project.id)
      end

      it 'filters the shared projects in the group based on search params' do
        get api(path, user1), params: { search: 'test_project' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(project4.id)
      end

      it 'does not return the projects owned by the group' do
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

      it 'only returns shared projects to which user has access' do
        project4.add_developer(user3)

        get api(path, user3)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(project4.id)
      end

      it 'only returns the projects starred by user' do
        user1.starred_projects = [project2]

        get api(path, user1), params: { starred: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(project2.id)
      end
    end

    context "when authenticated as admin" do
      subject { get api(path, admin) }

      it "returns shared projects of an existing group" do
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

      it 'avoids N+1 queries' do
        control_count = ActiveRecord::QueryRecorder.new do
          subject
        end.count

        create(:project_group_link, project: create(:project), group: group1)

        expect do
          subject
        end.not_to exceed_query_limit(control_count)
      end
    end

    context 'when using group path in URL' do
      let(:path) { "/groups/#{group1.path}/projects/shared" }

      it 'returns the right details' do
        get api(path, admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(2)
        project_ids = json_response.map { |project| project['id'] }
        expect(project_ids).to match_array([project2.id, project4.id])
      end

      it 'returns 404 for a non-existent group' do
        get api('/groups/unknown/projects/shared', admin)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /groups/:id/subgroups' do
    let!(:subgroup1) { create(:group, parent: group1) }
    let!(:subgroup2) { create(:group, :private, parent: group1) }
    let!(:subgroup3) { create(:group, :private, parent: group2) }

    context 'when unauthenticated' do
      it 'returns only public subgroups' do
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
        it 'does not include statistics' do
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
        it 'returns no subgroups for the public group' do
          get api("/groups/#{group1.id}/subgroups", user2)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(0)
        end

        context 'when using all_available in request' do
          it 'returns public subgroups' do
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

        it 'returns private subgroups' do
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
          it 'does not include statistics' do
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

        it 'returns subgroups' do
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
      it 'returns private subgroups of a public group' do
        get api("/groups/#{group1.id}/subgroups", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
      end

      it 'returns subgroups of a private group' do
        get api("/groups/#{group2.id}/subgroups", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
      end

      it 'does not include statistics by default' do
        get api("/groups/#{group1.id}/subgroups", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include('statistics')
      end

      it 'includes statistics if requested' do
        get api("/groups/#{group1.id}/subgroups", admin), params: { statistics: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.first).to include('statistics')
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
      it 'returns only public descendants' do
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
        it 'returns no descendants for the public group' do
          get api("/groups/#{group1.id}/descendant_groups", user2)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(0)
        end

        context 'when using all_available in request' do
          it 'returns public descendants' do
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

        it 'returns private descendants' do
          get api("/groups/#{group1.id}/descendant_groups", user2)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(3)
          expect(response_groups).to contain_exactly(child_group1.name, sub_child_group1.name, private_child_group1.name)
        end

        context 'when using statistics in request' do
          it 'does not include statistics' do
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

        it 'returns descendants' do
          get api("/groups/#{group2.id}/descendant_groups", user1)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(2)
          expect(response_groups).to contain_exactly(child_group2.name, sub_child_group2.name)
        end
      end
    end

    context 'when authenticated as admin' do
      it 'returns private descendants of a public group' do
        get api("/groups/#{group1.id}/descendant_groups", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(3)
      end

      it 'returns descendants of a private group' do
        get api("/groups/#{group2.id}/descendant_groups", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
      end

      it 'does not include statistics by default' do
        get api("/groups/#{group1.id}/descendant_groups", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include('statistics')
      end

      it 'includes statistics if requested' do
        get api("/groups/#{group1.id}/descendant_groups", admin), params: { statistics: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.first).to include('statistics')
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

        post api("/groups", user3), params: params
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

    context "when authenticated as user with group permissions" do
      it "creates group" do
        group = attributes_for_group_api request_access_enabled: false

        post api("/groups", user3), params: group

        expect(response).to have_gitlab_http_status(:created)

        expect(json_response["name"]).to eq(group[:name])
        expect(json_response["path"]).to eq(group[:path])
        expect(json_response["request_access_enabled"]).to eq(group[:request_access_enabled])
        expect(json_response["visibility"]).to eq(Gitlab::VisibilityLevel.string_level(Gitlab::CurrentSettings.current_application_settings.default_group_visibility))
      end

      it "creates a nested group" do
        parent = create(:group)
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
          it 'creates group with the specified branch protection level' do
            subject

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['default_branch_protection']).to eq(Gitlab::Access::PROTECTION_NONE)
          end
        end

        context 'for users who do not have the ability to create a group with `default_branch_protection`' do
          it 'does not create the group with the specified branch protection level' do
            allow(Ability).to receive(:allowed?).and_call_original
            allow(Ability).to receive(:allowed?).with(user3, :create_group_with_default_branch_protection) { false }

            subject

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['default_branch_protection']).not_to eq(Gitlab::Access::PROTECTION_NONE)
          end
        end
      end

      it "does not create group, duplicate" do
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
        delete api("/groups/#{group2.id}", admin)

        expect(response).to have_gitlab_http_status(:accepted)
      end

      it "does not remove a non existing group" do
        delete api("/groups/#{non_existing_record_id}", admin)

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
        post api("/groups/#{group1.id}/projects/#{project.id}", admin)

        expect(response).to have_gitlab_http_status(:created)
      end

      context 'when using project path in URL' do
        context 'with a valid project path' do
          it "transfers project to group" do
            post api("/groups/#{group1.id}/projects/#{project_path}", admin)

            expect(response).to have_gitlab_http_status(:created)
          end
        end

        context 'with a non-existent project path' do
          it "does not transfer project to group" do
            post api("/groups/#{group1.id}/projects/nogroup%2Fnoproject", admin)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when using a group path in URL' do
        context 'with a valid group path' do
          it "transfers project to group" do
            post api("/groups/#{group1.path}/projects/#{project_path}", admin)

            expect(response).to have_gitlab_http_status(:created)
          end
        end

        context 'with a non-existent group path' do
          it "does not transfer project to group" do
            post api("/groups/noexist/projects/#{project_path}", admin)

            expect(response).to have_gitlab_http_status(:not_found)
          end
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
      it "shares group with group" do
        expires_at = 10.days.from_now.to_date

        expect do
          post api("/groups/#{group.id}/share", user), params: { group_id: shared_with_group.id, group_access: Gitlab::Access::DEVELOPER, expires_at: expires_at }
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

      it "returns a 400 error when wrong params passed" do
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
      end
    end
  end

  describe 'DELETE /groups/:id/share/:group_id' do
    shared_examples 'deletes group share' do
      it 'deletes a group share' do
        expect do
          delete api("/groups/#{shared_group.id}/share/#{shared_with_group.id}", user)

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

      it 'does not remove group share' do
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
      end
    end
  end
end
