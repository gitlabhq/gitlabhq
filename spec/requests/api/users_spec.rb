require 'spec_helper'

describe Gitlab::API do
  include ApiHelpers

  let(:user)  { Factory :user }
  let(:admin) {Factory :admin}
  let(:key)   { Factory :key, user: user }

  describe "GET /users" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/users")
        response.status.should == 401
      end
    end

    context "when authenticated" do
      it "should return an array of users" do
        get api("/users", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.first['email'].should == user.email
      end
    end
  end

  describe "GET /users/:id" do
    it "should return a user by id" do
      get api("/users/#{user.id}", user)
      response.status.should == 200
      json_response['email'].should == user.email
    end
  end

  describe "POST /users" do
    before{ admin }

    it "should not create invalid user" do
      post api("/users", admin), { email: "invalid email" }
      response.status.should == 404
    end

    it "should create user" do
      expect{
        post api("/users", admin), Factory.attributes(:user)
      }.to change{User.count}.by(1)
    end

    it "shouldn't available for non admin users" do
      post api("/users", user), Factory.attributes(:user)
      response.status.should == 403
    end
  end

  describe "GET /user" do
    it "should return current user" do
      get api("/user", user)
      response.status.should == 200
      json_response['email'].should == user.email
    end
  end

  describe "GET /user/keys" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/user/keys")
        response.status.should == 401
      end
    end

    context "when authenticated" do
      it "should return array of ssh keys" do
        user.keys << key
        user.save
        get api("/user/keys", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.first["title"].should == key.title
      end
    end
  end

  describe "GET /user/keys/:id" do
    it "should returm single key" do
      user.keys << key
      user.save
      get api("/user/keys/#{key.id}", user)
      response.status.should == 200
      json_response["title"].should == key.title
    end

    it "should return 404 Not Found within invalid ID" do
      get api("/user/keys/42", user)
      response.status.should == 404
    end
  end

  describe "POST /user/keys" do
    it "should not create invalid ssh key" do
      post api("/user/keys", user), { title: "invalid key" }
      response.status.should == 404
    end

    it "should create ssh key" do
      key_attrs = Factory.attributes :key
      expect {
        post api("/user/keys", user), key_attrs
      }.to change{ user.keys.count }.by(1)
    end
  end

  describe "DELETE /user/keys/:id" do
    it "should delete existed key" do
      user.keys << key
      user.save
      expect {
        delete api("/user/keys/#{key.id}", user)
      }.to change{user.keys.count}.by(-1)
    end

    it "should return 404 Not Found within invalid ID" do
      delete api("/user/keys/42", user)
      response.status.should == 404
    end
  end
end
