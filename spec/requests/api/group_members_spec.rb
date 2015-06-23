require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  let(:owner) { create(:user) }
  let(:reporter) { create(:user) }
  let(:developer) { create(:user) }
  let(:master) { create(:user) }
  let(:guest) { create(:user) }
  let(:stranger) { create(:user) }

  let!(:group_with_members) do
    group = create(:group)
    group.add_users([reporter.id], GroupMember::REPORTER)
    group.add_users([developer.id], GroupMember::DEVELOPER)
    group.add_users([master.id], GroupMember::MASTER)
    group.add_users([guest.id], GroupMember::GUEST)
    group
  end

  let!(:group_no_members) { create(:group) }

  before do
    group_with_members.add_owner owner
    group_no_members.add_owner owner
  end

  describe "GET /groups/:id/members" do
    context "when authenticated as user that is part or the group" do
      it "each user: should return an array of members groups of group3" do
        [owner, master, developer, reporter, guest].each do |user|
          get api("/groups/#{group_with_members.id}/members", user)
          expect(response.status).to eq(200)
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(5)
          expect(json_response.find { |e| e['id']==owner.id }['access_level']).to eq(GroupMember::OWNER)
          expect(json_response.find { |e| e['id']==reporter.id }['access_level']).to eq(GroupMember::REPORTER)
          expect(json_response.find { |e| e['id']==developer.id }['access_level']).to eq(GroupMember::DEVELOPER)
          expect(json_response.find { |e| e['id']==master.id }['access_level']).to eq(GroupMember::MASTER)
          expect(json_response.find { |e| e['id']==guest.id }['access_level']).to eq(GroupMember::GUEST)
        end
      end

      it "users not part of the group should get access error" do
        get api("/groups/#{group_with_members.id}/members", stranger)
        expect(response.status).to eq(403)
      end
    end
  end

  describe "POST /groups/:id/members" do
    context "when not a member of the group" do
      it "should not add guest as member of group_no_members when adding being done by person outside the group" do
        post api("/groups/#{group_no_members.id}/members", reporter), user_id: guest.id, access_level: GroupMember::MASTER
        expect(response.status).to eq(403)
      end
    end

    context "when a member of the group" do
      it "should return ok and add new member" do
        new_user = create(:user)

        expect do
          post api("/groups/#{group_no_members.id}/members", owner), user_id: new_user.id, access_level: GroupMember::MASTER
        end.to change { group_no_members.members.count }.by(1)

        expect(response.status).to eq(201)
        expect(json_response['name']).to eq(new_user.name)
        expect(json_response['access_level']).to eq(GroupMember::MASTER)
      end

      it "should not allow guest to modify group members" do
        new_user = create(:user)

        expect do
          post api("/groups/#{group_with_members.id}/members", guest), user_id: new_user.id, access_level: GroupMember::MASTER
        end.not_to change { group_with_members.members.count }

        expect(response.status).to eq(403)
      end

      it "should return error if member already exists" do
        post api("/groups/#{group_with_members.id}/members", owner), user_id: master.id, access_level: GroupMember::MASTER
        expect(response.status).to eq(409)
      end

      it "should return a 400 error when user id is not given" do
        post api("/groups/#{group_no_members.id}/members", owner), access_level: GroupMember::MASTER
        expect(response.status).to eq(400)
      end

      it "should return a 400 error when access level is not given" do
        post api("/groups/#{group_no_members.id}/members", owner), user_id: master.id
        expect(response.status).to eq(400)
      end

      it "should return a 422 error when access level is not known" do
        post api("/groups/#{group_no_members.id}/members", owner), user_id: master.id, access_level: 1234
        expect(response.status).to eq(422)
      end
    end
  end

  describe 'PUT /groups/:id/members/:user_id' do
    context 'when not a member of the group' do
      it 'should return a 409 error if the user is not a group member' do
        put(
          api("/groups/#{group_no_members.id}/members/#{developer.id}",
              owner), access_level: GroupMember::MASTER
        )
        expect(response.status).to eq(404)
      end
    end

    context 'when a member of the group' do
      it 'should return ok and update member access level' do
        put(
          api("/groups/#{group_with_members.id}/members/#{reporter.id}",
              owner),
          access_level: GroupMember::MASTER
        )

        expect(response.status).to eq(200)

        get api("/groups/#{group_with_members.id}/members", owner)
        json_reporter = json_response.find do |e|
          e['id'] == reporter.id
        end

        expect(json_reporter['access_level']).to eq(GroupMember::MASTER)
      end

      it 'should not allow guest to modify group members' do
        put(
          api("/groups/#{group_with_members.id}/members/#{developer.id}",
              guest),
          access_level: GroupMember::MASTER
        )

        expect(response.status).to eq(403)

        get api("/groups/#{group_with_members.id}/members", owner)
        json_developer = json_response.find do |e|
          e['id'] == developer.id
        end

        expect(json_developer['access_level']).to eq(GroupMember::DEVELOPER)
      end

      it 'should return a 400 error when access level is not given' do
        put(
          api("/groups/#{group_with_members.id}/members/#{master.id}", owner)
        )
        expect(response.status).to eq(400)
      end

      it 'should return a 422 error when access level is not known' do
        put(
          api("/groups/#{group_with_members.id}/members/#{master.id}", owner),
          access_level: 1234
        )
        expect(response.status).to eq(422)
      end
    end
  end

  describe "DELETE /groups/:id/members/:user_id" do
    context "when not a member of the group" do
      it "should not delete guest's membership of group_with_members" do
        random_user = create(:user)
        delete api("/groups/#{group_with_members.id}/members/#{owner.id}", random_user)
        expect(response.status).to eq(403)
      end
    end

    context "when a member of the group" do
      it "should delete guest's membership of group" do
        expect do
          delete api("/groups/#{group_with_members.id}/members/#{guest.id}", owner)
        end.to change { group_with_members.members.count }.by(-1)

        expect(response.status).to eq(200)
      end

      it "should return a 404 error when user id is not known" do
        delete api("/groups/#{group_with_members.id}/members/1328", owner)
        expect(response.status).to eq(404)
      end

      it "should not allow guest to modify group members" do
        delete api("/groups/#{group_with_members.id}/members/#{master.id}", guest)
        expect(response.status).to eq(403)
      end
    end
  end
end
