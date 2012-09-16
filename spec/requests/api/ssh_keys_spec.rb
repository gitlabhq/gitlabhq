require 'spec_helper'

describe Gitlab::Keys do
  include ApiHelpers
  let(:user) { 
    user = Factory.create :user
    user.reset_authentication_token!
    user
  }
  let(:key) { Factory.create :key, { user: user}}

  describe "GET /keys" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/keys")
        response.status.should == 401
      end
    end
    context "when authenticated" do
      it "should return array of ssh keys" do
        user.keys << key
        user.save
        get api("/keys", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.first["title"].should == key.title
      end
    end
  end

  describe "GET /keys/:id" do
    it "should returm single key" do
      user.keys << key
      user.save
      get api("/keys/#{key.id}", user)
      response.status.should == 200
      json_response["title"].should == key.title
    end
    it "should return 404 Not Found within invalid ID" do
      get api("/keys/42", user)
      response.status.should == 404
    end
  end

  describe "POST /keys" do
    it "should not create invalid ssh key" do
      post api("/keys", user), { title: "invalid key" }
      response.status.should == 404
    end
    it "should create ssh key" do
      key_attrs = Factory.attributes :key
      expect {
        post api("/keys", user), key_attrs 
      }.to change{ user.keys.count }.by(1)
    end
  end

  describe "DELETE /keys/:id" do
    it "should delete existed key" do
      user.keys << key
      user.save
      expect {
        delete api("/keys/#{key.id}", user)
      }.to change{user.keys.count}.by(-1)
    end
    it "should return 404 Not Found within invalid ID" do
      delete api("/keys/42", user)
      response.status.should == 404
    end
  end

end

