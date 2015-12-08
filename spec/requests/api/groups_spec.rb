require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  let(:user1) { create(:user, can_create_group: false) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:admin) { create(:admin) }
  let(:avatar_file_path) { File.join(Rails.root, 'spec', 'fixtures', 'banana_sample.gif') }
  let!(:group1) { create(:group, avatar: File.open(avatar_file_path)) }
  let!(:group2) { create(:group) }
  let!(:project1) { create(:project, namespace: group1) }
  let!(:project2) { create(:project, namespace: group2) }

  before do
    group1.add_owner(user1)
    group2.add_owner(user2)
  end

  describe "GET /groups" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/groups")
        expect(response.status).to eq(401)
      end
    end

    context "when authenticated as user" do
      it "normal user: should return an array of groups of user1" do
        get api("/groups", user1)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(group1.name)
      end
    end

    context "when authenticated as  admin" do
      it "admin: should return an array of all groups" do
        get api("/groups", admin)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
      end
    end
  end

  describe "GET /groups/:id" do
    context "when authenticated as user" do
      it "should return one of user1's groups" do
        get api("/groups/#{group1.id}", user1)
        expect(response.status).to eq(200)
        json_response['name'] == group1.name
      end

      it "should not return a non existing group" do
        get api("/groups/1328", user1)
        expect(response.status).to eq(404)
      end

      it "should not return a group not attached to user1" do
        get api("/groups/#{group2.id}", user1)
        expect(response.status).to eq(403)
      end
    end

    context "when authenticated as admin" do
      it "should return any existing group" do
        get api("/groups/#{group2.id}", admin)
        expect(response.status).to eq(200)
        expect(json_response['name']).to eq(group2.name)
      end

      it "should not return a non existing group" do
        get api("/groups/1328", admin)
        expect(response.status).to eq(404)
      end
    end

    context 'when using group path in URL' do
      it 'should return any existing group' do
        get api("/groups/#{group1.path}", admin)
        expect(response.status).to eq(200)
        expect(json_response['name']).to eq(group1.name)
      end

      it 'should not return a non existing group' do
        get api('/groups/unknown', admin)
        expect(response.status).to eq(404)
      end

      it 'should not return a group not attached to user1' do
        get api("/groups/#{group2.path}", user1)
        expect(response.status).to eq(403)
      end
    end
  end

  describe "GET /groups/:id/projects" do
    context "when authenticated as user" do
      it "should return the group's projects" do
        get api("/groups/#{group1.id}/projects", user1)
        expect(response.status).to eq(200)
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project1.name)
      end

      it "should not return a non existing group" do
        get api("/groups/1328/projects", user1)
        expect(response.status).to eq(404)
      end

      it "should not return a group not attached to user1" do
        get api("/groups/#{group2.id}/projects", user1)
        expect(response.status).to eq(403)
      end
    end

    context "when authenticated as admin" do
      it "should return any existing group" do
        get api("/groups/#{group2.id}/projects", admin)
        expect(response.status).to eq(200)
        expect(json_response.length).to eq(1)
        expect(json_response.first['name']).to eq(project2.name)
      end

      it "should not return a non existing group" do
        get api("/groups/1328/projects", admin)
        expect(response.status).to eq(404)
      end
    end

    context 'when using group path in URL' do
      it 'should return any existing group' do
        get api("/groups/#{group1.path}/projects", admin)
        expect(response.status).to eq(200)
        expect(json_response.first['name']).to eq(project1.name)
      end

      it 'should not return a non existing group' do
        get api('/groups/unknown/projects', admin)
        expect(response.status).to eq(404)
      end

      it 'should not return a group not attached to user1' do
        get api("/groups/#{group2.path}/projects", user1)
        expect(response.status).to eq(403)
      end
    end
  end

  describe "POST /groups" do
    context "when authenticated as user without group permissions" do
      it "should not create group" do
        post api("/groups", user1), attributes_for(:group)
        expect(response.status).to eq(403)
      end
    end

    context "when authenticated as user with group permissions" do
      it "should create group" do
        post api("/groups", user3), attributes_for(:group)
        expect(response.status).to eq(201)
      end

      it "should not create group, duplicate" do
        post api("/groups", user3), { name: 'Duplicate Test', path: group2.path }
        expect(response.status).to eq(400)
        expect(response.message).to eq("Bad Request")
      end

      it "should return 400 bad request error if name not given" do
        post api("/groups", user3), { path: group2.path }
        expect(response.status).to eq(400)
      end

      it "should return 400 bad request error if path not given" do
        post api("/groups", user3), { name: 'test' }
        expect(response.status).to eq(400)
      end
    end
  end

  describe "DELETE /groups/:id" do
    context "when authenticated as user" do
      it "should remove group" do
        delete api("/groups/#{group1.id}", user1)
        expect(response.status).to eq(200)
      end

      it "should not remove a group if not an owner" do
        user4 = create(:user)
        group1.add_master(user4)
        delete api("/groups/#{group1.id}", user3)
        expect(response.status).to eq(403)
      end

      it "should not remove a non existing group" do
        delete api("/groups/1328", user1)
        expect(response.status).to eq(404)
      end

      it "should not remove a group not attached to user1" do
        delete api("/groups/#{group2.id}", user1)
        expect(response.status).to eq(403)
      end
    end

    context "when authenticated as admin" do
      it "should remove any existing group" do
        delete api("/groups/#{group2.id}", admin)
        expect(response.status).to eq(200)
      end

      it "should not remove a non existing group" do
        delete api("/groups/1328", admin)
        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST /groups/:id/projects/:project_id" do
    let(:project) { create(:project) }
    before(:each) do
      allow_any_instance_of(Projects::TransferService).
        to receive(:execute).and_return(true)
      allow(Project).to receive(:find).and_return(project)
    end

    context "when authenticated as user" do
      it "should not transfer project to group" do
        post api("/groups/#{group1.id}/projects/#{project.id}", user2)
        expect(response.status).to eq(403)
      end
    end

    context "when authenticated as admin" do
      it "should transfer project to group" do
        post api("/groups/#{group1.id}/projects/#{project.id}", admin)
        expect(response.status).to eq(201)
      end
    end
  end
end
