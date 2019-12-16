# frozen_string_literal: true

require 'spec_helper'

describe API::Groups do
  include GroupAPIHelpers
  include UploadHelpers

  let(:user1) { create(:user, can_create_group: false) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:admin) { create(:admin) }
  let!(:group1) { create(:group, avatar: File.open(uploaded_image_temp_path)) }
  let!(:group2) { create(:group, :private) }
  let!(:project1) { create(:project, namespace: group1) }
  let!(:project2) { create(:project, namespace: group2) }
  let!(:project3) { create(:project, namespace: group1, path: 'test', visibility_level: Gitlab::VisibilityLevel::PRIVATE) }

  before do
    group1.add_owner(user1)
    group2.add_owner(user2)
  end

  describe "GET /groups" do
    context "when unauthenticated" do
      it "returns public groups" do
        get api("/groups")

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
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
    end

    context "when authenticated as user" do
      it "normal user: returns an array of groups of user1" do
        get api("/groups", user1)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response)
          .to satisfy_one { |group| group['name'] == group1.name }
      end

      it "does not include runners_token information" do
        get api("/groups", user1)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first).not_to include('runners_token')
      end

      it "does not include statistics" do
        get api("/groups", user1), params: { statistics: true }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include 'statistics'
      end
    end

    context "when authenticated as admin" do
      it "admin: returns an array of all groups" do
        get api("/groups", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
      end

      it "does not include runners_token information" do
        get api("/groups", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
        expect(json_response.first).not_to include('runners_token')
      end

      it "does not include statistics by default" do
        get api("/groups", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include('statistics')
      end

      it "includes statistics if requested" do
        attributes = {
          storage_size: 1158,
          repository_size: 123,
          wiki_size: 456,
          lfs_objects_size: 234,
          build_artifacts_size: 345
        }.stringify_keys
        exposed_attributes = attributes.dup
        exposed_attributes['job_artifacts_size'] = exposed_attributes.delete('build_artifacts_size')

        project1.statistics.update!(attributes)

        get api("/groups", admin), params: { statistics: true }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response)
          .to satisfy_one { |group| group['statistics'] == exposed_attributes }
      end
    end

    context "when using skip_groups in request" do
      it "returns all groups excluding skipped groups" do
        get api("/groups", admin), params: { skip_groups: [group2.id] }

        expect(response).to have_gitlab_http_status(200)
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

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to contain_exactly(public_group.name, group1.name)
      end
    end

    context "when using sorting" do
      let(:group3) { create(:group, name: "a#{group1.name}", path: "z#{group1.path}") }
      let(:group4) { create(:group, name: "same-name", path: "y#{group1.path}") }
      let(:group5) { create(:group, name: "same-name") }
      let(:response_groups) { json_response.map { |group| group['name'] } }
      let(:response_groups_ids) { json_response.map { |group| group['id'] } }

      before do
        group3.add_owner(user1)
        group4.add_owner(user1)
        group5.add_owner(user1)
      end

      it "sorts by name ascending by default" do
        get api("/groups", user1)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq(groups_visible_to_user(user1).order(:name).pluck(:name))
      end

      it "sorts in descending order when passed" do
        get api("/groups", user1), params: { sort: "desc" }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq(groups_visible_to_user(user1).order(name: :desc).pluck(:name))
      end

      it "sorts by path in order_by param" do
        get api("/groups", user1), params: { order_by: "path" }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq(groups_visible_to_user(user1).order(:path).pluck(:name))
      end

      it "sorts by id in the order_by param" do
        get api("/groups", user1), params: { order_by: "id" }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq(groups_visible_to_user(user1).order(:id).pluck(:name))
      end

      it "sorts also by descending id with pagination fix" do
        get api("/groups", user1), params: { order_by: "id", sort: "desc" }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq(groups_visible_to_user(user1).order(id: :desc).pluck(:name))
      end

      it "sorts identical keys by id for good pagination" do
        get api("/groups", user1), params: { search: "same-name", order_by: "name" }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups_ids).to eq(Group.select { |group| group['name'] == 'same-name' }.map { |group| group['id'] }.sort)
      end

      it "sorts descending identical keys by id for good pagination" do
        get api("/groups", user1), params: { search: "same-name", order_by: "name", sort: "desc" }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups_ids).to eq(Group.select { |group| group['name'] == 'same-name' }.map { |group| group['id'] }.sort)
      end

      def groups_visible_to_user(user)
        Group.where(id: user.authorized_groups.select(:id).reorder(nil))
      end
    end

    context 'when using owned in the request' do
      it 'returns an array of groups the user owns' do
        group1.add_maintainer(user2)

        get api('/groups', user2), params: { owned: true }

        expect(response).to have_gitlab_http_status(200)
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
        group3.add_master(user2)
      end

      it 'returns an array of groups the user has at least master access' do
        get api('/groups', user2), params: { min_access_level: 40 }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq([group2.id, group3.id])
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

        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns 200 for a public group' do
        get api("/groups/#{group1.id}")

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).not_to include('runners_token')
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

        get api("/groups/#{group1.id}", user1)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['id']).to eq(group1.id)
        expect(json_response['name']).to eq(group1.name)
        expect(json_response['path']).to eq(group1.path)
        expect(json_response['description']).to eq(group1.description)
        expect(json_response['visibility']).to eq(Gitlab::VisibilityLevel.string_level(group1.visibility_level))
        expect(json_response['avatar_url']).to eq(group1.avatar_url(only_path: false))
        expect(json_response['share_with_group_lock']).to eq(group1.share_with_group_lock)
        expect(json_response['require_two_factor_authentication']).to eq(group1.require_two_factor_authentication)
        expect(json_response['two_factor_grace_period']).to eq(group1.two_factor_grace_period)
        expect(json_response['auto_devops_enabled']).to eq(group1.auto_devops_enabled)
        expect(json_response['emails_disabled']).to eq(group1.emails_disabled)
        expect(json_response['project_creation_level']).to eq('maintainer')
        expect(json_response['subgroup_creation_level']).to eq('maintainer')
        expect(json_response['web_url']).to eq(group1.web_url)
        expect(json_response['request_access_enabled']).to eq(group1.request_access_enabled)
        expect(json_response['full_name']).to eq(group1.full_name)
        expect(json_response['full_path']).to eq(group1.full_path)
        expect(json_response['parent_id']).to eq(group1.parent_id)
        expect(json_response['projects']).to be_an Array
        expect(json_response['projects'].length).to eq(2)
        expect(json_response['shared_projects']).to be_an Array
        expect(json_response['shared_projects'].length).to eq(1)
        expect(json_response['shared_projects'][0]['id']).to eq(project.id)
      end

      it "returns one of user1's groups without projects when with_projects option is set to false" do
        project = create(:project, namespace: group2, path: 'Foo')
        create(:project_group_link, project: project, group: group1)

        get api("/groups/#{group1.id}", user1), params: { with_projects: false }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['projects']).to be_nil
        expect(json_response['shared_projects']).to be_nil
        expect(json_response).not_to include('runners_token')
      end

      it "doesn't return runners_token if the user is not the owner of the group" do
        get api("/groups/#{group1.id}", user3)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).not_to include('runners_token')
      end

      it "returns runners_token if the user is the owner of the group" do
        group1.add_owner(user3)
        get api("/groups/#{group1.id}", user3)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to include('runners_token')
      end

      it "does not return a non existing group" do
        get api("/groups/1328", user1)

        expect(response).to have_gitlab_http_status(404)
      end

      it "does not return a group not attached to user1" do
        get api("/groups/#{group2.id}", user1)

        expect(response).to have_gitlab_http_status(404)
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

      it 'avoids N+1 queries' do
        get api("/groups/#{group1.id}", admin)

        control_count = ActiveRecord::QueryRecorder.new do
          get api("/groups/#{group1.id}", admin)
        end.count

        create(:project, namespace: group1)

        expect do
          get api("/groups/#{group1.id}", admin)
        end.not_to exceed_query_limit(control_count)
      end
    end

    context "when authenticated as admin" do
      it "returns any existing group" do
        get api("/groups/#{group2.id}", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq(group2.name)
      end

      it "returns information of the runners_token for the group" do
        get api("/groups/#{group2.id}", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to include('runners_token')
      end

      it "does not return a non existing group" do
        get api("/groups/1328", admin)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when using group path in URL' do
      it 'returns any existing group' do
        get api("/groups/#{group1.path}", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq(group1.name)
      end

      it 'does not return a non existing group' do
        get api('/groups/unknown', admin)

        expect(response).to have_gitlab_http_status(404)
      end

      it 'does not return a group not attached to user1' do
        get api("/groups/#{group2.path}", user1)

        expect(response).to have_gitlab_http_status(404)
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

      context 'when limiting feature is enabled' do
        before do
          stub_feature_flags(limit_projects_in_groups_api: true)
        end

        it 'limits projects and shared_projects' do
          get api("/groups/#{group1.id}")

          expect(json_response['projects'].count).to eq(limit)
          expect(json_response['shared_projects'].count).to eq(limit)
        end
      end

      context 'when limiting feature is not enabled' do
        before do
          stub_feature_flags(limit_projects_in_groups_api: false)
        end

        it 'does not limit projects and shared_projects' do
          get api("/groups/#{group1.id}")

          expect(json_response['projects'].count).to eq(3)
          expect(json_response['shared_projects'].count).to eq(3)
        end
      end
    end
  end

  describe 'PUT /groups/:id' do
    let(:new_group_name) { 'New Group'}

    context 'when authenticated as the group owner' do
      it 'updates the group' do
        put api("/groups/#{group1.id}", user1), params: {
          name: new_group_name,
          request_access_enabled: true,
          project_creation_level: "noone",
          subgroup_creation_level: "maintainer"
        }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq(new_group_name)
        expect(json_response['description']).to eq('')
        expect(json_response['visibility']).to eq('public')
        expect(json_response['share_with_group_lock']).to eq(false)
        expect(json_response['require_two_factor_authentication']).to eq(false)
        expect(json_response['two_factor_grace_period']).to eq(48)
        expect(json_response['auto_devops_enabled']).to eq(nil)
        expect(json_response['emails_disabled']).to eq(nil)
        expect(json_response['project_creation_level']).to eq("noone")
        expect(json_response['subgroup_creation_level']).to eq("maintainer")
        expect(json_response['request_access_enabled']).to eq(true)
        expect(json_response['parent_id']).to eq(nil)
        expect(json_response['projects']).to be_an Array
        expect(json_response['projects'].length).to eq(2)
        expect(json_response['shared_projects']).to be_an Array
        expect(json_response['shared_projects'].length).to eq(0)
      end

      it 'returns 404 for a non existing group' do
        put api('/groups/1328', user1), params: { name: new_group_name }

        expect(response).to have_gitlab_http_status(404)
      end

      context 'within a subgroup' do
        let(:group3) { create(:group, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
        let!(:subgroup) { create(:group, parent: group3, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }

        before do
          group3.add_owner(user3)
        end

        it 'does not change visibility when not requested' do
          put api("/groups/#{group3.id}", user3), params: { description: 'Bug #23083' }

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['visibility']).to eq('public')
        end

        it 'prevents making private a group containing public subgroups' do
          put api("/groups/#{group3.id}", user3), params: { visibility: 'private' }

          expect(response).to have_gitlab_http_status(400)
          expect(json_response['message']['visibility_level']).to contain_exactly('private is not allowed since there are sub-groups with higher visibility.')
        end
      end
    end

    context 'when authenticated as the admin' do
      it 'updates the group' do
        put api("/groups/#{group1.id}", admin), params: { name: new_group_name }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq(new_group_name)
      end
    end

    context 'when authenticated as an user that can see the group' do
      it 'does not updates the group' do
        put api("/groups/#{group1.id}", user2), params: { name: new_group_name }

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when authenticated as an user that cannot see the group' do
      it 'returns 404 when trying to update the group' do
        put api("/groups/#{group2.id}", user1), params: { name: new_group_name }

        expect(response).to have_gitlab_http_status(404)
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

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(2)
        project_names = json_response.map { |proj| proj['name'] }
        expect(project_names).to match_array([project1.name, project3.name])
        expect(json_response.first['visibility']).to be_present
      end

      it "returns the group's projects with simple representation" do
        get api("/groups/#{group1.id}/projects", user1), params: { simple: true }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(2)
        project_names = json_response.map { |proj| proj['name'] }
        expect(project_names).to match_array([project1.name, project3.name])
        expect(json_response.first['visibility']).not_to be_present
      end

      it "filters the groups projects" do
        public_project = create(:project, :public, path: 'test1', group: group1)

        get api("/groups/#{group1.id}/projects", user1), params: { visibility: 'public' }

        expect(response).to have_gitlab_http_status(200)
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

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(2)
      end

      it "returns projects including those in subgroups" do
        subgroup = create(:group, parent: group1)
        create(:project, group: subgroup)
        create(:project, group: subgroup)

        get api("/groups/#{group1.id}/projects", user1), params: { include_subgroups: true }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(4)
      end

      it "does not return a non existing group" do
        get api("/groups/1328/projects", user1)

        expect(response).to have_gitlab_http_status(404)
      end

      it "does not return a group not attached to user1" do
        get api("/groups/#{group2.id}/projects", user1)

        expect(response).to have_gitlab_http_status(404)
      end

      it "only returns projects to which user has access" do
        project3.add_developer(user3)

        get api("/groups/#{group1.id}/projects", user3)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project3.name)
      end

      it 'only returns the projects owned by user' do
        project2.group.add_owner(user3)

        get api("/groups/#{project2.group.id}/projects", user3), params: { owned: true }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project2.name)
      end

      it 'only returns the projects starred by user' do
        user1.starred_projects = [project1]

        get api("/groups/#{group1.id}/projects", user1), params: { starred: true }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project1.name)
      end
    end

    context "when authenticated as admin" do
      it "returns any existing group" do
        get api("/groups/#{group2.id}/projects", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project2.name)
      end

      it "does not return a non existing group" do
        get api("/groups/1328/projects", admin)

        expect(response).to have_gitlab_http_status(404)
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

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        project_names = json_response.map { |proj| proj['name'] }
        expect(project_names).to match_array([project1.name, project3.name])
      end

      it 'does not return a non existing group' do
        get api('/groups/unknown/projects', admin)

        expect(response).to have_gitlab_http_status(404)
      end

      it 'does not return a group not attached to user1' do
        get api("/groups/#{group2.path}/projects", user1)

        expect(response).to have_gitlab_http_status(404)
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

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(subgroup1.id)
        expect(json_response.first['parent_id']).to eq(group1.id)
      end

      it 'returns 404 for a private group' do
        get api("/groups/#{group2.id}/subgroups")

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when authenticated as user' do
      context 'when user is not member of a public group' do
        it 'returns no subgroups for the public group' do
          get api("/groups/#{group1.id}/subgroups", user2)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(0)
        end

        context 'when using all_available in request' do
          it 'returns public subgroups' do
            get api("/groups/#{group1.id}/subgroups", user2), params: { all_available: true }

            expect(response).to have_gitlab_http_status(200)
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

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when user is member of public group' do
        before do
          group1.add_guest(user2)
        end

        it 'returns private subgroups' do
          get api("/groups/#{group1.id}/subgroups", user2)

          expect(response).to have_gitlab_http_status(200)
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

            expect(response).to have_gitlab_http_status(200)
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

          expect(response).to have_gitlab_http_status(200)
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

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
      end

      it 'returns subgroups of a private group' do
        get api("/groups/#{group2.id}/subgroups", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
      end

      it 'does not include statistics by default' do
        get api("/groups/#{group1.id}/subgroups", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include('statistics')
      end

      it 'includes statistics if requested' do
        get api("/groups/#{group1.id}/subgroups", admin), params: { statistics: true }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first).to include('statistics')
      end
    end
  end

  describe "POST /groups" do
    context "when authenticated as user without group permissions" do
      it "does not create group" do
        group = attributes_for_group_api

        post api("/groups", user1), params: group

        expect(response).to have_gitlab_http_status(403)
      end

      context 'as owner' do
        before do
          group2.add_owner(user1)
        end

        it 'can create subgroups' do
          post api("/groups", user1), params: { parent_id: group2.id, name: 'foo', path: 'foo' }

          expect(response).to have_gitlab_http_status(201)
        end
      end

      context 'as maintainer' do
        before do
          group2.add_maintainer(user1)
        end

        it 'can create subgroups' do
          post api("/groups", user1), params: { parent_id: group2.id, name: 'foo', path: 'foo' }

          expect(response).to have_gitlab_http_status(201)
        end
      end
    end

    context "when authenticated as user with group permissions" do
      it "creates group" do
        group = attributes_for_group_api request_access_enabled: false

        post api("/groups", user3), params: group

        expect(response).to have_gitlab_http_status(201)

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

        expect(response).to have_gitlab_http_status(201)

        expect(json_response["full_path"]).to eq("#{parent.path}/#{group[:path]}")
        expect(json_response["parent_id"]).to eq(parent.id)
      end

      it "does not create group, duplicate" do
        post api("/groups", user3), params: { name: 'Duplicate Test', path: group2.path }

        expect(response).to have_gitlab_http_status(400)
        expect(response.message).to eq("Bad Request")
      end

      it "returns 400 bad request error if name not given" do
        post api("/groups", user3), params: { path: group2.path }

        expect(response).to have_gitlab_http_status(400)
      end

      it "returns 400 bad request error if path not given" do
        post api("/groups", user3), params: { name: 'test' }

        expect(response).to have_gitlab_http_status(400)
      end
    end
  end

  describe "DELETE /groups/:id" do
    context "when authenticated as user" do
      it "removes group" do
        Sidekiq::Testing.fake! do
          expect { delete api("/groups/#{group1.id}", user1) }.to change(GroupDestroyWorker.jobs, :size).by(1)
        end

        expect(response).to have_gitlab_http_status(202)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/groups/#{group1.id}", user1) }
        let(:success_status) { 202 }
      end

      it "does not remove a group if not an owner" do
        user4 = create(:user)
        group1.add_maintainer(user4)

        delete api("/groups/#{group1.id}", user3)

        expect(response).to have_gitlab_http_status(403)
      end

      it "does not remove a non existing group" do
        delete api("/groups/1328", user1)

        expect(response).to have_gitlab_http_status(404)
      end

      it "does not remove a group not attached to user1" do
        delete api("/groups/#{group2.id}", user1)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context "when authenticated as admin" do
      it "removes any existing group" do
        delete api("/groups/#{group2.id}", admin)

        expect(response).to have_gitlab_http_status(202)
      end

      it "does not remove a non existing group" do
        delete api("/groups/1328", admin)

        expect(response).to have_gitlab_http_status(404)
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

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context "when authenticated as admin" do
      it "transfers project to group" do
        post api("/groups/#{group1.id}/projects/#{project.id}", admin)

        expect(response).to have_gitlab_http_status(201)
      end

      context 'when using project path in URL' do
        context 'with a valid project path' do
          it "transfers project to group" do
            post api("/groups/#{group1.id}/projects/#{project_path}", admin)

            expect(response).to have_gitlab_http_status(201)
          end
        end

        context 'with a non-existent project path' do
          it "does not transfer project to group" do
            post api("/groups/#{group1.id}/projects/nogroup%2Fnoproject", admin)

            expect(response).to have_gitlab_http_status(404)
          end
        end
      end

      context 'when using a group path in URL' do
        context 'with a valid group path' do
          it "transfers project to group" do
            post api("/groups/#{group1.path}/projects/#{project_path}", admin)

            expect(response).to have_gitlab_http_status(201)
          end
        end

        context 'with a non-existent group path' do
          it "does not transfer project to group" do
            post api("/groups/noexist/projects/#{project_path}", admin)

            expect(response).to have_gitlab_http_status(404)
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
end
