require 'spec_helper'

describe Gitlab::Auth, lib: true do
  let(:gl_auth) { described_class }

  describe 'find_for_git_client' do
    it 'recognizes CI' do
      token = '123'
      project = create(:empty_project)
      project.update_attributes(runners_token: token)

      ip = 'ip'

      expect(gl_auth).to receive(:rate_limit!).with(ip, success: true, login: 'gitlab-ci-token')
      expect(gl_auth.find_for_git_client('gitlab-ci-token', token, project: project, ip: ip)).to eq(Gitlab::Auth::Result.new(nil, :ci))
    end

    it 'recognizes master passwords' do
      user = create(:user, password: 'password')
      ip = 'ip'

      expect(gl_auth).to receive(:rate_limit!).with(ip, success: true, login: user.username)
      expect(gl_auth.find_for_git_client(user.username, 'password', project: nil, ip: ip)).to eq(Gitlab::Auth::Result.new(user, :gitlab_or_ldap))
    end

    it 'recognizes user lfs tokens' do
      user = create(:user)
      ip = 'ip'

      expect(gl_auth).to receive(:rate_limit!).with(ip, success: true, login: user.username)
      expect(gl_auth.find_for_git_client(user.username, user.lfs_token, project: nil, ip: ip)).to eq(Gitlab::Auth::Result.new(user, :lfs_token))
    end

    it 'recognizes deploy key lfs tokens' do
      key = create(:deploy_key)
      ip = 'ip'

      expect(gl_auth).to receive(:rate_limit!).with(ip, success: true, login: 'lfs-deploy-key')
      expect(gl_auth.find_for_git_client('lfs-deploy-key', key.lfs_token, project: nil, ip: ip)).to eq(Gitlab::Auth::Result.new(key, :lfs_deploy_token))
    end

    it 'recognizes OAuth tokens' do
      user = create(:user)
      application = Doorkeeper::Application.create!(name: "MyApp", redirect_uri: "https://app.com", owner: user)
      token = Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: user.id)
      ip = 'ip'

      expect(gl_auth).to receive(:rate_limit!).with(ip, success: true, login: 'oauth2')
      expect(gl_auth.find_for_git_client("oauth2", token.token, project: nil, ip: ip)).to eq(Gitlab::Auth::Result.new(user, :oauth))
    end

    it 'returns double nil for invalid credentials' do
      login = 'foo'
      ip = 'ip'

      expect(gl_auth).to receive(:rate_limit!).with(ip, success: false, login: login)
      expect(gl_auth.find_for_git_client(login, 'bar', project: nil, ip: ip)).to eq(Gitlab::Auth::Result.new)
    end
  end

  describe 'find_with_user_password' do
    let!(:user) do
      create(:user,
        username: username,
        password: password,
        password_confirmation: password)
    end
    let(:username) { 'John' }     # username isn't lowercase, test this
    let(:password) { 'my-secret' }

    it "finds user by valid login/password" do
      expect( gl_auth.find_with_user_password(username, password) ).to eql user
    end

    it 'finds user by valid email/password with case-insensitive email' do
      expect(gl_auth.find_with_user_password(user.email.upcase, password)).to eql user
    end

    it 'finds user by valid username/password with case-insensitive username' do
      expect(gl_auth.find_with_user_password(username.upcase, password)).to eql user
    end

    it "does not find user with invalid password" do
      password = 'wrong'
      expect( gl_auth.find_with_user_password(username, password) ).not_to eql user
    end

    it "does not find user with invalid login" do
      user = 'wrong'
      expect( gl_auth.find_with_user_password(username, password) ).not_to eql user
    end

    context "with ldap enabled" do
      before do
        allow(Gitlab::LDAP::Config).to receive(:enabled?).and_return(true)
      end

      it "tries to autheticate with db before ldap" do
        expect(Gitlab::LDAP::Authentication).not_to receive(:login)

        gl_auth.find_with_user_password(username, password)
      end

      it "uses ldap as fallback to for authentication" do
        expect(Gitlab::LDAP::Authentication).to receive(:login)

        gl_auth.find_with_user_password('ldap_user', 'password')
      end
    end
  end
end
