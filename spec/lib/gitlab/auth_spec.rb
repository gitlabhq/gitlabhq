# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Auth, :use_clean_rails_memory_store_caching do
  let(:gl_auth) { described_class }

  set(:project) { create(:project) }

  describe 'constants' do
    it 'API_SCOPES contains all scopes for API access' do
      expect(subject::API_SCOPES).to eq %i[api read_user]
    end

    it 'ADMIN_SCOPES contains all scopes for ADMIN access' do
      expect(subject::ADMIN_SCOPES).to eq %i[sudo]
    end

    it 'REPOSITORY_SCOPES contains all scopes for REPOSITORY access' do
      expect(subject::REPOSITORY_SCOPES).to eq %i[read_repository write_repository]
    end

    it 'OPENID_SCOPES contains all scopes for OpenID Connect' do
      expect(subject::OPENID_SCOPES).to eq [:openid]
    end

    it 'DEFAULT_SCOPES contains all default scopes' do
      expect(subject::DEFAULT_SCOPES).to eq [:api]
    end

    it 'optional_scopes contains all non-default scopes' do
      stub_container_registry_config(enabled: true)

      expect(subject.optional_scopes).to eq %i[read_user read_repository write_repository read_registry sudo openid profile email]
    end
  end

  context 'available_scopes' do
    it 'contains all non-default scopes' do
      stub_container_registry_config(enabled: true)

      expect(subject.all_available_scopes).to eq %i[api read_user read_repository write_repository read_registry sudo]
    end

    it 'contains for non-admin user all non-default scopes without ADMIN access' do
      stub_container_registry_config(enabled: true)
      user = create(:user, admin: false)

      expect(subject.available_scopes_for(user)).to eq %i[api read_user read_repository write_repository read_registry]
    end

    it 'contains for admin user all non-default scopes with ADMIN access' do
      stub_container_registry_config(enabled: true)
      user = create(:user, admin: true)

      expect(subject.available_scopes_for(user)).to eq %i[api read_user read_repository write_repository read_registry sudo]
    end

    context 'registry_scopes' do
      context 'when registry is disabled' do
        before do
          stub_container_registry_config(enabled: false)
        end

        it 'is empty' do
          expect(subject.registry_scopes).to eq []
        end
      end

      context 'when registry is enabled' do
        before do
          stub_container_registry_config(enabled: true)
        end

        it 'contains all registry related scopes' do
          expect(subject.registry_scopes).to eq %i[read_registry]
        end
      end
    end
  end

  describe 'find_for_git_client' do
    describe 'rate limiting' do
      before do
        stub_rack_attack_setting(enabled: true, ip_whitelist: [])
      end

      context 'when IP is already banned' do
        subject { gl_auth.find_for_git_client('username', 'password', project: nil, ip: 'ip') }

        before do
          expect_next_instance_of(Gitlab::Auth::IpRateLimiter) do |rate_limiter|
            expect(rate_limiter).to receive(:banned?).and_return(true)
          end
        end

        it 'raises an IpBlacklisted exception' do
          expect { subject }.to raise_error(Gitlab::Auth::IpBlacklisted)
        end
      end

      context 'for CI registry user' do
        let_it_be(:build) { create(:ci_build, :running) }

        it 'skips rate limiting for successful auth' do
          expect_next_instance_of(Gitlab::Auth::IpRateLimiter) do |rate_limiter|
            expect(rate_limiter).not_to receive(:reset!)
          end

          gl_auth.find_for_git_client('gitlab-ci-token', build.token, project: build.project, ip: 'ip')
        end

        it 'skips rate limiting for failed auth' do
          expect_next_instance_of(Gitlab::Auth::IpRateLimiter) do |rate_limiter|
            expect(rate_limiter).not_to receive(:register_fail!)
          end

          gl_auth.find_for_git_client('gitlab-ci-token', 'wrong_token', project: build.project, ip: 'ip')
        end
      end

      context 'for other users' do
        let_it_be(:user) { create(:user) }

        it 'resets rate limit for successful auth' do
          expect_next_instance_of(Gitlab::Auth::IpRateLimiter) do |rate_limiter|
            expect(rate_limiter).to receive(:reset!)
          end

          gl_auth.find_for_git_client(user.username, user.password, project: nil, ip: 'ip')
        end

        it 'rate limits a user by unique IPs' do
          expect_next_instance_of(Gitlab::Auth::IpRateLimiter) do |rate_limiter|
            expect(rate_limiter).to receive(:reset!)
          end
          expect(Gitlab::Auth::UniqueIpsLimiter).to receive(:limit_user!).twice.and_call_original

          gl_auth.find_for_git_client(user.username, user.password, project: nil, ip: 'ip')
        end

        it 'registers failure for failed auth' do
          expect_next_instance_of(Gitlab::Auth::IpRateLimiter) do |rate_limiter|
            expect(rate_limiter).to receive(:register_fail!)
          end

          gl_auth.find_for_git_client(user.username, 'wrong_password', project: nil, ip: 'ip')
        end
      end
    end

    context 'build token' do
      subject { gl_auth.find_for_git_client('gitlab-ci-token', build.token, project: project, ip: 'ip') }

      context 'for running build' do
        let!(:build) { create(:ci_build, :running) }
        let(:project) { build.project }

        it 'recognises user-less build' do
          expect(subject).to eq(Gitlab::Auth::Result.new(nil, build.project, :ci, described_class.build_authentication_abilities))
        end

        it 'recognises user token' do
          build.update(user: create(:user))

          expect(subject).to eq(Gitlab::Auth::Result.new(build.user, build.project, :build, described_class.build_authentication_abilities))
        end
      end

      (HasStatus::AVAILABLE_STATUSES - ['running']).each do |build_status|
        context "for #{build_status} build" do
          let!(:build) { create(:ci_build, status: build_status) }
          let(:project) { build.project }

          it 'denies authentication' do
            expect(subject).to eq(Gitlab::Auth::Result.new)
          end
        end
      end
    end

    it 'recognizes other ci services' do
      project.create_drone_ci_service(active: true)
      project.drone_ci_service.update(token: 'token')

      expect(gl_auth.find_for_git_client('drone-ci-token', 'token', project: project, ip: 'ip')).to eq(Gitlab::Auth::Result.new(nil, project, :ci, described_class.build_authentication_abilities))
    end

    it 'recognizes master passwords' do
      user = create(:user, password: 'password')

      expect(gl_auth.find_for_git_client(user.username, 'password', project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new(user, nil, :gitlab_or_ldap, described_class.full_authentication_abilities))
    end

    include_examples 'user login operation with unique ip limit' do
      let(:user) { create(:user, password: 'password') }

      def operation
        expect(gl_auth.find_for_git_client(user.username, 'password', project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new(user, nil, :gitlab_or_ldap, described_class.full_authentication_abilities))
      end
    end

    context 'while using LFS authenticate' do
      it 'recognizes user lfs tokens' do
        user = create(:user)
        token = Gitlab::LfsToken.new(user).token

        expect(gl_auth.find_for_git_client(user.username, token, project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new(user, nil, :lfs_token, described_class.read_write_project_authentication_abilities))
      end

      it 'recognizes deploy key lfs tokens' do
        key = create(:deploy_key)
        token = Gitlab::LfsToken.new(key).token

        expect(gl_auth.find_for_git_client("lfs+deploy-key-#{key.id}", token, project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new(key, nil, :lfs_deploy_token, described_class.read_only_authentication_abilities))
      end

      it 'does not try password auth before oauth' do
        user = create(:user)
        token = Gitlab::LfsToken.new(user).token

        expect(gl_auth).not_to receive(:find_with_user_password)

        gl_auth.find_for_git_client(user.username, token, project: nil, ip: 'ip')
      end

      it 'grants deploy key write permissions' do
        key = create(:deploy_key)
        create(:deploy_keys_project, :write_access, deploy_key: key, project: project)
        token = Gitlab::LfsToken.new(key).token

        expect(gl_auth.find_for_git_client("lfs+deploy-key-#{key.id}", token, project: project, ip: 'ip')).to eq(Gitlab::Auth::Result.new(key, nil, :lfs_deploy_token, described_class.read_write_authentication_abilities))
      end

      it 'does not grant deploy key write permissions' do
        key = create(:deploy_key)
        token = Gitlab::LfsToken.new(key).token

        expect(gl_auth.find_for_git_client("lfs+deploy-key-#{key.id}", token, project: project, ip: 'ip')).to eq(Gitlab::Auth::Result.new(key, nil, :lfs_deploy_token, described_class.read_only_authentication_abilities))
      end
    end

    context 'while using OAuth tokens as passwords' do
      let(:user) { create(:user) }
      let(:token_w_api_scope) { Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: user.id, scopes: 'api') }
      let(:application) { Doorkeeper::Application.create!(name: 'MyApp', redirect_uri: 'https://app.com', owner: user) }

      it 'succeeds for OAuth tokens with the `api` scope' do
        expect(gl_auth.find_for_git_client("oauth2", token_w_api_scope.token, project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new(user, nil, :oauth, described_class.full_authentication_abilities))
      end

      it 'fails for OAuth tokens with other scopes' do
        token = Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: user.id, scopes: 'read_user')

        expect(gl_auth.find_for_git_client("oauth2", token.token, project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new(nil, nil))
      end

      it 'does not try password auth before oauth' do
        expect(gl_auth).not_to receive(:find_with_user_password)

        gl_auth.find_for_git_client("oauth2", token_w_api_scope.token, project: nil, ip: 'ip')
      end
    end

    context 'while using personal access tokens as passwords' do
      it 'succeeds for personal access tokens with the `api` scope' do
        personal_access_token = create(:personal_access_token, scopes: ['api'])

        expect_results_with_abilities(personal_access_token, described_class.full_authentication_abilities)
      end

      it 'succeeds for personal access tokens with the `read_repository` scope' do
        personal_access_token = create(:personal_access_token, scopes: ['read_repository'])

        expect_results_with_abilities(personal_access_token, [:download_code])
      end

      it 'succeeds for personal access tokens with the `write_repository` scope' do
        personal_access_token = create(:personal_access_token, scopes: ['write_repository'])

        expect_results_with_abilities(personal_access_token, [:download_code, :push_code])
      end

      context 'when registry is enabled' do
        before do
          stub_container_registry_config(enabled: true)
        end

        it 'succeeds for personal access tokens with the `read_registry` scope' do
          personal_access_token = create(:personal_access_token, scopes: ['read_registry'])

          expect_results_with_abilities(personal_access_token, [:read_container_image])
        end
      end

      it 'succeeds if it is an impersonation token' do
        impersonation_token = create(:personal_access_token, :impersonation, scopes: ['api'])

        expect_results_with_abilities(impersonation_token, described_class.full_authentication_abilities)
      end

      it 'limits abilities based on scope' do
        personal_access_token = create(:personal_access_token, scopes: %w[read_user sudo])

        expect_results_with_abilities(personal_access_token, [])
      end

      it 'fails if password is nil' do
        expect_results_with_abilities(nil, nil, false)
      end
    end

    context 'while using regular user and password' do
      it 'goes through lfs authentication' do
        user = create(
          :user,
          username: 'normal_user',
          password: 'my-secret'
        )

        expect(gl_auth.find_for_git_client(user.username, user.password, project: nil, ip: 'ip'))
          .to eq(Gitlab::Auth::Result.new(user, nil, :gitlab_or_ldap, described_class.full_authentication_abilities))
      end

      it 'goes through oauth authentication when the username is oauth2' do
        user = create(
          :user,
          username: 'oauth2',
          password: 'my-secret'
        )

        expect(gl_auth.find_for_git_client(user.username, user.password, project: nil, ip: 'ip'))
          .to eq(Gitlab::Auth::Result.new(user, nil, :gitlab_or_ldap, described_class.full_authentication_abilities))
      end
    end

    it 'returns double nil for invalid credentials' do
      login = 'foo'

      expect(gl_auth.find_for_git_client(login, 'bar', project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new)
    end

    it 'throws an error suggesting user create a PAT when internal auth is disabled' do
      allow_any_instance_of(ApplicationSetting).to receive(:password_authentication_enabled_for_git?) { false }

      expect { gl_auth.find_for_git_client('foo', 'bar', project: nil, ip: 'ip') }.to raise_error(Gitlab::Auth::MissingPersonalAccessTokenError)
    end

    context 'while using deploy tokens' do
      let(:auth_failure) { Gitlab::Auth::Result.new(nil, nil) }

      context 'when deploy token and user have the same username' do
        let(:username) { 'normal_user' }
        let(:user) { create(:user, username: username, password: 'my-secret') }
        let(:deploy_token) { create(:deploy_token, username: username, read_registry: false, projects: [project]) }

        it 'succeeds for the token' do
          auth_success = Gitlab::Auth::Result.new(deploy_token, project, :deploy_token, [:download_code])

          expect(gl_auth.find_for_git_client(username, deploy_token.token, project: project, ip: 'ip'))
            .to eq(auth_success)
        end

        it 'succeeds for the user' do
          auth_success = Gitlab::Auth::Result.new(user, nil, :gitlab_or_ldap, described_class.full_authentication_abilities)

          expect(gl_auth.find_for_git_client(username, 'my-secret', project: project, ip: 'ip'))
            .to eq(auth_success)
        end
      end

      context 'when deploy tokens have the same username' do
        context 'and belong to the same project' do
          let!(:read_registry) { create(:deploy_token, username: 'deployer', read_repository: false, projects: [project]) }
          let!(:read_repository) { create(:deploy_token, username: read_registry.username, read_registry: false, projects: [project]) }

          it 'succeeds for the right token' do
            auth_success = Gitlab::Auth::Result.new(read_repository, project, :deploy_token, [:download_code])

            expect(gl_auth.find_for_git_client('deployer', read_repository.token, project: project, ip: 'ip'))
              .to eq(auth_success)
          end

          it 'fails for the wrong token' do
            expect(gl_auth.find_for_git_client('deployer', read_registry.token, project: project, ip: 'ip'))
              .to eq(auth_failure)
          end
        end

        context 'and belong to different projects' do
          let!(:read_registry) { create(:deploy_token, username: 'deployer', read_repository: false, projects: [project]) }
          let!(:read_repository) { create(:deploy_token, username: read_registry.username, read_registry: false, projects: [project]) }

          it 'succeeds for the right token' do
            auth_success = Gitlab::Auth::Result.new(read_repository, project, :deploy_token, [:download_code])

            expect(gl_auth.find_for_git_client('deployer', read_repository.token, project: project, ip: 'ip'))
              .to eq(auth_success)
          end

          it 'fails for the wrong token' do
            expect(gl_auth.find_for_git_client('deployer', read_registry.token, project: project, ip: 'ip'))
              .to eq(auth_failure)
          end
        end
      end

      context 'when the deploy token has read_repository as scope' do
        let(:deploy_token) { create(:deploy_token, read_registry: false, projects: [project]) }
        let(:login) { deploy_token.username }

        it 'succeeds when login and token are valid' do
          auth_success = Gitlab::Auth::Result.new(deploy_token, project, :deploy_token, [:download_code])

          expect(gl_auth.find_for_git_client(login, deploy_token.token, project: project, ip: 'ip'))
            .to eq(auth_success)
        end

        it 'succeeds when custom login and token are valid' do
          deploy_token = create(:deploy_token, username: 'deployer', read_registry: false, projects: [project])
          auth_success = Gitlab::Auth::Result.new(deploy_token, project, :deploy_token, [:download_code])

          expect(gl_auth.find_for_git_client('deployer', deploy_token.token, project: project, ip: 'ip'))
            .to eq(auth_success)
        end

        it 'does not attempt to rate limit unique IPs for a deploy token' do
          expect(Gitlab::Auth::UniqueIpsLimiter).not_to receive(:limit_user!)

          gl_auth.find_for_git_client(login, deploy_token.token, project: project, ip: 'ip')
        end

        it 'fails when login is not valid' do
          expect(gl_auth.find_for_git_client('random_login', deploy_token.token, project: project, ip: 'ip'))
            .to eq(auth_failure)
        end

        it 'fails when token is not valid' do
          expect(gl_auth.find_for_git_client(login, '123123', project: project, ip: 'ip'))
            .to eq(auth_failure)
        end

        it 'fails if token is nil' do
          expect(gl_auth.find_for_git_client(login, nil, project: project, ip: 'ip'))
            .to eq(auth_failure)
        end

        it 'fails if token is not related to project' do
          another_deploy_token = create(:deploy_token)
          expect(gl_auth.find_for_git_client(login, another_deploy_token.token, project: project, ip: 'ip'))
            .to eq(auth_failure)
        end

        it 'fails if token has been revoked' do
          deploy_token.revoke!

          expect(deploy_token.revoked?).to be_truthy
          expect(gl_auth.find_for_git_client('deploy-token', deploy_token.token, project: project, ip: 'ip'))
            .to eq(auth_failure)
        end
      end

      context 'when the deploy token has read_registry as a scope' do
        let(:deploy_token) { create(:deploy_token, read_repository: false, projects: [project]) }
        let(:login) { deploy_token.username }

        context 'when registry enabled' do
          before do
            stub_container_registry_config(enabled: true)
          end

          it 'succeeds when login and token are valid' do
            auth_success = Gitlab::Auth::Result.new(deploy_token, project, :deploy_token, [:read_container_image])

            expect(gl_auth.find_for_git_client(login, deploy_token.token, project: nil, ip: 'ip'))
              .to eq(auth_success)
          end

          it 'fails when login is not valid' do
            expect(gl_auth.find_for_git_client('random_login', deploy_token.token, project: project, ip: 'ip'))
              .to eq(auth_failure)
          end

          it 'fails when token is not valid' do
            expect(gl_auth.find_for_git_client(login, '123123', project: project, ip: 'ip'))
              .to eq(auth_failure)
          end

          it 'fails if token is nil' do
            expect(gl_auth.find_for_git_client(login, nil, project: nil, ip: 'ip'))
              .to eq(auth_failure)
          end

          it 'fails if token is not related to project' do
            expect(gl_auth.find_for_git_client(login, 'abcdef', project: nil, ip: 'ip'))
              .to eq(auth_failure)
          end

          it 'fails if token has been revoked' do
            deploy_token.revoke!

            expect(deploy_token.revoked?).to be_truthy
            expect(gl_auth.find_for_git_client('deploy-token', deploy_token.token, project: nil, ip: 'ip'))
              .to eq(auth_failure)
          end
        end

        context 'when registry disabled' do
          before do
            stub_container_registry_config(enabled: false)
          end

          it 'fails when login and token are valid' do
            expect(gl_auth.find_for_git_client(login, deploy_token.token, project: nil, ip: 'ip'))
              .to eq(auth_failure)
          end
        end
      end
    end
  end

  describe 'find_with_user_password' do
    let!(:user) do
      create(:user,
        username: username,
        password: password,
        password_confirmation: password)
    end
    let(:username) { 'John' } # username isn't lowercase, test this
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

    include_examples 'user login operation with unique ip limit' do
      def operation
        expect(gl_auth.find_with_user_password(username, password)).to eq(user)
      end
    end

    it 'finds the user in deactivated state' do
      user.deactivate!

      expect( gl_auth.find_with_user_password(username, password) ).to eql user
    end

    it "does not find user in blocked state" do
      user.block

      expect( gl_auth.find_with_user_password(username, password) ).not_to eql user
    end

    it "does not find user in ldap_blocked state" do
      user.ldap_block

      expect( gl_auth.find_with_user_password(username, password) ).not_to eql user
    end

    context "with ldap enabled" do
      before do
        allow(Gitlab::Auth::LDAP::Config).to receive(:enabled?).and_return(true)
      end

      it "tries to autheticate with db before ldap" do
        expect(Gitlab::Auth::LDAP::Authentication).not_to receive(:login)

        expect(gl_auth.find_with_user_password(username, password)).to eq(user)
      end

      it "does not find user by using ldap as fallback to for authentication" do
        expect(Gitlab::Auth::LDAP::Authentication).to receive(:login).and_return(nil)

        expect(gl_auth.find_with_user_password('ldap_user', 'password')).to be_nil
      end

      it "find new user by using ldap as fallback to for authentication" do
        expect(Gitlab::Auth::LDAP::Authentication).to receive(:login).and_return(user)

        expect(gl_auth.find_with_user_password('ldap_user', 'password')).to eq(user)
      end
    end

    context "with password authentication disabled for Git" do
      before do
        stub_application_setting(password_authentication_enabled_for_git: false)
      end

      it "does not find user by valid login/password" do
        expect(gl_auth.find_with_user_password(username, password)).to be_nil
      end

      context "with ldap enabled" do
        before do
          allow(Gitlab::Auth::LDAP::Config).to receive(:enabled?).and_return(true)
        end

        it "does not find non-ldap user by valid login/password" do
          expect(gl_auth.find_with_user_password(username, password)).to be_nil
        end
      end
    end
  end

  private

  def expect_results_with_abilities(personal_access_token, abilities, success = true)
    expect(gl_auth.find_for_git_client('', personal_access_token&.token, project: nil, ip: 'ip'))
      .to eq(Gitlab::Auth::Result.new(personal_access_token&.user, nil, personal_access_token.nil? ? nil : :personal_access_token, abilities))
  end
end
