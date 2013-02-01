require 'spec_helper'

describe Gitlab::API do
  include ApiHelpers

  let(:user1)  { create(:user) }
  let(:user2)  { create(:user) }
  let(:admin) { create(:admin) }
  let!(:group1)  { create(:group, owner: user1) }
  let!(:group2)  { create(:group, owner: user2) }

  describe "GET /groups" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/groups")
        response.status.should == 401
      end
    end

    context "when authenticated as user" do
      it "normal user: should return an array of groups of user1" do
        get api("/groups", user1)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 1
        json_response.first['name'].should == group1.name
      end
    end
    
    context "when authenticated as  admin" do
      it "admin: should return an array of all groups" do
        get api("/groups", admin)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 2
      end
    end
  end
  
  describe "GET /groups/:id" do
    context "when authenticated as user" do
      it "should return one of user1's groups" do
        get api("/groups/#{group1.id}", user1)
        response.status.should == 200
        json_response['name'] == group1.name
      end
      
      it "should not return a non existing group" do
        get api("/groups/1328", user1)
        response.status.should == 404
      end
      
      it "should not return a group not attached to user1" do
        get api("/groups/#{group2.id}", user1)
        response.status.should == 404
      end
    end
    
    context "when authenticated as admin" do
      it "should return any existing group" do
        get api("/groups/#{group2.id}", admin)
        response.status.should == 200
        json_response['name'] == group2.name
      end
      
      it "should not return a non existing group" do
        get api("/groups/1328", admin)
        response.status.should == 404
      end
    end
  end
  
  describe "POST /groups" do
    context "when authenticated as user" do
      it "should not create group" do
        post api("/groups", user1), attributes_for(:group)
        response.status.should == 403
      end
    end
    
    context "when authenticated as admin" do
      it "should create group" do
        post api("/groups", admin), attributes_for(:group)
        response.status.should == 201
      end

      it "should not create group, duplicate" do
        post api("/groups", admin), {:name => "Duplicate Test", :path => group2.path}
        response.status.should == 404
      end
    end
  end
end
