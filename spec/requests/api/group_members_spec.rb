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
          response.status.should == 200
          json_response.should be_an Array
          json_response.size.should == 5
          json_response.find { |e| e['id']==owner.id }['access_level'].should == GroupMember::OWNER
          json_response.find { |e| e['id']==reporter.id }['access_level'].should == GroupMember::REPORTER
          json_response.find { |e| e['id']==developer.id }['access_level'].should == GroupMember::DEVELOPER
          json_response.find { |e| e['id']==master.id }['access_level'].should == GroupMember::MASTER
          json_response.find { |e| e['id']==guest.id }['access_level'].should == GroupMember::GUEST
        end
      end

      it "users not part of the group should get access error" do
        get api("/groups/#{group_with_members.id}/members", stranger)
        response.status.should == 403
      end
    end
  end

  describe "POST /groups/:id/members" do
    context "when not a member of the group" do
      it "should not add guest as member of group_no_members when adding being done by person outside the group" do
        post api("/groups/#{group_no_members.id}/members", reporter), user_id: guest.id, access_level: GroupMember::MASTER
        response.status.should == 403
      end
    end

    context "when a member of the group" do
      it "should return ok and add new member" do
        new_user = create(:user)

        expect {
          post api("/groups/#{group_no_members.id}/members", owner),
          user_id: new_user.id, access_level: GroupMember::MASTER
        }.to change { group_no_members.members.count }.by(1)

        response.status.should == 201
        json_response['name'].should == new_user.name
        json_response['access_level'].should == GroupMember::MASTER
      end

      it "should not allow guest to modify group members" do
        new_user = create(:user)

        expect {
          post api("/groups/#{group_with_members.id}/members", guest),
          user_id: new_user.id, access_level: GroupMember::MASTER
        }.not_to change { group_with_members.members.count }

        response.status.should == 403
      end

      it "should return error if member already exists" do
        post api("/groups/#{group_with_members.id}/members", owner), user_id: master.id, access_level: GroupMember::MASTER
        response.status.should == 409
      end

      it "should return a 400 error when user id is not given" do
        post api("/groups/#{group_no_members.id}/members", owner), access_level: GroupMember::MASTER
        response.status.should == 400
      end

      it "should return a 400 error when access level is not given" do
        post api("/groups/#{group_no_members.id}/members", owner), user_id: master.id
        response.status.should == 400
      end

      it "should return a 422 error when access level is not known" do
        post api("/groups/#{group_no_members.id}/members", owner), user_id: master.id, access_level: 1234
        response.status.should == 422
      end
    end
  end

  describe "DELETE /groups/:id/members/:user_id" do
    context "when not a member of the group" do
      it "should not delete guest's membership of group_with_members" do
        random_user = create(:user)
        delete api("/groups/#{group_with_members.id}/members/#{owner.id}", random_user)
        response.status.should == 403
      end
    end

    context "when a member of the group" do
      it "should delete guest's membership of group" do
        expect {
          delete api("/groups/#{group_with_members.id}/members/#{guest.id}", owner)
        }.to change { group_with_members.members.count }.by(-1)

        response.status.should == 200
      end

      it "should return a 404 error when user id is not known" do
        delete api("/groups/#{group_with_members.id}/members/1328", owner)
        response.status.should == 404
      end

      it "should not allow guest to modify group members" do
        delete api("/groups/#{group_with_members.id}/members/#{master.id}", guest)
        response.status.should == 403
      end
    end
  end
end
