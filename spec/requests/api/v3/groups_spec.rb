require 'spec_helper'

describe API::V3::Groups do
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
      it "returns authentication error" do
        get v3_api("/groups")

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context "when authenticated as user" do
      it "normal user: returns an array of groups of user1" do
        get v3_api("/groups", user1)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response)
          .to satisfy_one { |group| group['name'] == group1.name }
      end

      it "does not include statistics" do
        get v3_api("/groups", user1), statistics: true

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include 'statistics'
      end
    end

    context "when authenticated as admin" do
      it "admin: returns an array of all groups" do
        get v3_api("/groups", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
      end

      it "does not include statistics by default" do
        get v3_api("/groups", admin)

        expect(response).to have_gitlab_http_status(200)
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

        project1.statistics.update!(attributes)

        get v3_api("/groups", admin), statistics: true

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response)
          .to satisfy_one { |group| group['statistics'] == attributes }
      end
    end

    context "when using skip_groups in request" do
      it "returns all groups excluding skipped groups" do
        get v3_api("/groups", admin), skip_groups: [group2.id]

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
      end
    end

    context "when using all_available in request" do
      let(:response_groups) { json_response.map { |group| group['name'] } }

      it "returns all groups you have access to" do
        public_group = create :group, :public

        get v3_api("/groups", user1), all_available: true

        expect(response).to have_gitlab_http_status(200)
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
        get v3_api("/groups", user1)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(response_groups).to eq([group3.name, group1.name])
      end

      it "sorts in descending order when passed" do
        get v3_api("/groups", user1), sort: "desc"

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(response_groups).to eq([group1.name, group3.name])
      end

      it "sorts by the order_by param" do
        get v3_api("/groups", user1), order_by: "path"

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(response_groups).to eq([group1.name, group3.name])
      end
    end
  end

  describe 'GET /groups/owned' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        get v3_api('/groups/owned')

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when authenticated as group owner' do
      it 'returns an array of groups the user owns' do
        get v3_api('/groups/owned', user2)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['name']).to eq(group2.name)
      end
    end
  end

  describe "GET /groups/:id" do
    context "when authenticated as user" do
      it "returns one of user1's groups" do
        project = create(:project, namespace: group2, path: 'Foo')
        create(:project_group_link, project: project, group: group1)

        get v3_api("/groups/#{group1.id}", user1)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['id']).to eq(group1.id)
        expect(json_response['name']).to eq(group1.name)
        expect(json_response['path']).to eq(group1.path)
        expect(json_response['description']).to eq(group1.description)
        expect(json_response['visibility_level']).to eq(group1.visibility_level)
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
        get v3_api("/groups/1328", user1)

        expect(response).to have_gitlab_http_status(404)
      end

      it "does not return a group not attached to user1" do
        get v3_api("/groups/#{group2.id}", user1)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context "when authenticated as admin" do
      it "returns any existing group" do
        get v3_api("/groups/#{group2.id}", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq(group2.name)
      end

      it "does not return a non existing group" do
        get v3_api("/groups/1328", admin)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when using group path in URL' do
      it 'returns any existing group' do
        get v3_api("/groups/#{group1.path}", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq(group1.name)
      end

      it 'does not return a non existing group' do
        get v3_api('/groups/unknown', admin)

        expect(response).to have_gitlab_http_status(404)
      end

      it 'does not return a group not attached to user1' do
        get v3_api("/groups/#{group2.path}", user1)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'PUT /groups/:id' do
    let(:new_group_name) { 'New Group'}

    context 'when authenticated as the group owner' do
      it 'updates the group' do
        put v3_api("/groups/#{group1.id}", user1), name: new_group_name, request_access_enabled: true

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq(new_group_name)
        expect(json_response['request_access_enabled']).to eq(true)
      end

      it 'returns 404 for a non existing group' do
        put v3_api('/groups/1328', user1), name: new_group_name

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when authenticated as the admin' do
      it 'updates the group' do
        put v3_api("/groups/#{group1.id}", admin), name: new_group_name

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq(new_group_name)
      end
    end

    context 'when authenticated as an user that can see the group' do
      it 'does not updates the group' do
        put v3_api("/groups/#{group1.id}", user2), name: new_group_name

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when authenticated as an user that cannot see the group' do
      it 'returns 404 when trying to update the group' do
        put v3_api("/groups/#{group2.id}", user1), name: new_group_name

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe "GET /groups/:id/projects" do
    context "when authenticated as user" do
      it "returns the group's projects" do
        get v3_api("/groups/#{group1.id}/projects", user1)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.length).to eq(2)
        project_names = json_response.map { |proj| proj['name'] }
        expect(project_names).to match_array([project1.name, project3.name])
        expect(json_response.first['visibility_level']).to be_present
      end

      it "returns the group's projects with simple representation" do
        get v3_api("/groups/#{group1.id}/projects", user1), simple: true

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.length).to eq(2)
        project_names = json_response.map { |proj| proj['name'] }
        expect(project_names).to match_array([project1.name, project3.name])
        expect(json_response.first['visibility_level']).not_to be_present
      end

      it 'filters the groups projects' do
        public_project = create(:project, :public, path: 'test1', group: group1)

        get v3_api("/groups/#{group1.id}/projects", user1), visibility: 'public'

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(public_project.name)
      end

      it "does not return a non existing group" do
        get v3_api("/groups/1328/projects", user1)

        expect(response).to have_gitlab_http_status(404)
      end

      it "does not return a group not attached to user1" do
        get v3_api("/groups/#{group2.id}/projects", user1)

        expect(response).to have_gitlab_http_status(404)
      end

      it "only returns projects to which user has access" do
        project3.add_developer(user3)

        get v3_api("/groups/#{group1.id}/projects", user3)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project3.name)
      end

      it 'only returns the projects owned by user' do
        project2.group.add_owner(user3)

        get v3_api("/groups/#{project2.group.id}/projects", user3), owned: true

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project2.name)
      end

      it 'only returns the projects starred by user' do
        user1.starred_projects = [project1]

        get v3_api("/groups/#{group1.id}/projects", user1), starred: true

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project1.name)
      end
    end

    context "when authenticated as admin" do
      it "returns any existing group" do
        get v3_api("/groups/#{group2.id}/projects", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project2.name)
      end

      it "does not return a non existing group" do
        get v3_api("/groups/1328/projects", admin)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when using group path in URL' do
      it 'returns any existing group' do
        get v3_api("/groups/#{group1.path}/projects", admin)

        expect(response).to have_gitlab_http_status(200)
        project_names = json_response.map { |proj| proj['name'] }
        expect(project_names).to match_array([project1.name, project3.name])
      end

      it 'does not return a non existing group' do
        get v3_api('/groups/unknown/projects', admin)

        expect(response).to have_gitlab_http_status(404)
      end

      it 'does not return a group not attached to user1' do
        get v3_api("/groups/#{group2.path}/projects", user1)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe "POST /groups" do
    context "when authenticated as user without group permissions" do
      it "does not create group" do
        post v3_api("/groups", user1), attributes_for(:group)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context "when authenticated as user with group permissions" do
      it "creates group" do
        group = attributes_for(:group, { request_access_enabled: false })

        post v3_api("/groups", user3), group

        expect(response).to have_gitlab_http_status(201)

        expect(json_response["name"]).to eq(group[:name])
        expect(json_response["path"]).to eq(group[:path])
        expect(json_response["request_access_enabled"]).to eq(group[:request_access_enabled])
      end

      it "creates a nested group", :nested_groups do
        parent = create(:group)
        parent.add_owner(user3)
        group = attributes_for(:group, { parent_id: parent.id })

        post v3_api("/groups", user3), group

        expect(response).to have_gitlab_http_status(201)

        expect(json_response["full_path"]).to eq("#{parent.path}/#{group[:path]}")
        expect(json_response["parent_id"]).to eq(parent.id)
      end

      it "does not create group, duplicate" do
        post v3_api("/groups", user3), { name: 'Duplicate Test', path: group2.path }

        expect(response).to have_gitlab_http_status(400)
        expect(response.message).to eq("Bad Request")
      end

      it "returns 400 bad request error if name not given" do
        post v3_api("/groups", user3), { path: group2.path }

        expect(response).to have_gitlab_http_status(400)
      end

      it "returns 400 bad request error if path not given" do
        post v3_api("/groups", user3), { name: 'test' }

        expect(response).to have_gitlab_http_status(400)
      end
    end
  end

  describe "DELETE /groups/:id" do
    context "when authenticated as user" do
      it "removes group" do
        delete v3_api("/groups/#{group1.id}", user1)

        expect(response).to have_gitlab_http_status(200)
      end

      it "does not remove a group if not an owner" do
        user4 = create(:user)
        group1.add_master(user4)

        delete v3_api("/groups/#{group1.id}", user3)

        expect(response).to have_gitlab_http_status(403)
      end

      it "does not remove a non existing group" do
        delete v3_api("/groups/1328", user1)

        expect(response).to have_gitlab_http_status(404)
      end

      it "does not remove a group not attached to user1" do
        delete v3_api("/groups/#{group2.id}", user1)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context "when authenticated as admin" do
      it "removes any existing group" do
        delete v3_api("/groups/#{group2.id}", admin)

        expect(response).to have_gitlab_http_status(200)
      end

      it "does not remove a non existing group" do
        delete v3_api("/groups/1328", admin)

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
        post v3_api("/groups/#{group1.id}/projects/#{project.id}", user2)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context "when authenticated as admin" do
      it "transfers project to group" do
        post v3_api("/groups/#{group1.id}/projects/#{project.id}", admin)

        expect(response).to have_gitlab_http_status(201)
      end

      context 'when using project path in URL' do
        context 'with a valid project path' do
          it "transfers project to group" do
            post v3_api("/groups/#{group1.id}/projects/#{project_path}", admin)

            expect(response).to have_gitlab_http_status(201)
          end
        end

        context 'with a non-existent project path' do
          it "does not transfer project to group" do
            post v3_api("/groups/#{group1.id}/projects/nogroup%2Fnoproject", admin)

            expect(response).to have_gitlab_http_status(404)
          end
        end
      end

      context 'when using a group path in URL' do
        context 'with a valid group path' do
          it "transfers project to group" do
            post v3_api("/groups/#{group1.path}/projects/#{project_path}", admin)

            expect(response).to have_gitlab_http_status(201)
          end
        end

        context 'with a non-existent group path' do
          it "does not transfer project to group" do
            post v3_api("/groups/noexist/projects/#{project_path}", admin)

            expect(response).to have_gitlab_http_status(404)
          end
        end
      end
    end
  end
end
