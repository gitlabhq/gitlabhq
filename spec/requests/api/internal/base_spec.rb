# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::Base, feature_category: :system_access do
  include GitlabShellHelpers
  include APIInternalBaseHelpers

  let_it_be(:project, reload: true) { create(:project, :repository, :wiki_repo) }
  let_it_be(:user, reload: true) { create(:user, organizations: [project.organization]) }
  let_it_be(:personal_snippet) { create(:personal_snippet, :repository, author: user) }
  let_it_be(:project_snippet) { create(:project_snippet, :repository, author: user, project: project) }
  let_it_be(:max_pat_access_token_lifetime) do
    PersonalAccessToken::MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS.days.from_now.to_date.freeze
  end

  let(:key) { create(:key, user: user) }
  let(:secret_token) { Gitlab::Shell.secret_token }
  let(:gl_repository) { "project-#{project.id}" }
  let(:reference_counter) { double('ReferenceCounter') }
  let(:snippet_changes) { "#{TestEnv::BRANCH_SHA['snippet/single-file']} #{TestEnv::BRANCH_SHA['snippet/edit-file']} refs/heads/snippet/edit-file" }

  describe "GET /internal/check" do
    def perform_request(headers: gitlab_shell_internal_api_request_header)
      get api("/internal/check"), headers: headers
    end

    it do
      expect_any_instance_of(Redis).to receive(:ping).and_return('PONG')

      perform_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['api_version']).to eq(API::API.version)
      expect(json_response['redis']).to be(true)
    end

    it 'returns false for field `redis` when redis is unavailable' do
      expect_any_instance_of(Redis).to receive(:ping).and_raise(Errno::ENOENT)

      perform_request

      expect(json_response['redis']).to be(false)
    end

    context 'authenticating' do
      it 'authenticates using a jwt token in a header' do
        perform_request

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'authenticates using a jwt token with an IAT from 10 seconds in the future' do
        headers =
          travel_to(Time.now + 10.seconds) do
            gitlab_shell_internal_api_request_header
          end

        perform_request(headers: headers)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns 401 when jwt token is expired' do
        headers = gitlab_shell_internal_api_request_header

        travel_to(2.minutes.since) do
          perform_request(headers: headers)
        end

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'returns 401 when jwt issuer is not Gitlab-Shell' do
        perform_request(headers: gitlab_shell_internal_api_request_header(issuer: "gitlab-workhorse"))

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'returns 401 when jwt token is not provided, even if plain secret is provided' do
        perform_request(headers: { API::Helpers::GITLAB_SHARED_SECRET_HEADER => Base64.encode64(secret_token) })

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /internal/two_factor_recovery_codes' do
    let(:key_id) { key.id }

    subject do
      post api('/internal/two_factor_recovery_codes'),
        params: { key_id: key_id },
        headers: gitlab_shell_internal_api_request_header
    end

    it_behaves_like 'actor key validations'

    context 'key is a deploy key' do
      let(:key_id) { create(:deploy_key).id }

      it 'returns an error message' do
        subject

        expect(json_response['success']).to be_falsey
        expect(json_response['message']).to eq('Deploy keys cannot be used to retrieve recovery codes')
      end
    end

    context 'when two-factor is enabled' do
      it 'returns new recovery codes when the user exists' do
        allow_any_instance_of(User).to receive(:two_factor_enabled?).and_return(true)
        allow_any_instance_of(User)
          .to receive(:generate_otp_backup_codes!).and_return(%w[119135e5a3ebce8e 34bd7b74adbc8861])

        subject

        expect(json_response['success']).to be_truthy
        expect(json_response['recovery_codes']).to match_array(%w[119135e5a3ebce8e 34bd7b74adbc8861])
      end
    end

    context 'when two-factor is not enabled' do
      it 'returns an error message' do
        allow_any_instance_of(User).to receive(:two_factor_enabled?).and_return(false)

        subject

        expect(json_response['success']).to be_falsey
        expect(json_response['recovery_codes']).to be_nil
      end
    end
  end

  describe 'POST /internal/personal_access_token' do
    let(:key_id) { key.id }

    subject do
      post api('/internal/personal_access_token'),
        params: { key_id: key_id },
        headers: gitlab_shell_internal_api_request_header
    end

    it_behaves_like 'actor key validations'

    context 'key is a deploy key' do
      let(:key_id) { create(:deploy_key).id }

      it 'returns an error message' do
        subject

        expect(json_response['success']).to be_falsey
        expect(json_response['message']).to eq('Deploy keys cannot be used to create personal access tokens')
      end
    end

    it 'returns an error message when given an non existent user' do
      post api('/internal/personal_access_token'),
        params: { user_id: 0 },
        headers: gitlab_shell_internal_api_request_header

      expect(json_response['success']).to be_falsey
      expect(json_response['message']).to eq("Could not find the given user")
    end

    it 'returns an error message when no name parameter is received' do
      post api('/internal/personal_access_token'),
        params: { key_id: key.id },
        headers: gitlab_shell_internal_api_request_header

      expect(json_response['success']).to be_falsey
      expect(json_response['message']).to eq("No token name specified")
    end

    it 'returns an error message when no scopes parameter is received' do
      post api('/internal/personal_access_token'),
        params: { key_id: key.id, name: 'newtoken' },
        headers: gitlab_shell_internal_api_request_header

      expect(json_response['success']).to be_falsey
      expect(json_response['message']).to eq("No token scopes specified")
    end

    it 'returns an error message when expires_at contains an invalid date' do
      post api('/internal/personal_access_token'),
        params: {
          key_id: key.id,
          name: 'newtoken',
          scopes: ['api'],
          expires_at: 'invalid-date'
        },
        headers: gitlab_shell_internal_api_request_header

      expect(json_response['success']).to be_falsey
      expect(json_response['message']).to eq("Invalid token expiry date: 'invalid-date'")
    end

    it 'returns an error message when it receives an invalid scope' do
      post api('/internal/personal_access_token'),
        params: {
          key_id: key.id,
          name: 'newtoken',
          scopes: %w[read_api badscope read_repository]
        },
        headers: gitlab_shell_internal_api_request_header

      expect(json_response['success']).to be_falsey
      expect(json_response['message']).to match(/\AInvalid scope: 'badscope'. Valid scopes are: /)
    end

    it 'returns a token with expiry when it receives a valid expires_at parameter' do
      freeze_time do
        post api('/internal/personal_access_token'),
          params: {
            key_id: key.id,
            name: 'newtoken',
            scopes: %w[read_api read_repository],
            expires_at: max_pat_access_token_lifetime
          },
          headers: gitlab_shell_internal_api_request_header

        expect(json_response['success']).to be_truthy
        expect(json_response['token']).to start_with(PersonalAccessToken.token_prefix)
        expect(json_response['scopes']).to match_array(%w[read_api read_repository])
        expect(json_response['expires_at']).to eq(max_pat_access_token_lifetime.iso8601)
      end
    end

    it 'returns token with expiry as PersonalAccessToken::MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS' do
      freeze_time do
        post api('/internal/personal_access_token'),
          params: {
            key_id: key.id,
            name: 'newtoken',
            scopes: %w[read_api read_repository],
            expires_at: 365.days.from_now
          },
          headers: gitlab_shell_internal_api_request_header

        expect(json_response['success']).to be_truthy
        expect(json_response['token']).to start_with(PersonalAccessToken.token_prefix)
        expect(json_response['scopes']).to match_array(%w[read_api read_repository])
        expect(json_response['expires_at']).to eq(max_pat_access_token_lifetime.iso8601)
      end
    end
  end

  describe "POST /internal/lfs_authenticate" do
    before do
      stub_lfs_setting(enabled: true)
      project.add_developer(user)
    end

    context 'user key' do
      it 'returns the correct information about the key' do
        lfs_auth_key(key.id, project)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['username']).to eq(user.username)
        expect(json_response['repository_http_path']).to eq(project.http_url_to_repo)
        expect(json_response['expires_in']).to eq(Gitlab::LfsToken::DEFAULT_EXPIRE_TIME)
        expect(Gitlab::LfsToken.new(key, project).token_valid?(json_response['lfs_token'])).to be_truthy
      end

      it 'returns the correct information about the user' do
        lfs_auth_user(user.id, project)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['username']).to eq(user.username)
        expect(json_response['repository_http_path']).to eq(project.http_url_to_repo)
        expect(Gitlab::LfsToken.new(user, project).token_valid?(json_response['lfs_token'])).to be_truthy
      end

      it 'returns a 404 when no key or user is provided' do
        lfs_auth_project(project)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns a 404 when the wrong key is provided' do
        lfs_auth_key(non_existing_record_id, project)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns a 404 when the wrong user is provided' do
        lfs_auth_user(non_existing_record_id, project)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns a 404 when LFS is disabled on the project' do
        project.update!(lfs_enabled: false)
        lfs_auth_user(user.id, project)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'other repository types' do
        it 'returns the correct information for a project wiki' do
          wiki = create(:project_wiki, project: project)
          lfs_auth_user(user.id, wiki)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['username']).to eq(user.username)
          expect(json_response['repository_http_path']).to eq(wiki.http_url_to_repo)
          expect(json_response['expires_in']).to eq(Gitlab::LfsToken::DEFAULT_EXPIRE_TIME)
          expect(Gitlab::LfsToken.new(user, wiki).token_valid?(json_response['lfs_token'])).to be_truthy
        end

        it 'returns a 404 when the container does not support LFS' do
          snippet = create(:project_snippet)
          lfs_auth_user(user.id, snippet)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'deploy key' do
      let(:key) { create(:deploy_key) }

      it 'returns the correct information about the key' do
        lfs_auth_key(key.id, project)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['username']).to eq("lfs+deploy-key-#{key.id}")
        expect(json_response['repository_http_path']).to eq(project.http_url_to_repo)
        expect(Gitlab::LfsToken.new(key, project).token_valid?(json_response['lfs_token'])).to be_truthy
      end
    end
  end

  describe "GET /internal/discover" do
    it "finds a user by key id" do
      get(api("/internal/discover"), params: { key_id: key.id }, headers: gitlab_shell_internal_api_request_header)

      expect(response).to have_gitlab_http_status(:ok)

      expect(json_response['name']).to eq(user.name)
    end

    context 'when signing key is passed' do
      it 'does not authenticate user' do
        key.signing!

        get(api("/internal/discover"), params: { key_id: key.id }, headers: gitlab_shell_internal_api_request_header)

        expect(json_response).to be_nil
      end
    end

    context 'when auth-only key is passed' do
      it 'authenticates user' do
        key.auth!

        get(api("/internal/discover"), params: { key_id: key.id }, headers: gitlab_shell_internal_api_request_header)

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['name']).to eq(user.name)
      end
    end

    it "finds a user by username" do
      get(api("/internal/discover"), params: { username: user.username }, headers: gitlab_shell_internal_api_request_header)

      expect(response).to have_gitlab_http_status(:ok)

      expect(json_response['name']).to eq(user.name)
    end

    it 'responds successfully when a user is not found' do
      get(api('/internal/discover'), params: { username: 'noone' }, headers: gitlab_shell_internal_api_request_header)

      expect(response).to have_gitlab_http_status(:ok)

      expect(response.body).to eq('null')
    end

    it 'response successfully when passing invalid params' do
      get(api('/internal/discover'), params: { nothing: 'to find a user' }, headers: gitlab_shell_internal_api_request_header)

      expect(response).to have_gitlab_http_status(:ok)

      expect(response.body).to eq('null')
    end
  end

  describe "GET /internal/authorized_keys" do
    context "using an existing key" do
      it "finds the key" do
        get(api('/internal/authorized_keys'), params: { key: key.key.split[1] }, headers: gitlab_shell_internal_api_request_header)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(key.id)
        expect(json_response['key'].split[1]).to eq(key.key.split[1])
      end

      context 'when signing key is passed' do
        it 'does not return the key' do
          key.signing!

          get(api('/internal/authorized_keys'), params: { key: key.key.split[1] }, headers: gitlab_shell_internal_api_request_header)

          expect(response).to have_gitlab_http_status(:not_found)

          expect(json_response['id']).to be_nil
        end
      end

      context 'when auth-only key is passed' do
        it 'authenticates user' do
          key.auth!

          get(api('/internal/authorized_keys'), params: { key: key.key.split[1] }, headers: gitlab_shell_internal_api_request_header)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq(key.id)
          expect(json_response['key'].split[1]).to eq(key.key.split[1])
        end
      end

      it 'exposes the comment of the key as a simple identifier of username + hostname' do
        get(api('/internal/authorized_keys'), params: { key: key.key.split[1] }, headers: gitlab_shell_internal_api_request_header)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['key']).to include("#{key.user_name} (#{Gitlab.config.gitlab.host})")
      end
    end

    it "returns 404 with a partial key" do
      get(api('/internal/authorized_keys'), params: { key: key.key.split[1][0...-3] }, headers: gitlab_shell_internal_api_request_header)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns 404 with an not valid base64 string" do
      get(api('/internal/authorized_keys'), params: { key: "whatever!" }, headers: gitlab_shell_internal_api_request_header)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "POST /internal/allowed", :clean_gitlab_redis_shared_state, :clean_gitlab_redis_rate_limiting do
    shared_examples 'rate limited request' do
      let(:action) { 'git-upload-pack' }
      let(:actor) { key }
      let(:rate_limiter) { double(:rate_limiter, ip: "127.0.0.1", trusted_ip?: false) }

      before do
        allow(::Gitlab::Auth::IpRateLimiter).to receive(:new).with("127.0.0.1").and_return(rate_limiter)
      end

      it 'is throttled by rate limiter' do
        allow(::Gitlab::ApplicationRateLimiter).to receive(:threshold).and_return(1)

        expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:gitlab_shell_operation, scope: [action, project.full_path, actor]).twice.and_call_original
        expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:gitlab_shell_operation, scope: [action, project.full_path, "127.0.0.1"]).and_call_original

        request

        expect(response).to have_gitlab_http_status(:ok)

        request

        expect(response).to have_gitlab_http_status(:too_many_requests)
        expect(json_response['message']['error']).to eq('This endpoint has been requested too many times. Try again later.')
      end

      it 'is not throttled by rate limiter' do
        expect(::Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)

        subject
      end

      context 'when the IP is in a trusted range' do
        let(:rate_limiter) { double(:rate_limiter, ip: "127.0.0.1", trusted_ip?: true) }

        it 'is not throttled by rate limiter' do
          expect(::Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)

          subject
        end
      end
    end

    context "access granted" do
      let(:relative_path) { nil }
      let(:env) { {} }

      around do |example|
        freeze_time { example.run }
      end

      before do
        project.add_developer(user)
      end

      shared_context 'with env passed as a JSON' do
        let(:obj_dir_relative) { './objects' }
        let(:alt_obj_dirs_relative) { ['./alt-objects-1', './alt-objects-2'] }
        let(:env) do
          {
            GIT_OBJECT_DIRECTORY_RELATIVE: obj_dir_relative,
            GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE: alt_obj_dirs_relative
          }
        end
      end

      shared_examples 'sets hook env' do
        include_context 'with env passed as a JSON'

        it 'sets env in RequestStore' do
          expect(Gitlab::Git::HookEnv).to receive(:set).with(gl_repository, relative_path, env.stringify_keys)

          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      shared_examples 'sets hook env and routes to primary' do
        include_context 'with env passed as a JSON'

        let(:interceptor) do
          Class.new(::GRPC::ClientInterceptor) do
            def route_to_primary_received?
              @route_to_primary_count.to_i > 0
            end

            def request_response(request:, call:, method:, metadata:) # rubocop:disable Lint/UnusedMethodArgument
              @route_to_primary_count ||= 0
              @route_to_primary_count += 1 if metadata['gitaly-route-repository-accessor-policy'] == 'primary-only'

              yield
            end
          end.new
        end

        before do
          Gitlab::GitalyClient.clear_stubs!
          allow(::Gitlab::GitalyClient).to receive(:interceptors).and_return([interceptor])
        end

        after do
          Gitlab::GitalyClient.clear_stubs!
        end

        it 'sets env in RequestStore and routes gRPC messages to primary', :request_store do
          expect(Gitlab::Git::HookEnv).to receive(:set).with(gl_repository, relative_path, env.stringify_keys).and_call_original

          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(interceptor.route_to_primary_received?).to be_truthy
        end
      end

      context "git push with project.wiki" do
        let(:relative_path) { project.wiki.repository.relative_path }

        subject { push(key, project.wiki, env: env.to_json) }

        it 'responds with success' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response["status"]).to be_truthy
          expect(json_response["gl_project_path"]).to eq(project.wiki.full_path)
          expect(json_response["gl_repository"]).to eq("wiki-#{project.id}")
          expect(json_response["gl_project_id"]).to eq(project.id)
          expect(json_response["gl_root_namespace_id"]).to eq(project.root_namespace.id)
          expect(json_response["gl_key_type"]).to eq("key")
          expect(json_response["gl_key_id"]).to eq(key.id)
        end

        # Wiki repositories don't invoke any Gitaly RPCs to check for changes, so we can only test for the
        # hook environment being set.
        it_behaves_like 'sets hook env' do
          let(:gl_repository) { Gitlab::GlRepository::WIKI.identifier_for_container(project.wiki) }
        end
      end

      context "git pull with project.wiki" do
        it 'responds with success' do
          pull(key, project.wiki)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response["status"]).to be_truthy
          expect(json_response["gl_project_path"]).to eq(project.wiki.full_path)
          expect(json_response["gl_repository"]).to eq("wiki-#{project.id}")
          expect(json_response["gl_project_id"]).to eq(project.id)
          expect(json_response["gl_root_namespace_id"]).to eq(project.root_namespace.id)
        end
      end

      shared_examples 'snippet success' do
        it 'responds with success' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['status']).to be_truthy
        end
      end

      context 'git push with personal snippet' do
        # relative_path is sent from Gitaly to Rails when invoking internal API. In production it points to the
        # transaction's snapshot repository. As Gitaly is stubbed out from the invocation loop, there is no transaction
        # and thus no snapshot repository. Pass the original relative path.
        let(:relative_path) { personal_snippet.repository.relative_path }

        subject { push(key, personal_snippet, env: env.to_json, changes: snippet_changes) }

        it 'responds with success' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response["status"]).to be_truthy
          expect(json_response["gl_project_path"]).to eq(personal_snippet.repository.full_path)
          expect(json_response["gl_repository"]).to eq("snippet-#{personal_snippet.id}")
          expect(json_response["gl_project_id"]).to be_nil
          expect(json_response["gl_root_namespace_id"]).to be_nil
        end

        it_behaves_like 'sets hook env and routes to primary' do
          let(:gl_repository) { Gitlab::GlRepository::SNIPPET.identifier_for_container(personal_snippet) }
        end
      end

      context 'git pull with personal snippet' do
        subject { pull(key, personal_snippet) }

        it 'responds with success' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response["status"]).to be_truthy
          expect(json_response["gl_project_path"]).to eq(personal_snippet.repository.full_path)
          expect(json_response["gl_repository"]).to eq("snippet-#{personal_snippet.id}")
          expect(json_response["gl_project_id"]).to be_nil
          expect(json_response["gl_root_namespace_id"]).to be_nil
          expect(user.reload.last_activity_on).to eql(Date.today)
        end
      end

      context 'git push with project snippet' do
        # relative_path is sent from Gitaly to Rails when invoking internal API. In production it points to the
        # transaction's snapshot repository. As Gitaly is stubbed out from the invocation loop, there is no transaction
        # and thus no snapshot repository. Pass the original relative path.
        let(:relative_path) { project_snippet.repository.relative_path }

        subject { push(key, project_snippet, env: env.to_json, changes: snippet_changes) }

        it 'responds with success' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response["status"]).to be_truthy
          expect(json_response["gl_project_path"]).to eq(project_snippet.repository.full_path)
          expect(json_response["gl_repository"]).to eq("snippet-#{project_snippet.id}")
          expect(json_response["gl_project_id"]).to eq(project.id)
          expect(json_response["gl_root_namespace_id"]).to eq(project.root_namespace.id)
        end

        it_behaves_like 'sets hook env and routes to primary' do
          let(:gl_repository) { Gitlab::GlRepository::SNIPPET.identifier_for_container(project_snippet) }
        end
      end

      context 'git pull with project snippet' do
        it 'responds with success' do
          pull(key, project_snippet)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response["status"]).to be_truthy
          expect(json_response["gl_project_path"]).to eq(project_snippet.repository.full_path)
          expect(json_response["gl_repository"]).to eq("snippet-#{project_snippet.id}")
          expect(json_response["gl_project_id"]).to eq(project.id)
          expect(json_response["gl_root_namespace_id"]).to eq(project.root_namespace.id)
          expect(user.reload.last_activity_on).to eql(Date.today)
        end
      end

      context "git pull" do
        context "with a feature flag enabled globally" do
          before do
            stub_feature_flags(gitaly_mep_mep: true)
          end

          it "has the correct payload" do
            pull(key, project)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response["status"]).to be_truthy
            expect(json_response["gl_repository"]).to eq("project-#{project.id}")
            expect(json_response["gl_project_path"]).to eq(project.full_path)
            expect(json_response["gl_project_id"]).to eq(project.id)
            expect(json_response["gl_root_namespace_id"]).to eq(project.root_namespace.id)
            expect(json_response["gitaly"]).not_to be_nil
            expect(json_response["gitaly"]["repository"]).not_to be_nil
            expect(json_response["gitaly"]["repository"]["storage_name"]).to eq(project.repository.gitaly_repository.storage_name)
            expect(json_response["gitaly"]["repository"]["relative_path"]).to eq(project.repository.gitaly_repository.relative_path)
            expect(json_response["gitaly"]["address"]).to eq(Gitlab::GitalyClient.address(project.repository_storage))
            expect(json_response["gitaly"]["token"]).to eq(Gitlab::GitalyClient.token(project.repository_storage))
            expect(json_response["gitaly"]["features"]).to eq('gitaly-feature-mep-mep' => 'true')
            expect(user.reload.last_activity_on).to eql(Date.today)
          end

          it_behaves_like 'rate limited request' do
            def request
              pull(key, project)
            end
          end

          context 'when user_id is passed' do
            it_behaves_like 'rate limited request' do
              let(:actor) { user }

              def request
                post(
                  api("/internal/allowed"),
                  params: {
                    user_id: user.id,
                    project: full_path_for(project),
                    gl_repository: gl_repository_for(project),
                    action: 'git-upload-pack',
                    protocol: 'ssh'
                  },
                  headers: gitlab_shell_internal_api_request_header
                )
              end

              it "updates user's activity data" do
                expect(::Users::ActivityService).to receive(:new).with(author: user, namespace: project.namespace, project: project)

                request
              end
            end
          end
        end

        context "with a feature flag enabled for a project" do
          before do
            stub_feature_flags(gitaly_mep_mep: project)
          end

          it "has the flag set to true for that project" do
            pull(key, project)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response["gl_repository"]).to eq("project-#{project.id}")
            expect(json_response["gitaly"]["features"]).to eq('gitaly-feature-mep-mep' => 'true')
          end

          it "has the flag set to false for other projects" do
            other_project = create(:project, :public, :repository)

            pull(key, other_project)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response["gl_repository"]).to eq("project-#{other_project.id}")
            expect(json_response["gitaly"]["features"]).to eq('gitaly-feature-mep-mep' => 'false')
          end
        end

        context 'with audit event' do
          it 'does not send a git streaming audit event' do
            expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

            pull(key, project)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response["need_audit"]).to be_falsy
          end
        end
      end

      context "git push" do
        context 'project as namespace/project' do
          it do
            push(key, project)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response["status"]).to be_truthy
            expect(json_response["gl_repository"]).to eq("project-#{project.id}")
            expect(json_response["gl_project_path"]).to eq(project.full_path)
            expect(json_response["gl_project_id"]).to eq(project.id)
            expect(json_response["gl_root_namespace_id"]).to eq(project.root_namespace.id)
            expect(json_response["gl_key_type"]).to eq("key")
            expect(json_response["gl_key_id"]).to eq(key.id)
            expect(json_response["need_audit"]).to be_falsy
            expect(json_response["gitaly"]).not_to be_nil
            expect(json_response["gitaly"]["repository"]).not_to be_nil
            expect(json_response["gitaly"]["repository"]["storage_name"]).to eq(project.repository.gitaly_repository.storage_name)
            expect(json_response["gitaly"]["repository"]["relative_path"]).to eq(project.repository.gitaly_repository.relative_path)
            expect(json_response["gitaly"]["address"]).to eq(Gitlab::GitalyClient.address(project.repository_storage))
            expect(json_response["gitaly"]["token"]).to eq(Gitlab::GitalyClient.token(project.repository_storage))
          end

          it_behaves_like 'rate limited request' do
            let(:action) { 'git-receive-pack' }

            def request
              push(key, project)
            end
          end
        end

        context 'when receive_max_input_size has been updated' do
          before do
            allow(Gitlab::CurrentSettings).to receive(:receive_max_input_size) { 1 }
          end

          it 'returns maxInputSize and partial clone git config' do
            push(key, project)

            expect(json_response["git_config_options"]).to be_present
            expect(json_response["git_config_options"]).to include("receive.maxInputSize=1048576")
            expect(json_response["git_config_options"]).to include("uploadpack.allowFilter=true")
            expect(json_response["git_config_options"]).to include("uploadpack.allowAnySHA1InWant=true")
          end
        end

        context 'when receive_max_input_size is empty' do
          before do
            allow(Gitlab::CurrentSettings).to receive(:receive_max_input_size) { nil }
          end

          it 'returns partial clone git config' do
            push(key, project)

            expect(json_response["git_config_options"]).to be_present
            expect(json_response["git_config_options"]).to include("uploadpack.allowFilter=true")
            expect(json_response["git_config_options"]).to include("uploadpack.allowAnySHA1InWant=true")
          end
        end
      end

      context 'with Project' do
        it_behaves_like 'storing arguments in the application context for the API' do
          let(:expected_params) { { user: key.user.username, project: project.full_path, caller_id: "POST /api/:version/internal/allowed" } }

          subject { push(key, project) }
        end
      end

      context 'with PersonalSnippet' do
        it_behaves_like 'storing arguments in the application context for the API' do
          let(:expected_params) { { user: key.user.username, caller_id: "POST /api/:version/internal/allowed" } }

          subject { push(key, personal_snippet) }
        end
      end

      context 'with ProjectSnippet' do
        it_behaves_like 'storing arguments in the application context for the API' do
          let(:expected_params) { { user: key.user.username, project: project_snippet.project.full_path, caller_id: "POST /api/:version/internal/allowed" } }

          subject { push(key, project_snippet) }
        end
      end
    end

    context "access denied" do
      before do
        project.add_guest(user)
      end

      context "git pull" do
        it do
          pull(key, project)

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(json_response["status"]).to be_falsey
          expect(user.reload.last_activity_on).to be_nil
        end
      end

      context "git push" do
        it do
          push(key, project)

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(json_response["status"]).to be_falsey
          expect(user.reload.last_activity_on).to be_nil
        end
      end
    end

    context 'with a pending membership' do
      before_all do
        create(:project_member, :awaiting, :developer, source: project, user: user)
      end

      it 'returns not found for git pull' do
        pull(key, project)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response["status"]).to be_falsey
        expect(user.reload.last_activity_on).to be_nil
      end

      it 'returns not found for git push' do
        push(key, project)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response["status"]).to be_falsey
        expect(user.reload.last_activity_on).to be_nil
      end
    end

    context "custom action" do
      let(:payload) do
        {
          'action' => 'geo_proxy_to_primary',
          'data' => {
            'api_endpoints' => %w[geo/proxy_git_ssh/info_refs_receive_pack geo/proxy_git_ssh/receive_pack],
            'gl_username' => 'testuser',
            'primary_repo' => 'http://localhost:3000/testuser/repo.git'
          }
        }
      end

      let(:console_messages) { ['informational message'] }
      let(:custom_action_result) { Gitlab::GitAccessResult::CustomAction.new(payload, console_messages) }

      before do
        project.add_guest(user)

        expect_next_instance_of(Gitlab::GitAccess,
          key,
          project,
          'ssh',
          {
            authentication_abilities: [:read_project, :download_code, :push_code],
            repository_path: "#{project.full_path}.git",
            redirected_path: nil,
            push_options: nil,
            gitaly_context: nil
          }
        ) do |access_checker|
          expect(access_checker).to receive(:check).with(
            'git-receive-pack',
            'd14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/master'
          ).and_return(custom_action_result)
        end
      end

      context "git push" do
        it do
          push(key, project)

          expect(response).to have_gitlab_http_status(:multiple_choices)
          expect(json_response['status']).to be_truthy
          expect(json_response['payload']).to eql(payload)
          expect(json_response['gl_console_messages']).to eql(console_messages)
        end
      end
    end

    context "console message" do
      before do
        project.add_developer(user)
      end

      context 'git pull' do
        context 'with a key that has expired' do
          let(:key) { create(:key, :expired, user: user) }

          it 'includes the `key expired` message in the response and fails' do
            pull(key, project)

            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(json_response['message']).to eq('Your SSH key has expired.')
          end
        end

        context 'with a key that will expire in the next 7 days' do
          let(:key) { create(:key, user: user, expires_at: 2.days.from_now) }

          it 'includes the `key expiring soon` message in the response' do
            pull(key, project)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['gl_console_messages']).to eq(['INFO: Your SSH key is expiring soon. Please generate a new key.'])
          end
        end

        context 'with a key that has no expiry' do
          it 'does not include any message in the response' do
            pull(key, project)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['gl_console_messages']).to eq([])
          end
        end
      end
    end

    context "blocked user" do
      let(:personal_project) { create(:project, namespace: user.namespace) }

      before do
        user.block
      end

      context "git pull" do
        it do
          pull(key, personal_project)

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(json_response["status"]).to be_falsey
          expect(user.reload.last_activity_on).to be_nil
        end
      end

      context "git push" do
        it do
          push(key, personal_project)

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(json_response["status"]).to be_falsey
          expect(user.reload.last_activity_on).to be_nil
        end
      end
    end

    context 'request times out' do
      context 'git push' do
        it 'responds with a gateway timeout' do
          personal_project = create(:project, namespace: user.namespace)

          expect_next_instance_of(Gitlab::GitAccess) do |access|
            expect(access).to receive(:check).and_raise(Gitlab::GitAccess::TimeoutError, "Foo")
          end
          push(key, personal_project)

          expect(response).to have_gitlab_http_status(:service_unavailable)
          expect(json_response['status']).to be_falsey
          expect(json_response['message']).to eq("Foo")
          expect(user.reload.last_activity_on).to be_nil
        end
      end
    end

    context 'when result is not ::Gitlab::GitAccessResult::Success or ::Gitlab::GitAccessResult::CustomAction' do
      it 'responds with 500' do
        personal_project = create(:project, namespace: user.namespace)

        allow_next_instance_of(Gitlab::GitAccess) do |access|
          allow(access).to receive(:check).and_return(nil)
        end
        push(key, personal_project)

        expect(response).to have_gitlab_http_status(:internal_server_error)
        expect(json_response['status']).to be_falsey
        expect(json_response['message']).to eq(::API::Helpers::InternalHelpers::UNKNOWN_CHECK_RESULT_ERROR)
      end
    end

    context "archived project" do
      before do
        project.add_developer(user)
        ::Projects::UpdateService.new(project, user, archived: true).execute
      end

      context "git pull" do
        it do
          pull(key, project)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response["status"]).to be_truthy
        end
      end

      context "git push" do
        it do
          push(key, project)

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(json_response["status"]).to be_falsey
        end
      end
    end

    context "deploy key" do
      let(:key) { create(:deploy_key) }

      context "added to project" do
        before do
          key.projects << project
        end

        it do
          archive(key, project)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response["status"]).to be_truthy
          expect(json_response["gitaly"]).not_to be_nil
          expect(json_response["gl_key_type"]).to eq("deploy_key")
          expect(json_response["gl_key_id"]).to eq(key.id)
          expect(json_response["gitaly"]["repository"]).not_to be_nil
          expect(json_response["gitaly"]["repository"]["storage_name"]).to eq(project.repository.gitaly_repository.storage_name)
          expect(json_response["gitaly"]["repository"]["relative_path"]).to eq(project.repository.gitaly_repository.relative_path)
          expect(json_response["gitaly"]["address"]).to eq(Gitlab::GitalyClient.address(project.repository_storage))
          expect(json_response["gitaly"]["token"]).to eq(Gitlab::GitalyClient.token(project.repository_storage))
        end

        it_behaves_like 'rate limited request' do
          let(:action) { 'git-upload-archive' }

          def request
            archive(key, project)
          end
        end
      end

      context "not added to project" do
        it do
          archive(key, project)

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response["status"]).to be_falsey
        end
      end
    end

    context 'project does not exist' do
      let_it_be(:destroy_project) { create(:project, :repository, :wiki_repo) }

      context 'git pull' do
        it 'returns a 200 response with status: false' do
          destroy_project.destroy!

          pull(key, destroy_project)

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response["status"]).to be_falsey
        end

        it 'returns a 200 response when using a project path that does not exist' do
          post(
            api("/internal/allowed"),
            params: {
              key_id: key.id,
              project: 'project/does-not-exist.git',
              action: 'git-upload-pack',
              protocol: 'ssh'
            },
            headers: gitlab_shell_internal_api_request_header
          )

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response["status"]).to be_falsey
        end
      end

      context 'git push' do
        before do
          allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(120)
        end

        subject { push_with_path(key, full_path: path, changes: '_any') }

        context 'from a user/group namespace' do
          let!(:path) { "#{user.namespace.path}/notexist.git" }

          it 'creates the project' do
            expect do
              subject
            end.to change { Project.count }.by(1)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['status']).to be_truthy
          end
        end

        context 'when push path is invalid' do
          let!(:path) { "#{user.namespace.path}/cannot_end_with_dot." }

          it 'returns an error' do
            expect { subject }.not_to change { Project.count }

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(json_response['message']).to include('Could not create project')
            expect(json_response['status']).to be_falsey
          end
        end

        context 'from the personal snippet path' do
          let!(:path) { 'snippets/notexist.git' }

          it 'does not create snippet' do
            expect do
              subject
            end.not_to change { Snippet.count }

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'from a project path' do
          context 'from an non existent project path' do
            let!(:path) { "#{user.namespace.path}/notexist/snippets/notexist.git" }

            it 'does not create project' do
              expect do
                subject
              end.not_to change { Project.count }

              expect(response).to have_gitlab_http_status(:not_found)
            end

            it 'does not create snippet' do
              expect do
                subject
              end.not_to change { Snippet.count }

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end

          context 'from an existent project path' do
            let!(:path) { "#{project.full_path}/notexist/snippets/notexist.git" }

            it 'does not create snippet' do
              expect do
                subject
              end.not_to change { Snippet.count }

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end
      end
    end

    context 'user does not exist' do
      it do
        pull(double('key', id: 0), project)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response["status"]).to be_falsey
      end
    end

    context 'ssh access has been disabled' do
      before do
        stub_application_setting(enabled_git_access_protocol: 'http')
      end

      it 'rejects the SSH push' do
        push(key, project)

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(json_response['status']).to be_falsey
        expect(json_response['message']).to eq 'Git access over SSH is not allowed'
      end

      it 'rejects the SSH pull' do
        pull(key, project)

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(json_response['status']).to be_falsey
        expect(json_response['message']).to eq 'Git access over SSH is not allowed'
      end
    end

    context 'http access has been disabled' do
      before do
        stub_application_setting(enabled_git_access_protocol: 'ssh')
      end

      it 'rejects the HTTP push' do
        push(key, project, 'http')

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(json_response['status']).to be_falsey
        expect(json_response['message']).to eq 'Git access over HTTP is not allowed'
      end

      it 'rejects the HTTP pull' do
        pull(key, project, 'http')

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(json_response['status']).to be_falsey
        expect(json_response['message']).to eq 'Git access over HTTP is not allowed'
      end
    end

    context 'web actions are always allowed' do
      it 'allows WEB push' do
        stub_application_setting(enabled_git_access_protocol: 'ssh')
        project.add_developer(user)
        push(key, project, 'web')

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['status']).to be_truthy
      end
    end

    context 'the project path was changed' do
      let(:project) { create(:project, :repository, :legacy_storage) }
      let!(:repository) { project.repository }

      before do
        project.add_developer(user)
        project.path = 'new_path'
        project.save!
      end

      it 'rejects the push' do
        push(key, project)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['status']).to be_falsy
      end

      it 'rejects the SSH pull' do
        pull(key, project)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['status']).to be_falsy
      end
    end

    context 'for design repositories' do
      let(:gl_repository) { Gitlab::GlRepository::DESIGN.identifier_for_container(project) }

      it 'does not allow access' do
        post(api('/internal/allowed'),
          params: {
            key_id: key.id,
            project: project.full_path,
            gl_repository: gl_repository,
            protocol: 'ssh'
          }, headers: gitlab_shell_internal_api_request_header
        )

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'admin mode' do
      shared_examples 'pushes succeed for ssh and http' do
        it 'accepts the SSH push' do
          push(key, project)

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'accepts the HTTP push' do
          push(key, project, 'http')

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      shared_examples 'pushes fail for ssh and http' do
        it 'rejects the SSH push' do
          push(key, project)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'rejects the HTTP push' do
          push(key, project, 'http')

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'application setting :admin_mode is enabled' do
        context 'with an admin user' do
          let(:user) { create(:admin) }

          context 'is member of the project' do
            before do
              project.add_developer(user)
            end

            it_behaves_like 'pushes succeed for ssh and http'
          end

          context 'is not member of the project' do
            it_behaves_like 'pushes succeed for ssh and http'
          end
        end

        context 'with a regular user' do
          context 'is member of the project' do
            before do
              project.add_developer(user)
            end

            it_behaves_like 'pushes succeed for ssh and http'
          end

          context 'is not member of the project' do
            it_behaves_like 'pushes fail for ssh and http'
          end
        end
      end

      context 'application setting :admin_mode is disabled' do
        before do
          stub_application_setting(admin_mode: false)
        end

        context 'with an admin user' do
          let(:user) { create(:admin) }

          context 'is member of the project' do
            before do
              project.add_developer(user)
            end

            it_behaves_like 'pushes succeed for ssh and http'
          end

          context 'is not member of the project' do
            it_behaves_like 'pushes succeed for ssh and http'
          end
        end

        context 'with a regular user' do
          context 'is member of the project' do
            before do
              project.add_developer(user)
            end

            it_behaves_like 'pushes succeed for ssh and http'
          end

          context 'is not member of the project' do
            it_behaves_like 'pushes fail for ssh and http'
          end
        end
      end
    end
  end

  describe 'POST /internal/post_receive', :clean_gitlab_redis_shared_state do
    let(:identifier) { 'key-123' }
    let(:branch_name) { 'feature' }
    let(:push_options) { ['ci.skip', 'another push option'] }

    let(:valid_params) do
      {
        gl_repository: gl_repository,
        identifier: identifier,
        changes: changes,
        push_options: push_options
      }
    end

    let(:changes) do
      "#{Gitlab::Git::SHA1_BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/#{branch_name}"
    end

    subject { post api('/internal/post_receive'), params: valid_params, headers: gitlab_shell_internal_api_request_header }

    before do
      project.add_developer(user)
      allow_any_instance_of(Gitlab::Identifier).to receive(:identify).and_return(user)
    end

    shared_examples 'runs post-receive hooks' do
      let(:gl_repository) { container.repository.gl_repository }
      let(:messages) { [] }

      it 'executes PostReceiveService' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({
          'messages' => messages,
          'reference_counter_decreased' => true
        })
      end

      it 'tries to notify that the container has moved' do
        expect(Gitlab::Checks::ContainerMoved).to receive(:fetch_message).with(user, container.repository)

        subject
      end

      it_behaves_like 'storing arguments in the application context for the API' do
        let(:expected_params) { expected_context }
      end
    end

    context 'with Project' do
      it_behaves_like 'runs post-receive hooks' do
        let(:container) { project }
        let(:expected_context) { { user: user.username, project: project.full_path } }

        let(:messages) do
          [
            {
              'message' => <<~MESSAGE.strip,
                To create a merge request for #{branch_name}, visit:
                  http://#{Gitlab.config.gitlab.host}/#{project.full_path}/-/merge_requests/new?merge_request%5Bsource_branch%5D=#{branch_name}
              MESSAGE
              'type' => 'basic'
            }
          ]
        end
      end
    end

    context 'with PersonalSnippet' do
      it_behaves_like 'runs post-receive hooks' do
        let(:container) { personal_snippet }
        let(:expected_context) { { user: key.user.username } }
      end
    end

    context 'with ProjectSnippet' do
      it_behaves_like 'runs post-receive hooks' do
        let(:container) { project_snippet }
        let(:expected_context) { { user: key.user.username, project: project_snippet.project.full_path } }
      end
    end

    context 'with ProjectWiki' do
      it_behaves_like 'runs post-receive hooks' do
        let(:container) { project.wiki }
        let(:expected_context) { { user: key.user.username, project: project.full_path } }
      end
    end

    context 'with an orphaned write deploy key' do
      it 'does not try to notify that project moved' do
        allow_any_instance_of(Gitlab::Identifier).to receive(:identify).and_return(nil)

        expect(Gitlab::Checks::ContainerMoved).not_to receive(:fetch_message)

        subject

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when container is nil' do
      let(:gl_repository) { 'project-foo' }

      it 'does not try to notify that project moved' do
        allow(Gitlab::GlRepository).to receive(:parse).and_return([nil, nil, Gitlab::GlRepository::PROJECT])

        expect(Gitlab::Checks::ContainerMoved).not_to receive(:fetch_message)

        subject

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'POST /internal/pre_receive' do
    let(:valid_params) do
      { gl_repository: gl_repository, user_id: user.id }
    end

    it 'decreases the reference counter and returns the result' do
      expect(Gitlab::ReferenceCounter).to receive(:new).with(gl_repository)
        .and_return(reference_counter)
      expect(reference_counter).to receive(:increase).and_return(true)

      post api("/internal/pre_receive"), params: valid_params, headers: gitlab_shell_internal_api_request_header

      expect(json_response['reference_counter_increased']).to be(true)
    end

    it 'sticks to the primary' do
      expect(User.sticking).to receive(:find_caught_up_replica).with(:user, user.id)

      post api("/internal/pre_receive"), params: valid_params, headers: gitlab_shell_internal_api_request_header
    end
  end

  describe 'POST /internal/two_factor_config' do
    let(:key_id) { key.id }

    before do
      stub_feature_flags(two_factor_for_cli: true)
    end

    subject do
      post api('/internal/two_factor_config'),
        params: { key_id: key_id },
        headers: gitlab_shell_internal_api_request_header
    end

    it_behaves_like 'actor key validations'

    context 'when the key is a deploy key' do
      let(:key) { create(:deploy_key) }

      it 'does not required two factor' do
        subject

        expect(json_response['success']).to be_truthy
        expect(json_response['two_factor_required']).to be_falsey
      end
    end

    context 'when two-factor is enabled' do
      it 'returns user two factor config' do
        allow_any_instance_of(User).to receive(:two_factor_enabled?).and_return(true)

        subject

        expect(json_response['success']).to be_truthy
        expect(json_response['two_factor_required']).to be_truthy
      end
    end

    context 'when two-factor is not enabled' do
      it 'returns an error message' do
        allow_any_instance_of(User).to receive(:two_factor_enabled?).and_return(false)

        subject

        expect(json_response['success']).to be_truthy
        expect(json_response['two_factor_required']).to be_falsey
      end
    end

    context 'two_factor_for_cli feature is disabled' do
      before do
        stub_feature_flags(two_factor_for_cli: false)
      end

      context 'when two-factor is enabled for the user' do
        it 'returns user two factor config' do
          allow_any_instance_of(User).to receive(:two_factor_enabled?).and_return(true)

          subject

          expect(json_response['success']).to be_falsey
        end
      end
    end
  end

  describe 'POST /internal/two_factor_manual_otp_check' do
    let(:key_id) { key.id }
    let(:otp) { '123456' }

    subject do
      post api('/internal/two_factor_manual_otp_check'),
        params: {
          secret_token: secret_token,
          key_id: key_id,
          otp_attempt: otp
        },
        headers: gitlab_shell_internal_api_request_header
    end

    it 'is not available' do
      subject

      expect(json_response['success']).to be_falsey
      expect(json_response['message']).to eq 'Feature is not available'
    end
  end

  describe 'POST /internal/two_factor_push_otp_check' do
    let(:key_id) { key.id }
    let(:otp) { '123456' }

    subject do
      post api('/internal/two_factor_push_otp_check'),
        params: {
          secret_token: secret_token,
          key_id: key_id,
          otp_attempt: otp
        },
        headers: gitlab_shell_internal_api_request_header
    end

    it 'is not available' do
      subject

      expect(json_response['success']).to be_falsey
      expect(json_response['message']).to eq 'Feature is not available'
    end
  end

  describe 'POST /internal/two_factor_manual_otp_check' do
    let(:key_id) { key.id }
    let(:otp) { '123456' }

    subject do
      post api('/internal/two_factor_manual_otp_check'),
        params: {
          secret_token: secret_token,
          key_id: key_id,
          otp_attempt: otp
        },
        headers: gitlab_shell_internal_api_request_header
    end

    it 'is not available' do
      subject

      expect(json_response['success']).to be_falsey
    end
  end

  describe 'POST /internal/two_factor_push_otp_check' do
    let(:key_id) { key.id }
    let(:otp) { '123456' }

    subject do
      post api('/internal/two_factor_push_otp_check'),
        params: {
          secret_token: secret_token,
          key_id: key_id,
          otp_attempt: otp
        },
        headers: gitlab_shell_internal_api_request_header
    end

    it 'is not available' do
      subject

      expect(json_response['success']).to be_falsey
    end
  end

  def lfs_auth_project(project)
    post(
      api("/internal/lfs_authenticate"),
      params: { project: project.full_path },
      headers: gitlab_shell_internal_api_request_header
    )
  end

  def lfs_auth_key(key_id, project)
    post(
      api("/internal/lfs_authenticate"),
      params: { key_id: key_id, project: project.full_path },
      headers: gitlab_shell_internal_api_request_header
    )
  end

  def lfs_auth_user(user_id, project)
    post(
      api("/internal/lfs_authenticate"),
      params: { user_id: user_id, project: project.full_path },
      headers: gitlab_shell_internal_api_request_header
    )
  end
end
