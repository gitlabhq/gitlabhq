require 'spec_helper'

describe API::Groups do
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

      it "does not include statistics" do
        get api("/groups", user1), statistics: true

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

      it "does not include statistics by default" do
        get api("/groups", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include('statistics')
      end

      it "includes statistics if requested" do
        attributes = {
          storage_size: 702,
          repository_size: 123,
          lfs_objects_size: 234,
          build_artifacts_size: 345
        }.stringify_keys
        exposed_attributes = attributes.dup
        exposed_attributes['job_artifacts_size'] = exposed_attributes.delete('build_artifacts_size')

        project1.statistics.update!(attributes)

        get api("/groups", admin), statistics: true

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response)
          .to satisfy_one { |group| group['statistics'] == exposed_attributes }
      end
    end

    context "when using skip_groups in request" do
      it "returns all groups excluding skipped groups" do
        get api("/groups", admin), skip_groups: [group2.id]

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

        get api("/groups", user1), all_available: true

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to contain_exactly(public_group.name, group1.name)
      end
    end

    context "when using sorting" do
      let(:group3) { create(:group, name: "a#{group1.name}", path: "z#{group1.path}") }
      let(:response_groups) { json_response.map { |group| group['name'] } }

      before do
        group3.add_owner(user1)
      end

      it "sorts by name ascending by default" do
        get api("/groups", user1)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq([group3.name, group1.name])
      end

      it "sorts in descending order when passed" do
        get api("/groups", user1), sort: "desc"

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq([group1.name, group3.name])
      end

      it "sorts by the order_by param" do
        get api("/groups", user1), order_by: "path"

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(response_groups).to eq([group1.name, group3.name])
      end
    end

    context 'when using owned in the request' do
      it 'returns an array of groups the user owns' do
        group1.add_master(user2)

        get api('/groups', user2), owned: true

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(group2.name)
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

    context 'when unauthenticated' do
      it 'returns 404 for a private group' do
        get api("/groups/#{group2.id}")
        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns 200 for a public group' do
        get api("/groups/#{group1.id}")
        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns only public projects in the group' do
        public_group = create(:group, :public)
        projects = add_projects_to_group(public_group)

        get api("/groups/#{public_group.id}")

        expect(json_response['projects'].map { |p| p['id'].to_i })
          .to contain_exactly(projects[:public].id)
      end

      it 'returns only public projects shared with the group' do
        public_group = create(:group, :public)
        projects = add_projects_to_group(public_group, share_with: group1)

        get api("/groups/#{group1.id}")

        expect(json_response['shared_projects'].map { |p| p['id'].to_i })
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

        expect(json_response['projects'].map { |p| p['id'].to_i })
          .to contain_exactly(projects[:public].id, projects[:internal].id)
      end

      it 'returns only public and internal projects shared with the group' do
        public_group = create(:group, :public)
        projects = add_projects_to_group(public_group, share_with: group1)

        get api("/groups/#{group1.id}", user2)

        expect(json_response['shared_projects'].map { |p| p['id'].to_i })
          .to contain_exactly(projects[:public].id, projects[:internal].id)
      end
    end

    context "when authenticated as admin" do
      it "returns any existing group" do
        get api("/groups/#{group2.id}", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq(group2.name)
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
  end

  describe 'PUT /groups/:id' do
    let(:new_group_name) { 'New Group'}

    context 'when authenticated as the group owner' do
      it 'updates the group' do
        put api("/groups/#{group1.id}", user1), name: new_group_name, request_access_enabled: true

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq(new_group_name)
        expect(json_response['request_access_enabled']).to eq(true)
      end

      it 'returns 404 for a non existing group' do
        put api('/groups/1328', user1), name: new_group_name

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when authenticated as the admin' do
      it 'updates the group' do
        put api("/groups/#{group1.id}", admin), name: new_group_name

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq(new_group_name)
      end
    end

    context 'when authenticated as an user that can see the group' do
      it 'does not updates the group' do
        put api("/groups/#{group1.id}", user2), name: new_group_name

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when authenticated as an user that cannot see the group' do
      it 'returns 404 when trying to update the group' do
        put api("/groups/#{group2.id}", user1), name: new_group_name

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe "GET /groups/:id/projects" do
    context "when authenticated as user" do
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
        get api("/groups/#{group1.id}/projects", user1), simple: true

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(2)
        project_names = json_response.map { |proj| proj['name'] }
        expect(project_names).to match_array([project1.name, project3.name])
        expect(json_response.first['visibility']).not_to be_present
      end

      it 'filters the groups projects' do
        public_project = create(:project, :public, path: 'test1', group: group1)

        get api("/groups/#{group1.id}/projects", user1), visibility: 'public'

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(public_project.name)
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

        get api("/groups/#{project2.group.id}/projects", user3), owned: true

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project2.name)
      end

      it 'only returns the projects starred by user' do
        user1.starred_projects = [project1]

        get api("/groups/#{group1.id}/projects", user1), starred: true

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

  describe 'GET /groups/:id/subgroups', :nested_groups do
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
            get api("/groups/#{group1.id}/subgroups", user2), all_available: true

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
            get api("/groups/#{group1.id}/subgroups", user2), statistics: true

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
        get api("/groups/#{group1.id}/subgroups", admin), statistics: true

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first).to include('statistics')
      end
    end
  end

  describe "POST /groups" do
    context "when authenticated as user without group permissions" do
      it "does not create group" do
        post api("/groups", user1), attributes_for(:group)

        expect(response).to have_gitlab_http_status(403)
      end

      context 'as owner', :nested_groups do
        before do
          group2.add_owner(user1)
        end

        it 'can create subgroups' do
          post api("/groups", user1), parent_id: group2.id, name: 'foo', path: 'foo'

          expect(response).to have_gitlab_http_status(201)
        end
      end

      context 'as master', :nested_groups do
        before do
          group2.add_master(user1)
        end

        it 'cannot create subgroups' do
          post api("/groups", user1), parent_id: group2.id, name: 'foo', path: 'foo'

          expect(response).to have_gitlab_http_status(403)
        end
      end
    end

    context "when authenticated as user with group permissions" do
      it "creates group" do
        group = attributes_for(:group, { request_access_enabled: false })

        post api("/groups", user3), group

        expect(response).to have_gitlab_http_status(201)

        expect(json_response["name"]).to eq(group[:name])
        expect(json_response["path"]).to eq(group[:path])
        expect(json_response["request_access_enabled"]).to eq(group[:request_access_enabled])
        expect(json_response["visibility"]).to eq(Gitlab::VisibilityLevel.string_level(Gitlab::CurrentSettings.current_application_settings.default_group_visibility))
      end

      it "creates a nested group", :nested_groups do
        parent = create(:group)
        parent.add_owner(user3)
        group = attributes_for(:group, { parent_id: parent.id })

        post api("/groups", user3), group

        expect(response).to have_gitlab_http_status(201)

        expect(json_response["full_path"]).to eq("#{parent.path}/#{group[:path]}")
        expect(json_response["parent_id"]).to eq(parent.id)
      end

      it "does not create group, duplicate" do
        post api("/groups", user3), { name: 'Duplicate Test', path: group2.path }

        expect(response).to have_gitlab_http_status(400)
        expect(response.message).to eq("Bad Request")
      end

      it "returns 400 bad request error if name not given" do
        post api("/groups", user3), { path: group2.path }

        expect(response).to have_gitlab_http_status(400)
      end

      it "returns 400 bad request error if path not given" do
        post api("/groups", user3), { name: 'test' }

        expect(response).to have_gitlab_http_status(400)
      end
    end
  end

  describe "DELETE /groups/:id" do
    context "when authenticated as user" do
      it "removes group" do
        delete api("/groups/#{group1.id}", user1)

        expect(response).to have_gitlab_http_status(204)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/groups/#{group1.id}", user1) }
      end

      it "does not remove a group if not an owner" do
        user4 = create(:user)
        group1.add_master(user4)

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

        expect(response).to have_gitlab_http_status(204)
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
      allow_any_instance_of(Projects::TransferService)
        .to receive(:execute).and_return(true)
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
