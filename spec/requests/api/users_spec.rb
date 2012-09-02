require 'spec_helper'

describe Gitlab::API do
  include ApiHelpers

  let(:user) { Factory :user }

  describe "GET /users" do
    it "should return authentication error" do
      get api("/users")
      response.status.should == 401
    end

    describe "authenticated GET /users" do
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

  describe "GET /user" do
    it "should return current user" do
      get api("/user", user)
      response.status.should == 200
      json_response['email'].should == user.email
    end
  end
end
