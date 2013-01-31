require 'spec_helper'

describe Gitlab::API do
  include ApiHelpers

  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }
  let(:key)   { create(:key, user: user) }

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
      expect {
        post api("/users", admin), attributes_for(:user, projects_limit: 3)
      }.to change { User.count }.by(1)
    end

    it "shouldn't available for non admin users" do
      post api("/users", user), attributes_for(:user)
      response.status.should == 403
    end
  end

  describe "GET /users/sign_up" do
    before do
      Gitlab.config.gitlab.stub(:signup_enabled).and_return(false)
    end
    it "should redirect to sign in page if signup is disabled" do
      get "/users/sign_up"
      response.status.should == 302
      response.should redirect_to(new_user_session_path)
    end
  end

  describe "GET /users/sign_up" do
    before do
      Gitlab.config.gitlab.stub(:signup_enabled).and_return(true)
    end
    it "should return sign up page if signup is enabled" do
      get "/users/sign_up"
      response.status.should == 200
    end
    it "should create a new user account" do
      visit new_user_registration_path
      fill_in "user_name", with: "Name Surname"
      fill_in "user_username", with: "Great"
      fill_in "user_email", with: "name@mail.com"
      fill_in "user_password", with: "password1234"
      fill_in "user_password_confirmation", with: "password1234"
      expect { click_button "Sign up" }.to change {User.count}.by(1)
    end
  end

  describe "PUT /users/:id" do
    before { admin }

    it "should update user" do
      put api("/users/#{user.id}", admin), {bio: 'new test bio'}
      response.status.should == 200
      json_response['bio'].should == 'new test bio'
      user.reload.bio.should == 'new test bio'
    end

    it "should not allow invalid update" do
      put api("/users/#{user.id}", admin), {email: 'invalid email'}
      response.status.should == 404
      user.reload.email.should_not == 'invalid email'
    end

    it "shouldn't available for non admin users" do
      put api("/users/#{user.id}", user), attributes_for(:user)
      response.status.should == 403
    end

    it "should return 404 for non-existing user" do
      put api("/users/999999", admin), {bio: 'update should fail'}
      response.status.should == 404
    end
  end

  describe "DELETE /users/:id" do
    before { admin }

    it "should delete user" do
      delete api("/users/#{user.id}", admin)
      response.status.should == 200
      expect { User.find(user.id) }.to raise_error ActiveRecord::RecordNotFound
      json_response['email'].should == user.email
    end

    it "shouldn't available for non admin users" do
      delete api("/users/#{user.id}", user)
      response.status.should == 403
    end

    it "should return 404 for non-existing user" do
      delete api("/users/999999", admin)
      response.status.should == 404
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
      key_attrs = attributes_for :key
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
