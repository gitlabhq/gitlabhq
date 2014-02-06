require 'spec_helper'

describe API::API do
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

    it "should return a 401 if unauthenticated" do
      get api("/users/9998")
      response.status.should == 401
    end

    it "should return a 404 error if user id not found" do
      get api("/users/9999", user)
      response.status.should == 404
    end
  end

  describe "POST /users" do
    before{ admin }

    it "should create user" do
      expect {
        post api("/users", admin), attributes_for(:user, projects_limit: 3)
      }.to change { User.count }.by(1)
    end

    it "should create user with correct attributes" do
      post api('/users', admin), attributes_for(:user, admin: true, can_create_group: true)
      response.status.should == 201
      user_id = json_response['id']
      new_user = User.find(user_id)
      new_user.should_not == nil
      new_user.admin.should == true
      new_user.can_create_group.should == true
    end

    it "should create non-admin user" do
      post api('/users', admin), attributes_for(:user, admin: false, can_create_group: false)
      response.status.should == 201
      user_id = json_response['id']
      new_user = User.find(user_id)
      new_user.should_not == nil
      new_user.admin.should == false
      new_user.can_create_group.should == false
    end

    it "should create non-admin users by default" do
      post api('/users', admin), attributes_for(:user)
      response.status.should == 201
      user_id = json_response['id']
      new_user = User.find(user_id)
      new_user.should_not == nil
      new_user.admin.should == false
    end

    it "should return 201 Created on success" do
      post api("/users", admin), attributes_for(:user, projects_limit: 3)
      response.status.should == 201
    end

    it "creating a user should respect default project limit" do
      limit = 123456
      Gitlab.config.gitlab.stub(:default_projects_limit).and_return(limit)
      attr = attributes_for(:user )
      expect {
        post api("/users", admin), attr
      }.to change { User.count }.by(1)
      user = User.find_by(username: attr[:username])
      user.projects_limit.should == limit
      user.theme_id.should == Gitlab::Theme::MARS
      Gitlab.config.gitlab.unstub(:default_projects_limit)
    end

    it "should not create user with invalid email" do
      post api("/users", admin), { email: "invalid email", password: 'password' }
      response.status.should == 400
    end

    it "should return 400 error if password not given" do
      post api("/users", admin), { email: 'test@example.com' }
      response.status.should == 400
    end

    it "should return 400 error if email not given" do
      post api("/users", admin), { password: 'pass1234' }
      response.status.should == 400
    end

    it "shouldn't available for non admin users" do
      post api("/users", user), attributes_for(:user)
      response.status.should == 403
    end

    context "with existing user" do
      before { post api("/users", admin), { email: 'test@example.com', password: 'password', username: 'test' } }

      it "should not create user with same email" do
        expect {
          post api("/users", admin), { email: 'test@example.com', password: 'password' }
        }.to change { User.count }.by(0)
      end

      it "should return 409 conflict error if user with email exists" do
        post api("/users", admin), { email: 'test@example.com', password: 'password' }
      end

      it "should return 409 conflict error if same username exists" do
        post api("/users", admin), { email: 'foo@example.com', password: 'pass', username: 'test' }
      end
    end
  end

  describe "GET /users/sign_up" do
    context 'enabled' do
      before do
        Gitlab.config.gitlab.stub(:signup_enabled).and_return(true)
      end

      it "should return sign up page if signup is enabled" do
        get "/users/sign_up"
        response.status.should == 200
      end
    end

    context 'disabled' do
      before do
        Gitlab.config.gitlab.stub(:signup_enabled).and_return(false)
      end

      it "should redirect to sign in page if signup is disabled" do
        get "/users/sign_up"
        response.status.should == 302
        response.should redirect_to(new_user_session_path)
      end
    end
  end

  describe "PUT /users/:id" do
    let!(:admin_user) { create(:admin) }

    before { admin }

    it "should update user with new bio" do
      put api("/users/#{user.id}", admin), {bio: 'new test bio'}
      response.status.should == 200
      json_response['bio'].should == 'new test bio'
      user.reload.bio.should == 'new test bio'
    end

    it "should update admin status" do
      put api("/users/#{user.id}", admin), {admin: true}
      response.status.should == 200
      json_response['is_admin'].should == true
      user.reload.admin.should == true
    end

    it "should not update admin status" do
      put api("/users/#{admin_user.id}", admin), {can_create_group: false}
      response.status.should == 200
      json_response['is_admin'].should == true
      admin_user.reload.admin.should == true
      admin_user.can_create_group.should == false
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

    context "with existing user" do
      before {
        post api("/users", admin), { email: 'test@example.com', password: 'password', username: 'test', name: 'test' }
        post api("/users", admin), { email: 'foo@bar.com', password: 'password', username: 'john', name: 'john' }
        @user_id = User.all.last.id
      }

#      it "should return 409 conflict error if email address exists" do
#        put api("/users/#{@user_id}", admin), { email: 'test@example.com' }
#        response.status.should == 409
#      end
#
#      it "should return 409 conflict error if username taken" do
#        @user_id = User.all.last.id
#        put api("/users/#{@user_id}", admin), { username: 'test' }
#        response.status.should == 409
#      end
    end
  end

  describe "POST /users/:id/keys" do
    before { admin }

    it "should not create invalid ssh key" do
      post api("/users/#{user.id}/keys", admin), { title: "invalid key" }
      response.status.should == 404
    end

    it "should create ssh key" do
      key_attrs = attributes_for :key
      expect {
        post api("/users/#{user.id}/keys", admin), key_attrs
      }.to change{ user.keys.count }.by(1)
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

    it "should not delete for unauthenticated user" do
      delete api("/users/#{user.id}")
      response.status.should == 401
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
      json_response['is_admin'].should == user.is_admin?
      json_response['can_create_project'].should == user.can_create_project?
      json_response['can_create_group'].should == user.can_create_group?
    end

    it "should return 401 error if user is unauthenticated" do
      get api("/user")
      response.status.should == 401
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
    it "should return single key" do
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

    it "should return 404 error if admin accesses user's ssh key" do
      user.keys << key
      user.save
      admin
      get api("/user/keys/#{key.id}", admin)
      response.status.should == 404
    end
  end

  describe "POST /user/keys" do
    it "should create ssh key" do
      key_attrs = attributes_for :key
      expect {
        post api("/user/keys", user), key_attrs
      }.to change{ user.keys.count }.by(1)
      response.status.should == 201
    end

    it "should return a 401 error if unauthorized" do
      post api("/user/keys"), title: 'some title', key: 'some key'
      response.status.should == 401
    end

    it "should not create ssh key without key" do
      post api("/user/keys", user), title: 'title'
      response.status.should == 400
    end

    it "should not create ssh key without title" do
      post api("/user/keys", user), key: "somekey"
      response.status.should == 400
    end
  end

  describe "DELETE /user/keys/:id" do
    it "should delete existed key" do
      user.keys << key
      user.save
      expect {
        delete api("/user/keys/#{key.id}", user)
      }.to change{user.keys.count}.by(-1)
      response.status.should == 200
    end

    it "should return success if key ID not found" do
      delete api("/user/keys/42", user)
      response.status.should == 200
    end

    it "should return 401 error if unauthorized" do
      user.keys << key
      user.save
      delete api("/user/keys/#{key.id}")
      response.status.should == 401
    end
  end
end
