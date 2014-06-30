require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }
  let(:key)   { create(:key, user: user) }

  describe "GET /users" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/users")
        expect(response.status).to eq(401)
      end
    end

    context "when authenticated" do
      it "should return an array of users" do
        get api("/users", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.first['username']).to eq(user.username)
      end
    end

    context "when admin" do
      it "should return an array of users" do
        get api("/users", admin)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.first.keys).to include 'email'
        expect(json_response.first.keys).to include 'extern_uid'
        expect(json_response.first.keys).to include 'can_create_project'
      end
    end
  end

  describe "GET /users/:id" do
    it "should return a user by id" do
      get api("/users/#{user.id}", user)
      expect(response.status).to eq(200)
      expect(json_response['username']).to eq(user.username)
    end

    it "should return a 401 if unauthenticated" do
      get api("/users/9998")
      expect(response.status).to eq(401)
    end

    it "should return a 404 error if user id not found" do
      get api("/users/9999", user)
      expect(response.status).to eq(404)
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
      expect(response.status).to eq(201)
      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user).not_to eq(nil)
      expect(new_user.admin).to eq(true)
      expect(new_user.can_create_group).to eq(true)
    end

    it "should create non-admin user" do
      post api('/users', admin), attributes_for(:user, admin: false, can_create_group: false)
      expect(response.status).to eq(201)
      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user).not_to eq(nil)
      expect(new_user.admin).to eq(false)
      expect(new_user.can_create_group).to eq(false)
    end

    it "should create non-admin users by default" do
      post api('/users', admin), attributes_for(:user)
      expect(response.status).to eq(201)
      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user).not_to eq(nil)
      expect(new_user.admin).to eq(false)
    end

    it "should return 201 Created on success" do
      post api("/users", admin), attributes_for(:user, projects_limit: 3)
      expect(response.status).to eq(201)
    end

    it "creating a user should respect default project limit" do
      limit = 123456
      allow(Gitlab.config.gitlab).to receive(:default_projects_limit).and_return(limit)
      attr = attributes_for(:user )
      expect {
        post api("/users", admin), attr
      }.to change { User.count }.by(1)
      user = User.find_by(username: attr[:username])
      expect(user.projects_limit).to eq(limit)
      expect(user.theme_id).to eq(Gitlab::Theme::MARS)
      allow(Gitlab.config.gitlab).to receive(:default_projects_limit).and_call_original
    end

    it "should not create user with invalid email" do
      post api("/users", admin), { email: "invalid email", password: 'password' }
      expect(response.status).to eq(400)
    end

    it "should return 400 error if password not given" do
      post api("/users", admin), { email: 'test@example.com' }
      expect(response.status).to eq(400)
    end

    it "should return 400 error if email not given" do
      post api("/users", admin), { password: 'pass1234' }
      expect(response.status).to eq(400)
    end

    it "shouldn't available for non admin users" do
      post api("/users", user), attributes_for(:user)
      expect(response.status).to eq(403)
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
        allow(Gitlab.config.gitlab).to receive(:signup_enabled).and_return(true)
      end

      it "should return sign up page if signup is enabled" do
        get "/users/sign_up"
        expect(response.status).to eq(200)
      end
    end

    context 'disabled' do
      before do
        allow(Gitlab.config.gitlab).to receive(:signup_enabled).and_return(false)
      end

      it "should redirect to sign in page if signup is disabled" do
        get "/users/sign_up"
        expect(response.status).to eq(302)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PUT /users/:id" do
    let!(:admin_user) { create(:admin) }

    before { admin }

    it "should update user with new bio" do
      put api("/users/#{user.id}", admin), {bio: 'new test bio'}
      expect(response.status).to eq(200)
      expect(json_response['bio']).to eq('new test bio')
      expect(user.reload.bio).to eq('new test bio')
    end

    it "should update admin status" do
      put api("/users/#{user.id}", admin), {admin: true}
      expect(response.status).to eq(200)
      expect(json_response['is_admin']).to eq(true)
      expect(user.reload.admin).to eq(true)
    end

    it "should not update admin status" do
      put api("/users/#{admin_user.id}", admin), {can_create_group: false}
      expect(response.status).to eq(200)
      expect(json_response['is_admin']).to eq(true)
      expect(admin_user.reload.admin).to eq(true)
      expect(admin_user.can_create_group).to eq(false)
    end

    it "should not allow invalid update" do
      put api("/users/#{user.id}", admin), {email: 'invalid email'}
      expect(response.status).to eq(404)
      expect(user.reload.email).not_to eq('invalid email')
    end

    it "shouldn't available for non admin users" do
      put api("/users/#{user.id}", user), attributes_for(:user)
      expect(response.status).to eq(403)
    end

    it "should return 404 for non-existing user" do
      put api("/users/999999", admin), {bio: 'update should fail'}
      expect(response.status).to eq(404)
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
      expect(response.status).to eq(404)
    end

    it "should create ssh key" do
      key_attrs = attributes_for :key
      expect {
        post api("/users/#{user.id}/keys", admin), key_attrs
      }.to change{ user.keys.count }.by(1)
    end
  end

  describe 'GET /user/:uid/keys' do
    before { admin }

    context 'when unauthenticated' do
      it 'should return authentication error' do
        get api("/users/#{user.id}/keys")
        expect(response.status).to eq(401)
      end
    end

    context 'when authenticated' do
      it 'should return 404 for non-existing user' do
        get api('/users/999999/keys', admin)
        expect(response.status).to eq(404)
      end

      it 'should return array of ssh keys' do
        user.keys << key
        user.save
        get api("/users/#{user.id}/keys", admin)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.first['title']).to eq(key.title)
      end
    end
  end

  describe 'DELETE /user/:uid/keys/:id' do
    before { admin }

    context 'when unauthenticated' do
      it 'should return authentication error' do
        delete api("/users/#{user.id}/keys/42")
        expect(response.status).to eq(401)
      end
    end

    context 'when authenticated' do
      it 'should delete existing key' do
        user.keys << key
        user.save
        expect {
          delete api("/users/#{user.id}/keys/#{key.id}", admin)
        }.to change { user.keys.count }.by(-1)
        expect(response.status).to eq(200)
      end

      it 'should return 404 error if user not found' do
        user.keys << key
        user.save
        delete api("/users/999999/keys/#{key.id}", admin)
        expect(response.status).to eq(404)
      end

      it 'should return 404 error if key not foud' do
        delete api("/users/#{user.id}/keys/42", admin)
        expect(response.status).to eq(404)
      end
    end
  end

  describe "DELETE /users/:id" do
    before { admin }

    it "should delete user" do
      delete api("/users/#{user.id}", admin)
      expect(response.status).to eq(200)
      expect { User.find(user.id) }.to raise_error ActiveRecord::RecordNotFound
      expect(json_response['email']).to eq(user.email)
    end

    it "should not delete for unauthenticated user" do
      delete api("/users/#{user.id}")
      expect(response.status).to eq(401)
    end

    it "shouldn't available for non admin users" do
      delete api("/users/#{user.id}", user)
      expect(response.status).to eq(403)
    end

    it "should return 404 for non-existing user" do
      delete api("/users/999999", admin)
      expect(response.status).to eq(404)
    end
  end

  describe "GET /user" do
    it "should return current user" do
      get api("/user", user)
      expect(response.status).to eq(200)
      expect(json_response['email']).to eq(user.email)
      expect(json_response['is_admin']).to eq(user.is_admin?)
      expect(json_response['can_create_project']).to eq(user.can_create_project?)
      expect(json_response['can_create_group']).to eq(user.can_create_group?)
    end

    it "should return 401 error if user is unauthenticated" do
      get api("/user")
      expect(response.status).to eq(401)
    end
  end

  describe "GET /user/keys" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/user/keys")
        expect(response.status).to eq(401)
      end
    end

    context "when authenticated" do
      it "should return array of ssh keys" do
        user.keys << key
        user.save
        get api("/user/keys", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.first["title"]).to eq(key.title)
      end
    end
  end

  describe "GET /user/keys/:id" do
    it "should return single key" do
      user.keys << key
      user.save
      get api("/user/keys/#{key.id}", user)
      expect(response.status).to eq(200)
      expect(json_response["title"]).to eq(key.title)
    end

    it "should return 404 Not Found within invalid ID" do
      get api("/user/keys/42", user)
      expect(response.status).to eq(404)
    end

    it "should return 404 error if admin accesses user's ssh key" do
      user.keys << key
      user.save
      admin
      get api("/user/keys/#{key.id}", admin)
      expect(response.status).to eq(404)
    end
  end

  describe "POST /user/keys" do
    it "should create ssh key" do
      key_attrs = attributes_for :key
      expect {
        post api("/user/keys", user), key_attrs
      }.to change{ user.keys.count }.by(1)
      expect(response.status).to eq(201)
    end

    it "should return a 401 error if unauthorized" do
      post api("/user/keys"), title: 'some title', key: 'some key'
      expect(response.status).to eq(401)
    end

    it "should not create ssh key without key" do
      post api("/user/keys", user), title: 'title'
      expect(response.status).to eq(400)
    end

    it "should not create ssh key without title" do
      post api("/user/keys", user), key: "somekey"
      expect(response.status).to eq(400)
    end
  end

  describe "DELETE /user/keys/:id" do
    it "should delete existed key" do
      user.keys << key
      user.save
      expect {
        delete api("/user/keys/#{key.id}", user)
      }.to change{user.keys.count}.by(-1)
      expect(response.status).to eq(200)
    end

    it "should return success if key ID not found" do
      delete api("/user/keys/42", user)
      expect(response.status).to eq(200)
    end

    it "should return 401 error if unauthorized" do
      user.keys << key
      user.save
      delete api("/user/keys/#{key.id}")
      expect(response.status).to eq(401)
    end
  end
end
