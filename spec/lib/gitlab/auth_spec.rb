# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth, :use_clean_rails_memory_store_caching, feature_category: :system_access do
  include StubRequests

  let_it_be(:project) { create(:project) }

  let(:auth_failure) { { actor: nil, project: nil, type: nil, authentication_abilities: nil } }
  let(:gl_auth) { described_class }

  let(:request) { instance_double(ActionDispatch::Request, ip: 'ip', path: path) }
  let(:path) { '/some_path/example' }

  describe 'constants' do
    it 'API_SCOPES contains all scopes for API access' do
      expect(subject::API_SCOPES).to match_array %i[api read_user read_api create_runner manage_runner k8s_proxy self_rotate]
    end

    it 'ADMIN_SCOPES contains all scopes for ADMIN access' do
      expect(subject::ADMIN_SCOPES).to match_array %i[sudo admin_mode read_service_ping]
    end

    it 'REPOSITORY_SCOPES contains all scopes for REPOSITORY access' do
      expect(subject::REPOSITORY_SCOPES).to match_array %i[read_repository write_repository]
    end

    it 'OBSERVABILITY_SCOPES contains all scopes for Observability access' do
      expect(subject::OBSERVABILITY_SCOPES).to match_array %i[read_observability write_observability]
    end

    it 'OPENID_SCOPES contains all scopes for OpenID Connect' do
      expect(subject::OPENID_SCOPES).to match_array [:openid]
    end

    it 'DEFAULT_SCOPES contains all default scopes' do
      expect(subject::DEFAULT_SCOPES).to match_array [:api]
    end

    it 'VIRTUAL_REGISTRY_SCOPES contains all scopes for Virtual Registry access' do
      expect(subject::VIRTUAL_REGISTRY_SCOPES).to match_array %i[read_virtual_registry write_virtual_registry]
    end
  end

  describe 'available_scopes' do
    before do
      stub_container_registry_config(enabled: true)
    end

    it 'contains all non-default scopes' do
      expect(subject.all_available_scopes).to match_array %i[
        api read_user read_api read_repository read_service_ping write_repository read_registry write_registry
        sudo admin_mode read_observability write_observability create_runner manage_runner k8s_proxy ai_features
        self_rotate
      ]
    end

    it 'contains for non-admin user all non-default scopes without ADMIN access and without observability scopes' do
      user = build_stubbed(:user, admin: false)

      expect(subject.available_scopes_for(user)).to match_array %i[
        api read_user read_api read_repository write_repository read_registry write_registry
        create_runner manage_runner k8s_proxy ai_features self_rotate
      ]
    end

    it 'contains for admin user all non-default scopes with ADMIN access and without observability scopes' do
      user = build_stubbed(:user, admin: true)

      expect(subject.available_scopes_for(user)).to match_array %i[
        api read_user read_api read_repository read_service_ping write_repository read_registry write_registry
        sudo admin_mode create_runner manage_runner k8s_proxy ai_features self_rotate
      ]
    end

    it 'contains for project all resource bot scopes' do
      expect(subject.available_scopes_for(project)).to match_array %i[
        api read_api read_repository write_repository read_registry write_registry
        read_observability write_observability create_runner manage_runner k8s_proxy ai_features
        self_rotate
      ]
    end

    it 'contains for group all resource bot scopes' do
      group = build_stubbed(:group).tap { |g| g.namespace_settings = build_stubbed(:namespace_settings, namespace: g) }

      expect(subject.available_scopes_for(group)).to match_array %i[
        api read_api read_repository write_repository read_registry write_registry
        read_observability write_observability create_runner manage_runner k8s_proxy ai_features
        self_rotate
      ]
    end

    it 'contains for unsupported type no scopes' do
      expect(subject.available_scopes_for(:something)).to be_empty
    end

    it 'optional_scopes contains all non-default scopes' do
      expect(subject.optional_scopes).to match_array %i[
        admin_mode
        ai_features
        ai_workflows
        create_runner
        email
        k8s_proxy
        manage_runner
        openid
        profile
        read_api
        read_observability
        read_registry
        read_repository
        read_service_ping
        read_user
        self_rotate
        sudo
        user:*
        write_observability
        write_registry
        write_repository
      ]
    end

    context 'with observability feature flags' do
      context 'when all disabled' do
        before do
          stub_feature_flags(observability_features: false)
        end

        it 'contains for group all resource bot scopes without observability scopes' do
          group = build_stubbed(:group).tap do |g|
            g.namespace_settings = build_stubbed(:namespace_settings, namespace: g)
          end

          expect(subject.available_scopes_for(group)).to match_array %i[
            api read_api read_repository write_repository read_registry write_registry create_runner manage_runner
            k8s_proxy ai_features self_rotate
          ]
        end

        it 'contains for project all resource bot scopes without observability scopes' do
          group = build_stubbed(:group).tap do |g|
            g.namespace_settings = build_stubbed(:namespace_settings, namespace: g)
          end
          project = build_stubbed(:project, namespace: group)

          expect(subject.available_scopes_for(project)).to match_array %i[
            api read_api read_repository write_repository read_registry write_registry create_runner manage_runner
            k8s_proxy ai_features self_rotate
          ]
        end
      end

      context "with feature flag enabled for specific root group" do
        let(:parent) { build_stubbed(:group) }
        let(:group) do
          build_stubbed(:group, parent: parent).tap { |g| g.namespace_settings = build_stubbed(:namespace_settings, namespace: g) }
        end

        let(:project) { build_stubbed(:project, namespace: group) }

        before do
          stub_feature_flags(observability_features: parent)
        end

        it 'contains for group all resource bot scopes including observability scopes' do
          expect(subject.available_scopes_for(group)).to match_array %i[
            api read_api read_repository write_repository read_registry write_registry
            read_observability write_observability create_runner manage_runner k8s_proxy ai_features
            self_rotate
          ]
        end

        it 'contains for admin user all non-default scopes with ADMIN access and without observability scopes' do
          user = build_stubbed(:user, admin: true)

          expect(subject.available_scopes_for(user)).to match_array %i[
            api read_user read_api read_repository write_repository read_registry write_registry read_service_ping
            sudo admin_mode create_runner manage_runner k8s_proxy ai_features self_rotate
          ]
        end

        it 'contains for project all resource bot scopes including observability scopes' do
          expect(subject.available_scopes_for(project)).to match_array %i[
            api read_api read_repository write_repository read_registry write_registry
            read_observability write_observability create_runner manage_runner k8s_proxy ai_features
            self_rotate
          ]
        end

        it 'contains for other group all resource bot scopes without observability scopes' do
          other_parent = build_stubbed(:group)
          other_group = build_stubbed(:group, parent: other_parent).tap do |g|
            g.namespace_settings = build_stubbed(:namespace_settings, namespace: g)
          end

          expect(subject.available_scopes_for(other_group)).to match_array %i[
            api read_api read_repository write_repository read_registry write_registry
            create_runner manage_runner k8s_proxy ai_features
            self_rotate
          ]
        end

        it 'contains for other project all resource bot scopes without observability scopes' do
          other_parent = build_stubbed(:group)
          other_group = build_stubbed(:group, parent: other_parent).tap do |g|
            g.namespace_settings = build_stubbed(:namespace_settings, namespace: g)
          end
          other_project = build_stubbed(:project, namespace: other_group)

          expect(subject.available_scopes_for(other_project)).to match_array %i[
            api read_api read_repository write_repository read_registry write_registry
            create_runner manage_runner k8s_proxy ai_features self_rotate
          ]
        end
      end
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
          expect(subject.registry_scopes).to eq %i[read_registry write_registry]
        end
      end
    end

    context 'virtual_registry_scopes' do
      context 'when dependency proxy and virtual registry are both disabled' do
        before do
          stub_config(dependency_proxy: { enabled: false })
        end

        it 'is empty' do
          expect(subject.virtual_registry_scopes).to eq []
        end
      end

      context 'when dependency proxy is enabled' do
        before do
          stub_config(dependency_proxy: { enabled: true })
        end

        it 'contains all virtual registry related scopes' do
          expect(subject.virtual_registry_scopes).to eq %i[read_virtual_registry write_virtual_registry]
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
        subject { gl_auth.find_for_git_client('username-does-not-matter', 'password-does-not-matter', project: nil, request: request) }

        before do
          expect_next_instance_of(Gitlab::Auth::IpRateLimiter) do |rate_limiter|
            expect(rate_limiter).to receive(:banned?).and_return(true)
          end
        end

        it 'raises an IpBlocked exception' do
          expect { subject }.to raise_error(Gitlab::Auth::IpBlocked)
        end
      end

      context 'for CI registry user' do
        let_it_be(:build) { create(:ci_build, :running) }

        it 'skips rate limiting for successful auth' do
          expect_next_instance_of(Gitlab::Auth::IpRateLimiter) do |rate_limiter|
            expect(rate_limiter).not_to receive(:reset!)
          end

          gl_auth.find_for_git_client('gitlab-ci-token', build.token, project: build.project, request: request)
        end

        it 'skips rate limiting for failed auth' do
          expect_next_instance_of(Gitlab::Auth::IpRateLimiter) do |rate_limiter|
            expect(rate_limiter).not_to receive(:register_fail!)
          end

          gl_auth.find_for_git_client('gitlab-ci-token', 'wrong_token', project: build.project, request: request)
        end
      end

      context 'for other users' do
        let_it_be(:user) { create(:user) }

        it 'resets rate limit for successful auth' do
          expect_next_instance_of(Gitlab::Auth::IpRateLimiter) do |rate_limiter|
            expect(rate_limiter).to receive(:reset!)
          end

          gl_auth.find_for_git_client(user.username, user.password, project: nil, request: request)
        end

        it 'rate limits a user by unique IPs' do
          expect_next_instance_of(Gitlab::Auth::IpRateLimiter) do |rate_limiter|
            expect(rate_limiter).to receive(:reset!)
          end
          expect(Gitlab::Auth::UniqueIpsLimiter).to receive(:limit_user!).twice.and_call_original

          gl_auth.find_for_git_client(user.username, user.password, project: nil, request: request)
        end

        it 'registers failure for failed auth' do
          expect_next_instance_of(Gitlab::Auth::IpRateLimiter) do |rate_limiter|
            expect(rate_limiter).to receive(:register_fail!)
          end

          gl_auth.find_for_git_client(user.username, 'wrong_password', project: nil, request: request)
        end

        context 'when failure goes over threshold' do
          let(:token_prefix) { Gitlab::ApplicationSettingFetcher.current_application_settings.personal_access_token_prefix }
          let(:token_string) { "#{token_prefix}PAT1234" }
          let(:relative_url) { "/some/project.git/info/refs?private_token=#{token_string}" }
          let(:request) { request_for_url(relative_url) }

          before do
            expect_next_instance_of(Gitlab::Auth::IpRateLimiter) do |rate_limiter|
              expect(rate_limiter).to receive(:register_fail!).and_return(true)
            end
          end

          it 'logs a message with a filtered path' do
            expect(Gitlab::AuthLogger).to receive(:error).with(
              message: "Rack_Attack: Git auth failures has exceeded the threshold. " \
                "IP has been temporarily banned from Git auth.",
              env: :blocklist,
              remote_ip: request.ip,
              request_method: request.request_method,
              path: request.filtered_path,
              login: user.username
            )

            gl_auth.find_for_git_client(user.username, 'wrong_password', project: nil, request: request)
          end
        end
      end
    end

    context 'build token' do
      subject { gl_auth.find_for_git_client(username, build.token, project: project, request: request) }

      let(:username) { 'gitlab-ci-token' }

      context 'for running build' do
        let!(:group) { create(:group) }
        let!(:project) { create(:project, group: group) }
        let!(:build) { create(:ci_build, :running, project: project) }

        it 'recognises user-less build' do
          expect(subject).to have_attributes(actor: nil, project: build.project, type: :ci, authentication_abilities: described_class.build_authentication_abilities)
        end

        it 'recognises user token' do
          build.update!(user: create(:user))

          expect(subject).to have_attributes(actor: build.user, project: build.project, type: :build, authentication_abilities: described_class.build_authentication_abilities)
        end

        it 'recognises project level bot access token' do
          build.update!(user: create(:user, :project_bot))
          project.add_maintainer(build.user)

          expect(subject).to have_attributes(actor: build.user, project: build.project, type: :build, authentication_abilities: described_class.build_authentication_abilities)
        end

        it 'recognises group level bot access token' do
          build.update!(user: create(:user, :project_bot))
          group.add_maintainer(build.user)

          expect(subject).to have_attributes(actor: build.user, project: build.project, type: :build, authentication_abilities: described_class.build_authentication_abilities)
        end

        it 'recognises project level security_policy_bot access token' do
          build.update!(user: create(:user, :security_policy_bot))
          project.add_guest(build.user)

          expect(subject).to have_attributes(actor: build.user, project: build.project, type: :build, authentication_abilities: described_class.build_authentication_abilities)
        end

        it 'fails with blocked user token' do
          build.update!(user: create(:user, :blocked))

          expect(subject).to have_attributes(auth_failure)
        end

        context 'username is not gitlab-ci-token' do
          let(:username) { 'another_username' }

          it 'fails to authenticate' do
            expect(subject).to have_attributes(auth_failure)
          end
        end
      end

      (Ci::HasStatus::AVAILABLE_STATUSES - ['running']).each do |build_status|
        context "for #{build_status} build" do
          let!(:build) { create(:ci_build, status: build_status) }
          let(:project) { build.project }

          it 'denies authentication' do
            expect(subject).to have_attributes(auth_failure)
          end
        end
      end
    end

    it 'recognizes other ci services' do
      project.create_drone_ci_integration(active: true)
      project.drone_ci_integration.update!(token: 'token', drone_url: generate(:url))

      expect(gl_auth.find_for_git_client('drone-ci-token', 'token', project: project, request: request)).to have_attributes(actor: nil, project: project, type: :ci, authentication_abilities: described_class.build_authentication_abilities)
    end

    it 'recognizes master passwords' do
      user = create(:user)

      expect(gl_auth.find_for_git_client(user.username, user.password, project: nil, request: request)).to have_attributes(actor: user, project: nil, type: :gitlab_or_ldap, authentication_abilities: described_class.full_authentication_abilities)
    end

    include_examples 'user login operation with unique ip limit' do
      let(:user) { create(:user) }

      def operation
        expect(gl_auth.find_for_git_client(user.username, user.password, project: nil, request: request)).to have_attributes(actor: user, project: nil, type: :gitlab_or_ldap, authentication_abilities: described_class.full_authentication_abilities)
      end
    end

    context 'while using LFS authenticate' do
      let(:path) { '/namespace/project.git/info/lfs/objects/batch' }

      context 'while using LFS token on non-LFS path' do
        let(:path) { '/namespace/project.git/other/path' }

        it 'does not authenticate with LFS token on non-LFS path' do
          user = create(:user)
          token = Gitlab::LfsToken.new(user, project).token

          expect(gl_auth.find_for_git_client(user.username, token, project: nil, request: request)).to have_attributes(auth_failure)
        end
      end

      it 'recognizes user lfs tokens' do
        user = create(:user)
        token = Gitlab::LfsToken.new(user, project).token

        expect(gl_auth.find_for_git_client(user.username, token, project: nil, request: request)).to have_attributes(actor: user, project: nil, type: :lfs_token, authentication_abilities: described_class.read_write_project_authentication_abilities)
      end

      it 'recognizes deploy key lfs tokens' do
        key = create(:deploy_key)
        token = Gitlab::LfsToken.new(key, project).token

        expect(gl_auth.find_for_git_client("lfs+deploy-key-#{key.id}", token, project: nil, request: request)).to have_attributes(actor: key, project: nil, type: :lfs_deploy_token, authentication_abilities: described_class.read_only_authentication_abilities)
      end

      it 'does not try password auth before oauth' do
        user = create(:user)
        token = Gitlab::LfsToken.new(user, project).token

        expect(gl_auth).not_to receive(:find_with_user_password)

        gl_auth.find_for_git_client(user.username, token, project: nil, request: request)
      end

      it 'grants deploy key write permissions' do
        key = create(:deploy_key)
        create(:deploy_keys_project, :write_access, deploy_key: key, project: project)
        token = Gitlab::LfsToken.new(key, project).token

        expect(gl_auth.find_for_git_client("lfs+deploy-key-#{key.id}", token, project: project, request: request)).to have_attributes(actor: key, project: nil, type: :lfs_deploy_token, authentication_abilities: described_class.read_write_authentication_abilities)
      end

      it 'does not grant deploy key write permissions' do
        key = create(:deploy_key)
        token = Gitlab::LfsToken.new(key, project).token

        expect(gl_auth.find_for_git_client("lfs+deploy-key-#{key.id}", token, project: project, request: request)).to have_attributes(actor: key, project: nil, type: :lfs_deploy_token, authentication_abilities: described_class.read_only_authentication_abilities)
      end

      it 'does fail if the user and token are nil' do
        expect(gl_auth.find_for_git_client(nil, nil, project: project, request: request)).to have_attributes(auth_failure)
      end

      context 'when lfs token belongs to a different project' do
        let_it_be(:actor) { create(:user) }
        let_it_be(:another_project) { create(:project) }

        context 'when project is provided' do
          it 'returns an auth failure' do
            token = Gitlab::LfsToken.new(actor, another_project).token

            expect(gl_auth.find_for_git_client(actor.username, token, project: project, request: request)).to have_attributes(auth_failure)
          end
        end

        context 'without project' do
          it 'grants permissions' do
            token = Gitlab::LfsToken.new(actor, another_project).token

            expect(gl_auth.find_for_git_client(actor.username, token, project: nil, request: request)).to have_attributes(actor: actor, project: nil, type: :lfs_token, authentication_abilities: described_class.read_write_project_authentication_abilities)
          end
        end
      end
    end

    describe 'using OAuth tokens as passwords' do
      let_it_be(:organization) { create(:organization) }

      let(:user) { create(:user, organizations: [organization]) }
      let(:application) { Doorkeeper::Application.create!(name: 'MyApp', redirect_uri: 'https://app.com', owner: user) }
      let(:scopes) { 'api' }

      let(:token) do
        Doorkeeper::AccessToken.create!(
          application_id: application.id,
          resource_owner_id: user.id,
          scopes: scopes,
          organization_id: organization.id).plaintext_token
      end

      def authenticate(username:, password:)
        gl_auth.find_for_git_client(username, password, project: nil, request: request)
      end

      shared_examples 'an oauth failure' do
        it 'fails' do
          expect(authenticate(username: "oauth2", password: token))
            .to have_attributes(auth_failure)
        end
      end

      context 'with specified scopes' do
        using RSpec::Parameterized::TableSyntax

        where(:scopes, :abilities) do
          'api'                 | described_class.full_authentication_abilities
          'read_api'            | described_class.read_only_authentication_abilities
          'read_repository'     | %i[download_code]
          'write_repository'    | %i[download_code push_code]
          'create_runner'       | %i[create_instance_runner create_runner]
          'manage_runner'       | %i[assign_runner update_runner delete_runner]
          'read_user'           | []
          'sudo'                | []
          'openid'              | []
          'profile'             | []
          'email'               | []
          'read_observability'  | []
          'write_observability' | []
        end

        with_them do
          it 'authenticates with correct abilities' do
            expect(authenticate(username: 'oauth2', password: token))
              .to have_attributes(actor: user, project: nil, type: :oauth, authentication_abilities: abilities)
          end

          it 'authenticates with correct abilities without special username' do
            expect(authenticate(username: user.username, password: token))
              .to have_attributes(actor: user, project: nil, type: :oauth, authentication_abilities: abilities)
          end

          it 'tracks any composite identity' do
            expect(::Gitlab::Auth::Identity).to receive(:link_from_oauth_token).and_call_original

            expect(authenticate(username: "oauth2", password: token))
              .to have_attributes(actor: user, project: nil, type: :oauth, authentication_abilities: abilities)
          end
        end
      end

      it 'does not try password auth before oauth' do
        expect(gl_auth).not_to receive(:find_with_user_password)

        authenticate(username: "oauth2", password: token)
      end

      context 'blocked user' do
        let(:user) { create(:user, :blocked) }

        it_behaves_like 'an oauth failure'
      end

      context 'orphaned token' do
        before do
          user.destroy!
        end

        it_behaves_like 'an oauth failure'
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

      it 'succeeds for personal access tokens with the `create_runner` scope' do
        personal_access_token = create(:personal_access_token, scopes: ['create_runner'])

        expect_results_with_abilities(personal_access_token, %i[create_instance_runner create_runner])
      end

      it 'succeeds for personal access tokens with the `manage_runner` scope' do
        personal_access_token = create(:personal_access_token, scopes: ['manage_runner'])

        expect_results_with_abilities(personal_access_token, %i[assign_runner update_runner delete_runner])
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

      it 'fails if it is an impersonation token but impersonation is blocked' do
        stub_config_setting(impersonation_enabled: false)

        impersonation_token = create(:personal_access_token, :impersonation, scopes: ['api'])

        expect(gl_auth.find_for_git_client('', impersonation_token.token, project: nil, request: request))
          .to have_attributes(auth_failure)
      end

      it 'limits abilities based on scope' do
        personal_access_token = create(:personal_access_token, scopes: %w[read_user sudo])

        expect_results_with_abilities(personal_access_token, [])
      end

      it 'fails if password is nil' do
        expect_results_with_abilities(nil, nil, false)
      end

      context 'when user is blocked' do
        let(:user) { create(:user, :blocked) }
        let(:personal_access_token) { create(:personal_access_token, scopes: ['read_registry'], user: user) }

        before do
          stub_container_registry_config(enabled: true)
        end

        it 'fails if user is blocked' do
          expect(gl_auth.find_for_git_client('', personal_access_token.token, project: nil, request: request))
            .to have_attributes(auth_failure)
        end
      end

      context 'when using a resource access token' do
        shared_examples 'with a valid access token' do
          it 'successfully authenticates the project bot' do
            expect(gl_auth.find_for_git_client(project_bot_user.username, access_token.token, project: project, request: request))
              .to have_attributes(actor: project_bot_user, project: nil, type: :personal_access_token, authentication_abilities: described_class.full_authentication_abilities)
          end

          it 'successfully authenticates the project bot with a nil project' do
            expect(gl_auth.find_for_git_client(project_bot_user.username, access_token.token, project: nil, request: request))
              .to have_attributes(actor: project_bot_user, project: nil, type: :personal_access_token, authentication_abilities: described_class.full_authentication_abilities)
          end
        end

        shared_examples 'with an invalid access token' do
          it 'fails for a non-member' do
            expect(gl_auth.find_for_git_client(project_bot_user.username, access_token.token, project: project, request: request))
              .to have_attributes(auth_failure)
          end

          context 'when project bot user is blocked' do
            before do
              project_bot_user.block!
            end

            it 'fails for a blocked project bot' do
              expect(gl_auth.find_for_git_client(project_bot_user.username, access_token.token, project: project, request: request))
                .to have_attributes(auth_failure)
            end
          end
        end

        context 'when using a personal namespace project access token' do
          let_it_be(:project_bot_user) { create(:user, :project_bot) }
          let_it_be(:access_token) { create(:personal_access_token, user: project_bot_user) }

          context 'when the token belongs to the project' do
            before do
              project.add_maintainer(project_bot_user)
            end

            it_behaves_like 'with a valid access token'
          end

          it_behaves_like 'with an invalid access token'
        end

        context 'when in a group namespace' do
          let_it_be(:group) { create(:group) }
          let_it_be(:project) { create(:project, group: group) }

          context 'when using a project access token' do
            let_it_be(:project_bot_user) { create(:user, :project_bot) }
            let_it_be(:access_token) { create(:personal_access_token, user: project_bot_user) }

            context 'when token user belongs to the project' do
              before do
                project.add_maintainer(project_bot_user)
              end

              it_behaves_like 'with a valid access token'
            end

            it_behaves_like 'with an invalid access token'
          end

          context 'when using a group access token' do
            let_it_be(:project_bot_user) { create(:user, name: 'Group token bot', email: "group_#{group.id}_bot@example.com", username: "group_#{group.id}_bot", user_type: :project_bot) }
            let_it_be(:access_token) { create(:personal_access_token, user: project_bot_user) }

            context 'when the token belongs to the group' do
              before do
                group.add_maintainer(project_bot_user)
              end

              it_behaves_like 'with a valid access token'
            end

            it_behaves_like 'with an invalid access token'

            context 'when the token belongs to a group via project share' do
              let_it_be(:invited_group) { create(:group) }

              before do
                invited_group.add_maintainer(project_bot_user)
                create(:project_group_link, group: invited_group, project: project)
              end

              it_behaves_like 'with a valid access token'
            end
          end
        end
      end

      it 'updates last_used_at column if token is valid' do
        personal_access_token = create(:personal_access_token, scopes: ['write_repository'])

        expect { gl_auth.find_for_git_client('', personal_access_token.token, project: nil, request: request) }.to change { personal_access_token.reload.last_used_at }
      end
    end

    context 'while using regular user and password' do
      it 'fails for a blocked user' do
        user = create(
          :user,
          :blocked,
          username: 'normal_user'
        )

        expect(gl_auth.find_for_git_client(user.username, user.password, project: nil, request: request))
          .to have_attributes(auth_failure)
      end

      context 'when 2fa is enabled globally' do
        let_it_be(:user) do
          create(:user, username: 'normal_user', otp_grace_period_started_at: 1.day.ago)
        end

        before do
          stub_application_setting(require_two_factor_authentication: true)
        end

        it 'fails if grace period expired' do
          stub_application_setting(two_factor_grace_period: 0)

          expect { gl_auth.find_for_git_client(user.username, user.password, project: nil, request: request) }
            .to raise_error(Gitlab::Auth::MissingPersonalAccessTokenError)
        end

        it 'goes through if grace period is not expired yet' do
          stub_application_setting(two_factor_grace_period: 72)

          expect(gl_auth.find_for_git_client(user.username, user.password, project: nil, request: request))
            .to have_attributes(actor: user, project: nil, type: :gitlab_or_ldap, authentication_abilities: described_class.full_authentication_abilities)
        end
      end

      context 'when 2fa is enabled personally' do
        let(:user) do
          create(:user, :two_factor, username: 'normal_user', otp_grace_period_started_at: 1.day.ago)
        end

        it 'fails' do
          expect { gl_auth.find_for_git_client(user.username, user.password, project: nil, request: request) }
            .to raise_error(Gitlab::Auth::MissingPersonalAccessTokenError)
        end
      end

      it 'goes through lfs authentication' do
        user = create(
          :user,
          username: 'normal_user'
        )

        expect(gl_auth.find_for_git_client(user.username, user.password, project: nil, request: request))
          .to have_attributes(actor: user, project: nil, type: :gitlab_or_ldap, authentication_abilities: described_class.full_authentication_abilities)
      end

      it 'goes through oauth authentication when the username is oauth2' do
        user = create(
          :user,
          username: 'oauth2'
        )

        expect(gl_auth.find_for_git_client(user.username, user.password, project: nil, request: request))
          .to have_attributes(actor: user, project: nil, type: :gitlab_or_ldap, authentication_abilities: described_class.full_authentication_abilities)
      end
    end

    it 'returns double nil for invalid credentials' do
      login = 'foo'

      expect(gl_auth.find_for_git_client(login, 'bar', project: nil, request: request)).to have_attributes(auth_failure)
    end

    it 'throws an error suggesting user create a PAT when internal auth is disabled' do
      allow_any_instance_of(ApplicationSetting).to receive(:password_authentication_enabled_for_git?) { false }

      expect { gl_auth.find_for_git_client('foo', 'bar', project: nil, request: request) }.to raise_error(Gitlab::Auth::MissingPersonalAccessTokenError)
    end

    context 'while using deploy tokens' do
      shared_examples 'registry token scope' do
        it 'fails when login is not valid' do
          expect(gl_auth.find_for_git_client('random_login', deploy_token.token, project: project, request: request))
            .to have_attributes(auth_failure)
        end

        it 'fails when token is not valid' do
          expect(gl_auth.find_for_git_client(login, '123123', project: project, request: request))
            .to have_attributes(auth_failure)
        end

        it 'fails if token is nil' do
          expect(gl_auth.find_for_git_client(login, nil, project: nil, request: request))
            .to have_attributes(auth_failure)
        end

        it 'fails if token is not related to project' do
          expect(gl_auth.find_for_git_client(login, 'abcdef', project: nil, request: request))
            .to have_attributes(auth_failure)
        end

        it 'fails if token has been revoked' do
          deploy_token.revoke!

          expect(deploy_token.revoked?).to be_truthy
          expect(gl_auth.find_for_git_client('deploy-token', deploy_token.token, project: nil, request: request))
            .to have_attributes(auth_failure)
        end
      end

      shared_examples 'deploy token with disabled feature' do
        context 'when registry disabled' do
          before do
            stub_container_registry_config(enabled: false)
          end

          it 'fails when login and token are valid' do
            expect(gl_auth.find_for_git_client(login, deploy_token.token, project: nil, request: request))
              .to have_attributes(auth_failure)
          end
        end

        context 'when repository is disabled' do
          let(:project) { create(:project, :repository_disabled) }

          it 'fails when login and token are valid' do
            expect(gl_auth.find_for_git_client(login, deploy_token.token, project: project, request: request))
              .to have_attributes(auth_failure)
          end
        end
      end

      context 'when deploy token and user have the same username' do
        let(:username) { 'normal_user' }
        let(:user) { create(:user, username: username) }
        let(:deploy_token) { create(:deploy_token, username: username, read_registry: false, projects: [project]) }

        it 'succeeds for the token' do
          auth_success = { actor: deploy_token, project: project, type: :deploy_token, authentication_abilities: [:download_code] }

          expect(gl_auth.find_for_git_client(username, deploy_token.token, project: project, request: request))
            .to have_attributes(auth_success)
        end

        it 'succeeds for the user' do
          auth_success = { actor: user, project: nil, type: :gitlab_or_ldap, authentication_abilities: described_class.full_authentication_abilities }

          expect(gl_auth.find_for_git_client(username, user.password, project: project, request: request))
            .to have_attributes(auth_success)
        end
      end

      context 'when deploy tokens have the same username' do
        context 'and belong to the same project' do
          let!(:read_registry) { create(:deploy_token, username: 'deployer', read_repository: false, projects: [project]) }
          let!(:read_repository) { create(:deploy_token, username: read_registry.username, read_registry: false, projects: [project]) }
          let(:auth_success) { { actor: read_repository, project: project, type: :deploy_token, authentication_abilities: [:download_code] } }

          it 'succeeds for the right token' do
            expect(gl_auth.find_for_git_client('deployer', read_repository.token, project: project, request: request))
              .to have_attributes(auth_success)
          end

          it 'fails for the wrong token' do
            expect(gl_auth.find_for_git_client('deployer', read_registry.token, project: project, request: request))
              .not_to have_attributes(auth_success)
          end
        end

        context 'and belong to different projects' do
          let_it_be(:other_project) { create(:project) }

          let!(:read_registry) { create(:deploy_token, username: 'deployer', read_repository: false, projects: [project]) }
          let!(:read_repository) { create(:deploy_token, username: read_registry.username, read_registry: false, projects: [other_project]) }
          let(:auth_success) { { actor: read_repository, project: other_project, type: :deploy_token, authentication_abilities: [:download_code] } }

          it 'succeeds for the right token' do
            expect(gl_auth.find_for_git_client('deployer', read_repository.token, project: other_project, request: request))
              .to have_attributes(auth_success)
          end

          it 'fails for the wrong token' do
            expect(gl_auth.find_for_git_client('deployer', read_registry.token, project: other_project, request: request))
              .not_to have_attributes(auth_success)
          end
        end
      end

      context 'when the deploy token has read_repository as scope' do
        let(:deploy_token) { create(:deploy_token, read_registry: false, projects: [project]) }
        let(:login) { deploy_token.username }

        it 'succeeds when login and token are valid' do
          auth_success = { actor: deploy_token, project: project, type: :deploy_token, authentication_abilities: [:download_code] }

          expect(gl_auth.find_for_git_client(login, deploy_token.token, project: project, request: request))
            .to have_attributes(auth_success)
        end

        it 'succeeds when custom login and token are valid' do
          deploy_token = create(:deploy_token, username: 'deployer', read_registry: false, projects: [project])
          auth_success = { actor: deploy_token, project: project, type: :deploy_token, authentication_abilities: [:download_code] }

          expect(gl_auth.find_for_git_client('deployer', deploy_token.token, project: project, request: request))
            .to have_attributes(auth_success)
        end

        it 'does not attempt to rate limit unique IPs for a deploy token' do
          expect(Gitlab::Auth::UniqueIpsLimiter).not_to receive(:limit_user!)

          gl_auth.find_for_git_client(login, deploy_token.token, project: project, request: request)
        end

        it 'fails when login is not valid' do
          expect(gl_auth.find_for_git_client('random_login', deploy_token.token, project: project, request: request))
            .to have_attributes(auth_failure)
        end

        it 'fails when token is not valid' do
          expect(gl_auth.find_for_git_client(login, '123123', project: project, request: request))
            .to have_attributes(auth_failure)
        end

        it 'fails if token is nil' do
          expect(gl_auth.find_for_git_client(login, nil, project: project, request: request))
            .to have_attributes(auth_failure)
        end

        it 'fails if token is not related to project' do
          another_deploy_token = create(:deploy_token)
          expect(gl_auth.find_for_git_client(another_deploy_token.username, another_deploy_token.token, project: project, request: request))
            .to have_attributes(auth_failure)
        end

        it 'fails if token has been revoked' do
          deploy_token.revoke!

          expect(deploy_token.revoked?).to be_truthy
          expect(gl_auth.find_for_git_client('deploy-token', deploy_token.token, project: project, request: request))
            .to have_attributes(auth_failure)
        end
      end

      context 'when the deploy token is of group type' do
        let(:project_with_group) { create(:project, group: create(:group)) }
        let(:deploy_token) { create(:deploy_token, :group, read_repository: true, groups: [project_with_group.group]) }
        let(:login) { deploy_token.username }

        subject { gl_auth.find_for_git_client(login, deploy_token.token, project: project_with_group, request: request) }

        it 'succeeds when login and a group deploy token are valid' do
          auth_success = { actor: deploy_token, project: project_with_group, type: :deploy_token, authentication_abilities: [:download_code, :read_container_image] }

          expect(subject).to have_attributes(auth_success)
        end

        it 'fails if token is not related to group' do
          another_deploy_token = create(:deploy_token, :group, read_repository: true)

          expect(gl_auth.find_for_git_client(another_deploy_token.username, another_deploy_token.token, project: project_with_group, request: request))
            .to have_attributes(auth_failure)
        end
      end

      context 'when the deploy token has read_registry as a scope' do
        let(:deploy_token) { create(:deploy_token, read_repository: false, projects: [project]) }
        let(:login) { deploy_token.username }

        context 'when registry enabled' do
          before do
            stub_container_registry_config(enabled: true)
          end

          it 'succeeds when login and a project token are valid' do
            auth_success = { actor: deploy_token, project: project, type: :deploy_token, authentication_abilities: [:read_container_image] }

            expect(gl_auth.find_for_git_client(login, deploy_token.token, project: project, request: request))
              .to have_attributes(auth_success)
          end

          it_behaves_like 'registry token scope'
        end

        it_behaves_like 'deploy token with disabled feature'
      end

      context 'when the deploy token has write_registry as a scope' do
        let_it_be(:deploy_token) { create(:deploy_token, write_registry: true, read_repository: false, read_registry: false, projects: [project]) }
        let_it_be(:login) { deploy_token.username }

        context 'when registry enabled' do
          before do
            stub_container_registry_config(enabled: true)
          end

          it 'succeeds when login and a project token are valid' do
            auth_success = { actor: deploy_token, project: project, type: :deploy_token, authentication_abilities: [:create_container_image] }

            expect(gl_auth.find_for_git_client(login, deploy_token.token, project: project, request: request))
              .to have_attributes(auth_success)
          end

          it_behaves_like 'registry token scope'
        end

        it_behaves_like 'deploy token with disabled feature'
      end
    end
  end

  describe '#build_access_token_check' do
    subject(:result) do
      gl_auth.find_for_git_client('gitlab-ci-token', build.token, project: build.project, request: request)
    end

    let_it_be(:user) { create(:user) }

    context 'for running build' do
      let!(:build) { create(:ci_build, :running, user: user) }

      it 'executes query using primary database' do
        expect(::Ci::JobToken::Jwt).to receive(:decode).with(build.token).and_wrap_original do |m, *args|
          expect(::Gitlab::Database::LoadBalancing::SessionMap.current(Ci::Build.load_balancer).use_primary?)
            .to be(true)
          m.call(*args)
        end

        expect(result).to be_a(Gitlab::Auth::Result)
        expect(result.actor).to eq(user)
        expect(result.project).to eq(build.project)
        expect(result.type).to eq(:build)
      end

      context 'with a database token' do
        before do
          stub_feature_flags(ci_job_token_jwt: false)
        end

        it 'executes query using primary database' do
          expect(Ci::Build).to receive(:find_by_token).with(build.token).and_wrap_original do |m, *args|
            expect(::Gitlab::Database::LoadBalancing::SessionMap.current(Ci::Build.load_balancer).use_primary?)
              .to be(true)
            m.call(*args)
          end

          expect(result).to be_a(Gitlab::Auth::Result)
          expect(result.actor).to eq(user)
          expect(result.project).to eq(build.project)
          expect(result.type).to eq(:build)
        end
      end
    end
  end

  describe 'find_with_user_password' do
    let!(:user) { create(:user, username: username) }
    let(:username) { 'John' } # username isn't lowercase, test this

    it "finds user by valid login/password" do
      expect(gl_auth.find_with_user_password(username, user.password)).to eql user
    end

    it 'finds user by valid email/password with case-insensitive email' do
      expect(gl_auth.find_with_user_password(user.email.upcase, user.password)).to eql user
    end

    it 'finds user by valid username/password with case-insensitive username' do
      expect(gl_auth.find_with_user_password(username.upcase, user.password)).to eql user
    end

    it "does not find user with invalid password" do
      expect(gl_auth.find_with_user_password(username, 'incorrect_password')).not_to eql user
    end

    it "does not find user with invalid login" do
      username = 'wrong'
      expect(gl_auth.find_with_user_password(username, user.password)).not_to eql user
    end

    include_examples 'user login operation with unique ip limit' do
      def operation
        expect(gl_auth.find_with_user_password(username, user.password)).to eq(user)
      end
    end

    it 'finds the user in deactivated state' do
      user.deactivate!

      expect(gl_auth.find_with_user_password(username, user.password)).to eql user
    end

    it "does not find user in blocked state" do
      user.block

      expect(gl_auth.find_with_user_password(username, user.password)).not_to eql user
    end

    it 'does not find user in locked state' do
      user.lock_access!

      expect(gl_auth.find_with_user_password(username, user.password)).not_to eql user
    end

    it "does not find user in ldap_blocked state" do
      user.ldap_block

      expect(gl_auth.find_with_user_password(username, user.password)).not_to eql user
    end

    it 'does not find user in blocked_pending_approval state' do
      user.block_pending_approval

      expect(gl_auth.find_with_user_password(username, user.password)).not_to eql user
    end

    context 'with increment_failed_attempts' do
      wrong_password = 'incorrect_password'

      it 'increments failed_attempts when true and password is incorrect' do
        expect do
          gl_auth.find_with_user_password(username, wrong_password, increment_failed_attempts: true)
          user.reload
        end.to change(user, :failed_attempts).from(0).to(1)
      end

      it 'resets failed_attempts when true and password is correct' do
        user.failed_attempts = 2
        user.save!

        expect do
          gl_auth.find_with_user_password(username, user.password, increment_failed_attempts: true)
          user.reload
        end.to change(user, :failed_attempts).from(2).to(0)
      end

      it 'does not increment failed_attempts by default' do
        expect do
          gl_auth.find_with_user_password(username, wrong_password)
          user.reload
        end.not_to change(user, :failed_attempts)
      end

      context 'when the database is read-only' do
        before do
          allow(Gitlab::Database).to receive(:read_only?).and_return(true)
        end

        it 'does not increment failed_attempts when true and password is incorrect' do
          expect do
            gl_auth.find_with_user_password(username, wrong_password, increment_failed_attempts: true)
            user.reload
          end.not_to change(user, :failed_attempts)
        end

        it 'does not reset failed_attempts when true and password is correct' do
          user.failed_attempts = 2
          user.save!

          expect do
            gl_auth.find_with_user_password(username, user.password, increment_failed_attempts: true)
            user.reload
          end.not_to change(user, :failed_attempts)
        end
      end
    end

    context "with ldap enabled" do
      before do
        allow(Gitlab::Auth::Ldap::Config).to receive(:enabled?).and_return(true)
      end

      it "tries to autheticate with db before ldap" do
        expect(Gitlab::Auth::Ldap::Authentication).not_to receive(:login)

        expect(gl_auth.find_with_user_password(username, user.password)).to eq(user)
      end

      it "does not find user by using ldap as fallback to for authentication" do
        expect(Gitlab::Auth::Ldap::Authentication).to receive(:login).and_return(nil)

        expect(gl_auth.find_with_user_password('ldap_user', 'password')).to be_nil
      end

      it "find new user by using ldap as fallback to for authentication" do
        expect(Gitlab::Auth::Ldap::Authentication).to receive(:login).and_return(user)

        expect(gl_auth.find_with_user_password('ldap_user', 'password')).to eq(user)
      end
    end

    context "with password authentication disabled for Git" do
      before do
        stub_application_setting(password_authentication_enabled_for_git: false)
      end

      it "does not find user by valid login/password" do
        expect(gl_auth.find_with_user_password(username, user.password)).to be_nil
      end

      context "with ldap enabled" do
        before do
          allow(Gitlab::Auth::Ldap::Config).to receive(:enabled?).and_return(true)
        end

        it "does not find non-ldap user by valid login/password" do
          expect(gl_auth.find_with_user_password(username, user.password)).to be_nil
        end
      end
    end
  end

  describe ".resource_bot_scopes" do
    subject { described_class.resource_bot_scopes }

    it { is_expected.to include(*described_class::API_SCOPES - [:read_user]) }
    it { is_expected.to include(*described_class::REPOSITORY_SCOPES) }

    it { is_expected.to include(*described_class.registry_scopes) } unless described_class.registry_scopes.empty?
    it { is_expected.to include(*described_class::OBSERVABILITY_SCOPES) }
  end

  private

  def expect_results_with_abilities(personal_access_token, abilities, success = true)
    expect(gl_auth.find_for_git_client('', personal_access_token&.token, project: nil, request: request))
      .to have_attributes(actor: personal_access_token&.user, project: nil, type: personal_access_token.nil? ? nil : :personal_access_token, authentication_abilities: abilities)
  end
end
