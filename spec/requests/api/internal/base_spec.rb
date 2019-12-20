# frozen_string_literal: true

require 'spec_helper'

describe API::Internal::Base do
  set(:user) { create(:user) }
  let(:key) { create(:key, user: user) }
  set(:project) { create(:project, :repository, :wiki_repo) }
  let(:secret_token) { Gitlab::Shell.secret_token }
  let(:gl_repository) { "project-#{project.id}" }
  let(:reference_counter) { double('ReferenceCounter') }

  describe "GET /internal/check" do
    it do
      expect_any_instance_of(Redis).to receive(:ping).and_return('PONG')

      get api("/internal/check"), params: { secret_token: secret_token }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['api_version']).to eq(API::API.version)
      expect(json_response['redis']).to be(true)
    end

    it 'returns false for field `redis` when redis is unavailable' do
      expect_any_instance_of(Redis).to receive(:ping).and_raise(Errno::ENOENT)

      get api("/internal/check"), params: { secret_token: secret_token }

      expect(json_response['redis']).to be(false)
    end

    context 'authenticating' do
      it 'authenticates using a header' do
        get api("/internal/check"),
            headers: { API::Helpers::GITLAB_SHARED_SECRET_HEADER => Base64.encode64(secret_token) }

        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns 401 when no credentials provided' do
        get(api("/internal/check"))

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'GET /internal/two_factor_recovery_codes' do
    it 'returns an error message when the key does not exist' do
      post api('/internal/two_factor_recovery_codes'),
           params: {
             secret_token: secret_token,
             key_id: 12345
           }

      expect(json_response['success']).to be_falsey
      expect(json_response['message']).to eq('Could not find the given key')
    end

    it 'returns an error message when the key is a deploy key' do
      deploy_key = create(:deploy_key)

      post api('/internal/two_factor_recovery_codes'),
           params: {
             secret_token: secret_token,
             key_id: deploy_key.id
           }

      expect(json_response['success']).to be_falsey
      expect(json_response['message']).to eq('Deploy keys cannot be used to retrieve recovery codes')
    end

    it 'returns an error message when the user does not exist' do
      key_without_user = create(:key, user: nil)

      post api('/internal/two_factor_recovery_codes'),
           params: {
             secret_token: secret_token,
             key_id: key_without_user.id
           }

      expect(json_response['success']).to be_falsey
      expect(json_response['message']).to eq('Could not find a user for the given key')
      expect(json_response['recovery_codes']).to be_nil
    end

    context 'when two-factor is enabled' do
      it 'returns new recovery codes when the user exists' do
        allow_any_instance_of(User).to receive(:two_factor_enabled?).and_return(true)
        allow_any_instance_of(User)
          .to receive(:generate_otp_backup_codes!).and_return(%w(119135e5a3ebce8e 34bd7b74adbc8861))

        post api('/internal/two_factor_recovery_codes'),
             params: {
               secret_token: secret_token,
               key_id: key.id
             }

        expect(json_response['success']).to be_truthy
        expect(json_response['recovery_codes']).to match_array(%w(119135e5a3ebce8e 34bd7b74adbc8861))
      end
    end

    context 'when two-factor is not enabled' do
      it 'returns an error message' do
        allow_any_instance_of(User).to receive(:two_factor_enabled?).and_return(false)

        post api('/internal/two_factor_recovery_codes'),
             params: {
               secret_token: secret_token,
               key_id: key.id
             }

        expect(json_response['success']).to be_falsey
        expect(json_response['recovery_codes']).to be_nil
      end
    end
  end

  describe "POST /internal/lfs_authenticate" do
    before do
      project.add_developer(user)
    end

    context 'user key' do
      it 'returns the correct information about the key' do
        lfs_auth_key(key.id, project)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['username']).to eq(user.username)
        expect(json_response['repository_http_path']).to eq(project.http_url_to_repo)
        expect(json_response['expires_in']).to eq(Gitlab::LfsToken::DEFAULT_EXPIRE_TIME)
        expect(Gitlab::LfsToken.new(key).token_valid?(json_response['lfs_token'])).to be_truthy
      end

      it 'returns the correct information about the user' do
        lfs_auth_user(user.id, project)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['username']).to eq(user.username)
        expect(json_response['repository_http_path']).to eq(project.http_url_to_repo)
        expect(Gitlab::LfsToken.new(user).token_valid?(json_response['lfs_token'])).to be_truthy
      end

      it 'returns a 404 when no key or user is provided' do
        lfs_auth_project(project)

        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns a 404 when the wrong key is provided' do
        lfs_auth_key(key.id + 12345, project)

        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns a 404 when the wrong user is provided' do
        lfs_auth_user(user.id + 12345, project)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'deploy key' do
      let(:key) { create(:deploy_key) }

      it 'returns the correct information about the key' do
        lfs_auth_key(key.id, project)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['username']).to eq("lfs+deploy-key-#{key.id}")
        expect(json_response['repository_http_path']).to eq(project.http_url_to_repo)
        expect(Gitlab::LfsToken.new(key).token_valid?(json_response['lfs_token'])).to be_truthy
      end
    end
  end

  describe "GET /internal/discover" do
    it "finds a user by key id" do
      get(api("/internal/discover"), params: { key_id: key.id, secret_token: secret_token })

      expect(response).to have_gitlab_http_status(200)

      expect(json_response['name']).to eq(user.name)
    end

    it "finds a user by username" do
      get(api("/internal/discover"), params: { username: user.username, secret_token: secret_token })

      expect(response).to have_gitlab_http_status(200)

      expect(json_response['name']).to eq(user.name)
    end

    it 'responds successfully when a user is not found' do
      get(api('/internal/discover'), params: { username: 'noone', secret_token: secret_token })

      expect(response).to have_gitlab_http_status(200)

      expect(response.body).to eq('null')
    end

    it 'response successfully when passing invalid params' do
      get(api('/internal/discover'), params: { nothing: 'to find a user', secret_token: secret_token })

      expect(response).to have_gitlab_http_status(200)

      expect(response.body).to eq('null')
    end
  end

  describe "GET /internal/authorized_keys" do
    context "using an existing key's fingerprint" do
      it "finds the key" do
        get(api('/internal/authorized_keys'), params: { fingerprint: key.fingerprint, secret_token: secret_token })

        expect(response.status).to eq(200)
        expect(json_response["key"]).to eq(key.key)
      end
    end

    context "non existing key's fingerprint" do
      it "returns 404" do
        get(api('/internal/authorized_keys'), params: { fingerprint: "no:t-:va:li:d0", secret_token: secret_token })

        expect(response.status).to eq(404)
      end
    end

    context "using a partial fingerprint" do
      it "returns 404" do
        get(api('/internal/authorized_keys'), params: { fingerprint: "#{key.fingerprint[0..5]}%", secret_token: secret_token })

        expect(response.status).to eq(404)
      end
    end

    context "sending the key" do
      it "finds the key" do
        get(api('/internal/authorized_keys'), params: { key: key.key.split[1], secret_token: secret_token })

        expect(response.status).to eq(200)
        expect(json_response["key"]).to eq(key.key)
      end

      it "returns 404 with a partial key" do
        get(api('/internal/authorized_keys'), params: { key: key.key.split[1][0...-3], secret_token: secret_token })

        expect(response.status).to eq(404)
      end

      it "returns 404 with an not valid base64 string" do
        get(api('/internal/authorized_keys'), params: { key: "whatever!", secret_token: secret_token })

        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST /internal/allowed", :clean_gitlab_redis_shared_state do
    context "access granted" do
      around do |example|
        Timecop.freeze { example.run }
      end

      before do
        project.add_developer(user)
      end

      context 'with env passed as a JSON' do
        let(:gl_repository) { Gitlab::GlRepository::WIKI.identifier_for_subject(project) }

        it 'sets env in RequestStore' do
          obj_dir_relative = './objects'
          alt_obj_dirs_relative = ['./alt-objects-1', './alt-objects-2']

          expect(Gitlab::Git::HookEnv).to receive(:set).with(gl_repository, {
            'GIT_OBJECT_DIRECTORY_RELATIVE' => obj_dir_relative,
            'GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE' => alt_obj_dirs_relative
          })

          push(key, project.wiki, env: {
            GIT_OBJECT_DIRECTORY_RELATIVE: obj_dir_relative,
            GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE: alt_obj_dirs_relative
          }.to_json)

          expect(response).to have_gitlab_http_status(200)
        end
      end

      context "git push with project.wiki" do
        it 'responds with success' do
          push(key, project.wiki)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response["status"]).to be_truthy
          expect(json_response["gl_project_path"]).to eq(project.wiki.full_path)
          expect(json_response["gl_repository"]).to eq("wiki-#{project.id}")
          expect(user.reload.last_activity_on).to be_nil
        end
      end

      context "git pull with project.wiki" do
        it 'responds with success' do
          pull(key, project.wiki)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response["status"]).to be_truthy
          expect(json_response["gl_project_path"]).to eq(project.wiki.full_path)
          expect(json_response["gl_repository"]).to eq("wiki-#{project.id}")
          expect(user.reload.last_activity_on).to eql(Date.today)
        end
      end

      context "git pull" do
        it "has the correct payload" do
          pull(key, project)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response["status"]).to be_truthy
          expect(json_response["gl_repository"]).to eq("project-#{project.id}")
          expect(json_response["gl_project_path"]).to eq(project.full_path)
          expect(json_response["gitaly"]).not_to be_nil
          expect(json_response["gitaly"]["repository"]).not_to be_nil
          expect(json_response["gitaly"]["repository"]["storage_name"]).to eq(project.repository.gitaly_repository.storage_name)
          expect(json_response["gitaly"]["repository"]["relative_path"]).to eq(project.repository.gitaly_repository.relative_path)
          expect(json_response["gitaly"]["address"]).to eq(Gitlab::GitalyClient.address(project.repository_storage))
          expect(json_response["gitaly"]["token"]).to eq(Gitlab::GitalyClient.token(project.repository_storage))
          expect(json_response["gitaly"]["features"]).to eq('gitaly-feature-inforef-uploadpack-cache' => 'true', 'gitaly-feature-get-tag-messages-go' => 'true', 'gitaly-feature-filter-shas-with-signatures-go' => 'true')
          expect(user.reload.last_activity_on).to eql(Date.today)
        end
      end

      context "git push" do
        context 'project as namespace/project' do
          it do
            push(key, project)

            expect(response).to have_gitlab_http_status(200)
            expect(json_response["status"]).to be_truthy
            expect(json_response["gl_repository"]).to eq("project-#{project.id}")
            expect(json_response["gl_project_path"]).to eq(project.full_path)
            expect(json_response["gitaly"]).not_to be_nil
            expect(json_response["gitaly"]["repository"]).not_to be_nil
            expect(json_response["gitaly"]["repository"]["storage_name"]).to eq(project.repository.gitaly_repository.storage_name)
            expect(json_response["gitaly"]["repository"]["relative_path"]).to eq(project.repository.gitaly_repository.relative_path)
            expect(json_response["gitaly"]["address"]).to eq(Gitlab::GitalyClient.address(project.repository_storage))
            expect(json_response["gitaly"]["token"]).to eq(Gitlab::GitalyClient.token(project.repository_storage))
            expect(json_response["gitaly"]["features"]).to eq('gitaly-feature-inforef-uploadpack-cache' => 'true', 'gitaly-feature-get-tag-messages-go' => 'true', 'gitaly-feature-filter-shas-with-signatures-go' => 'true')
            expect(user.reload.last_activity_on).to be_nil
          end
        end

        context 'when receive_max_input_size has been updated' do
          before do
            allow(Gitlab::CurrentSettings).to receive(:receive_max_input_size) { 1 }
          end

          it 'returns custom git config' do
            push(key, project)

            expect(json_response["git_config_options"]).to be_present
            expect(json_response["git_config_options"]).to include("uploadpack.allowFilter=true")
            expect(json_response["git_config_options"]).to include("uploadpack.allowAnySHA1InWant=true")
          end

          context 'when gitaly_upload_pack_filter feature flag is disabled' do
            before do
              stub_feature_flags(gitaly_upload_pack_filter: { enabled: false, thing: project })
            end

            it 'does not include allowFilter and allowAnySha1InWant in the git config options' do
              push(key, project)

              expect(json_response["git_config_options"]).to be_present
              expect(json_response["git_config_options"]).not_to include("uploadpack.allowFilter=true")
              expect(json_response["git_config_options"]).not_to include("uploadpack.allowAnySHA1InWant=true")
            end
          end
        end

        context 'when receive_max_input_size is empty' do
          it 'returns an empty git config' do
            allow(Gitlab::CurrentSettings).to receive(:receive_max_input_size) { nil }

            push(key, project)

            expect(json_response["git_config_options"]).to be_empty
          end
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

          expect(response).to have_gitlab_http_status(401)
          expect(json_response["status"]).to be_falsey
          expect(user.reload.last_activity_on).to be_nil
        end
      end

      context "git push" do
        it do
          push(key, project)

          expect(response).to have_gitlab_http_status(401)
          expect(json_response["status"]).to be_falsey
          expect(user.reload.last_activity_on).to be_nil
        end
      end
    end

    context "custom action" do
      let(:access_checker) { double(Gitlab::GitAccess) }
      let(:payload) do
        {
          'action' => 'geo_proxy_to_primary',
          'data' => {
            'api_endpoints' => %w{geo/proxy_git_push_ssh/info_refs geo/proxy_git_push_ssh/push},
            'gl_username' => 'testuser',
            'primary_repo' => 'http://localhost:3000/testuser/repo.git'
          }
        }
      end
      let(:console_messages) { ['informational message'] }
      let(:custom_action_result) { Gitlab::GitAccessResult::CustomAction.new(payload, console_messages) }

      before do
        project.add_guest(user)
        expect(Gitlab::GitAccess).to receive(:new).with(
          key,
          project,
          'ssh',
          {
            authentication_abilities: [:read_project, :download_code, :push_code],
            namespace_path: project.namespace.path,
            project_path: project.path,
            redirected_path: nil
          }
        ).and_return(access_checker)
        expect(access_checker).to receive(:check).with(
          'git-receive-pack',
          'd14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/master'
        ).and_return(custom_action_result)
      end

      context "git push" do
        it do
          push(key, project)

          expect(response).to have_gitlab_http_status(300)
          expect(json_response['status']).to be_truthy
          expect(json_response['payload']).to eql(payload)
          expect(json_response['gl_console_messages']).to eql(console_messages)
          expect(user.reload.last_activity_on).to be_nil
        end
      end
    end

    context "console message" do
      before do
        project.add_developer(user)
      end

      context "git pull" do
        context "with no console message" do
          it "has the correct payload" do
            pull(key, project)

            expect(response).to have_gitlab_http_status(200)
            expect(json_response['gl_console_messages']).to eq([])
          end
        end

        context "with a console message" do
          let(:console_messages) { ['message for the console'] }

          it "has the correct payload" do
            expect_next_instance_of(Gitlab::GitAccess) do |access|
              expect(access).to receive(:check_for_console_messages)
                                  .with('git-upload-pack')
                                  .and_return(console_messages)
            end

            pull(key, project)

            expect(response).to have_gitlab_http_status(200)
            expect(json_response['gl_console_messages']).to eq(console_messages)
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

          expect(response).to have_gitlab_http_status(401)
          expect(json_response["status"]).to be_falsey
          expect(user.reload.last_activity_on).to be_nil
        end
      end

      context "git push" do
        it do
          push(key, personal_project)

          expect(response).to have_gitlab_http_status(401)
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

          expect(response).to have_gitlab_http_status(503)
          expect(json_response['status']).to be_falsey
          expect(json_response['message']).to eq("Foo")
          expect(user.reload.last_activity_on).to be_nil
        end
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

          expect(response).to have_gitlab_http_status(200)
          expect(json_response["status"]).to be_truthy
        end
      end

      context "git push" do
        it do
          push(key, project)

          expect(response).to have_gitlab_http_status(401)
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

          expect(response).to have_gitlab_http_status(200)
          expect(json_response["status"]).to be_truthy
          expect(json_response["gitaly"]).not_to be_nil
          expect(json_response["gitaly"]["repository"]).not_to be_nil
          expect(json_response["gitaly"]["repository"]["storage_name"]).to eq(project.repository.gitaly_repository.storage_name)
          expect(json_response["gitaly"]["repository"]["relative_path"]).to eq(project.repository.gitaly_repository.relative_path)
          expect(json_response["gitaly"]["address"]).to eq(Gitlab::GitalyClient.address(project.repository_storage))
          expect(json_response["gitaly"]["token"]).to eq(Gitlab::GitalyClient.token(project.repository_storage))
          expect(json_response["gitaly"]["features"]).to eq('gitaly-feature-inforef-uploadpack-cache' => 'true', 'gitaly-feature-get-tag-messages-go' => 'true', 'gitaly-feature-filter-shas-with-signatures-go' => 'true')
        end
      end

      context "not added to project" do
        it do
          archive(key, project)

          expect(response).to have_gitlab_http_status(404)
          expect(json_response["status"]).to be_falsey
        end
      end
    end

    context 'project does not exist' do
      it 'returns a 200 response with status: false' do
        project.destroy

        pull(key, project)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response["status"]).to be_falsey
      end

      it 'returns a 200 response when using a project path that does not exist' do
        post(
          api("/internal/allowed"),
          params: {
            key_id: key.id,
            project: 'project/does-not-exist.git',
            action: 'git-upload-pack',
            secret_token: secret_token,
            protocol: 'ssh'
          }
        )

        expect(response).to have_gitlab_http_status(404)
        expect(json_response["status"]).to be_falsey
      end
    end

    context 'user does not exist' do
      it do
        pull(OpenStruct.new(id: 0), project)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response["status"]).to be_falsey
      end
    end

    context 'ssh access has been disabled' do
      before do
        stub_application_setting(enabled_git_access_protocol: 'http')
      end

      it 'rejects the SSH push' do
        push(key, project)

        expect(response.status).to eq(401)
        expect(json_response['status']).to be_falsey
        expect(json_response['message']).to eq 'Git access over SSH is not allowed'
      end

      it 'rejects the SSH pull' do
        pull(key, project)

        expect(response.status).to eq(401)
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

        expect(response.status).to eq(401)
        expect(json_response['status']).to be_falsey
        expect(json_response['message']).to eq 'Git access over HTTP is not allowed'
      end

      it 'rejects the HTTP pull' do
        pull(key, project, 'http')

        expect(response.status).to eq(401)
        expect(json_response['status']).to be_falsey
        expect(json_response['message']).to eq 'Git access over HTTP is not allowed'
      end
    end

    context 'web actions are always allowed' do
      it 'allows WEB push' do
        stub_application_setting(enabled_git_access_protocol: 'ssh')
        project.add_developer(user)
        push(key, project, 'web')

        expect(response.status).to eq(200)
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

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['status']).to be_falsy
      end

      it 'rejects the SSH pull' do
        pull(key, project)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['status']).to be_falsy
      end
    end
  end

  # TODO: Uncomment when the end-point is reenabled
  # describe 'POST /notify_post_receive' do
  #   let(:valid_params) do
  #     { project: project.repository.path, secret_token: secret_token }
  #   end
  #
  #   let(:valid_wiki_params) do
  #     { project: project.wiki.repository.path, secret_token: secret_token }
  #   end
  #
  #   before do
  #     allow(Gitlab.config.gitaly).to receive(:enabled).and_return(true)
  #   end
  #
  #   it "calls the Gitaly client with the project's repository" do
  #     expect(Gitlab::GitalyClient::NotificationService).
  #       to receive(:new).with(gitlab_git_repository_with(path: project.repository.path)).
  #       and_call_original
  #     expect_any_instance_of(Gitlab::GitalyClient::NotificationService).
  #       to receive(:post_receive)
  #
  #     post api("/internal/notify_post_receive"), valid_params
  #
  #     expect(response).to have_gitlab_http_status(200)
  #   end
  #
  #   it "calls the Gitaly client with the wiki's repository if it's a wiki" do
  #     expect(Gitlab::GitalyClient::NotificationService).
  #       to receive(:new).with(gitlab_git_repository_with(path: project.wiki.repository.path)).
  #       and_call_original
  #     expect_any_instance_of(Gitlab::GitalyClient::NotificationService).
  #       to receive(:post_receive)
  #
  #     post api("/internal/notify_post_receive"), valid_wiki_params
  #
  #     expect(response).to have_gitlab_http_status(200)
  #   end
  #
  #   it "returns 500 if the gitaly call fails" do
  #     expect_any_instance_of(Gitlab::GitalyClient::NotificationService).
  #       to receive(:post_receive).and_raise(GRPC::Unavailable)
  #
  #     post api("/internal/notify_post_receive"), valid_params
  #
  #     expect(response).to have_gitlab_http_status(500)
  #   end
  #
  #   context 'with a gl_repository parameter' do
  #     let(:valid_params) do
  #       { gl_repository: "project-#{project.id}", secret_token: secret_token }
  #     end
  #
  #     let(:valid_wiki_params) do
  #       { gl_repository: "wiki-#{project.id}", secret_token: secret_token }
  #     end
  #
  #     it "calls the Gitaly client with the project's repository" do
  #       expect(Gitlab::GitalyClient::NotificationService).
  #         to receive(:new).with(gitlab_git_repository_with(path: project.repository.path)).
  #         and_call_original
  #       expect_any_instance_of(Gitlab::GitalyClient::NotificationService).
  #         to receive(:post_receive)
  #
  #       post api("/internal/notify_post_receive"), valid_params
  #
  #       expect(response).to have_gitlab_http_status(200)
  #     end
  #
  #     it "calls the Gitaly client with the wiki's repository if it's a wiki" do
  #       expect(Gitlab::GitalyClient::NotificationService).
  #         to receive(:new).with(gitlab_git_repository_with(path: project.wiki.repository.path)).
  #         and_call_original
  #       expect_any_instance_of(Gitlab::GitalyClient::NotificationService).
  #         to receive(:post_receive)
  #
  #       post api("/internal/notify_post_receive"), valid_wiki_params
  #
  #       expect(response).to have_gitlab_http_status(200)
  #     end
  #   end
  # end

  describe 'POST /internal/post_receive', :clean_gitlab_redis_shared_state do
    let(:identifier) { 'key-123' }

    let(:valid_params) do
      {
        gl_repository: gl_repository,
        secret_token: secret_token,
        identifier: identifier,
        changes: changes,
        push_options: push_options
      }
    end

    let(:branch_name) { 'feature' }

    let(:changes) do
      "#{Gitlab::Git::BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/#{branch_name}"
    end

    let(:push_options) do
      ['ci.skip',
       'another push option']
    end

    before do
      project.add_developer(user)
      allow_any_instance_of(Gitlab::Identifier).to receive(:identify).and_return(user)
    end

    it 'enqueues a PostReceive worker job' do
      expect(PostReceive).to receive(:perform_async)
        .with(gl_repository, identifier, changes, { ci: { skip: true } })

      post api('/internal/post_receive'), params: valid_params
    end

    it 'decreases the reference counter and returns the result' do
      expect(Gitlab::ReferenceCounter).to receive(:new).with(gl_repository)
        .and_return(reference_counter)
      expect(reference_counter).to receive(:decrease).and_return(true)

      post api('/internal/post_receive'), params: valid_params

      expect(json_response['reference_counter_decreased']).to be(true)
    end

    it 'returns link to create new merge request' do
      post api('/internal/post_receive'), params: valid_params

      message = <<~MESSAGE.strip
        To create a merge request for #{branch_name}, visit:
          http://#{Gitlab.config.gitlab.host}/#{project.full_path}/merge_requests/new?merge_request%5Bsource_branch%5D=#{branch_name}
      MESSAGE

      expect(json_response['messages']).to include(build_basic_message(message))
    end

    it 'returns the link to an existing merge request when it exists' do
      merge_request = create(:merge_request, source_project: project, source_branch: branch_name, target_branch: 'master')

      post api('/internal/post_receive'), params: valid_params

      message = <<~MESSAGE.strip
        View merge request for feature:
          #{project_merge_request_url(project, merge_request)}
      MESSAGE

      expect(json_response['messages']).to include(build_basic_message(message))
    end

    it 'returns no merge request messages if printing_merge_request_link_enabled is false' do
      project.update!(printing_merge_request_link_enabled: false)

      post api('/internal/post_receive'), params: valid_params

      expect(json_response['messages']).to be_blank
    end

    it 'does not invoke MergeRequests::PushOptionsHandlerService' do
      expect(MergeRequests::PushOptionsHandlerService).not_to receive(:new)

      post api('/internal/post_receive'), params: valid_params
    end

    context 'when there are merge_request push options' do
      before do
        valid_params[:push_options] = ['merge_request.create']
      end

      it 'invokes MergeRequests::PushOptionsHandlerService' do
        expect(MergeRequests::PushOptionsHandlerService).to receive(:new)

        post api('/internal/post_receive'), params: valid_params
      end

      it 'creates a new merge request' do
        expect do
          Sidekiq::Testing.fake! do
            post api('/internal/post_receive'), params: valid_params
          end
        end.to change { MergeRequest.count }.by(1)
      end

      it 'links to the newly created merge request' do
        post api('/internal/post_receive'), params: valid_params

        message = <<~MESSAGE.strip
          View merge request for #{branch_name}:
            http://#{Gitlab.config.gitlab.host}/#{project.full_path}/merge_requests/1
        MESSAGE

        expect(json_response['messages']).to include(build_basic_message(message))
      end

      it 'adds errors on the service instance to warnings' do
        expect_any_instance_of(
          MergeRequests::PushOptionsHandlerService
        ).to receive(:errors).at_least(:once).and_return(['my error'])

        post api('/internal/post_receive'), params: valid_params

        message = "WARNINGS:\nError encountered with push options 'merge_request.create': my error"
        expect(json_response['messages']).to include(build_alert_message(message))
      end

      it 'adds ActiveRecord errors on invalid MergeRequest records to warnings' do
        invalid_merge_request = MergeRequest.new
        invalid_merge_request.errors.add(:base, 'my error')

        expect_any_instance_of(
          MergeRequests::CreateService
        ).to receive(:execute).and_return(invalid_merge_request)

        post api('/internal/post_receive'), params: valid_params

        message = "WARNINGS:\nError encountered with push options 'merge_request.create': my error"
        expect(json_response['messages']).to include(build_alert_message(message))
      end
    end

    context 'broadcast message exists' do
      let!(:broadcast_message) { create(:broadcast_message, starts_at: 1.day.ago, ends_at: 1.day.from_now ) }

      it 'outputs a broadcast message' do
        post api('/internal/post_receive'), params: valid_params

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['messages']).to include(build_alert_message(broadcast_message.message))
      end
    end

    context 'broadcast message does not exist' do
      it 'does not output a broadcast message' do
        post api('/internal/post_receive'), params: valid_params

        expect(response).to have_gitlab_http_status(200)
        expect(has_alert_messages?(json_response['messages'])).to be_falsey
      end
    end

    context 'nil broadcast message' do
      it 'does not output a broadcast message' do
        allow(BroadcastMessage).to receive(:current).and_return(nil)

        post api('/internal/post_receive'), params: valid_params

        expect(response).to have_gitlab_http_status(200)
        expect(has_alert_messages?(json_response['messages'])).to be_falsey
      end
    end

    context 'with a redirected data' do
      it 'returns redirected message on the response' do
        project_moved = Gitlab::Checks::ProjectMoved.new(project, user, 'http', 'foo/baz')
        project_moved.add_message

        post api('/internal/post_receive'), params: valid_params

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['messages']).to include(build_basic_message(project_moved.message))
      end
    end

    context 'with new project data' do
      it 'returns new project message on the response' do
        project_created = Gitlab::Checks::ProjectCreated.new(project, user, 'http')
        project_created.add_message

        post api('/internal/post_receive'), params: valid_params

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['messages']).to include(build_basic_message(project_created.message))
      end
    end

    context 'with an orphaned write deploy key' do
      it 'does not try to notify that project moved' do
        allow_any_instance_of(Gitlab::Identifier).to receive(:identify).and_return(nil)

        post api('/internal/post_receive'), params: valid_params

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end

  describe 'POST /internal/pre_receive' do
    let(:valid_params) do
      { gl_repository: gl_repository, secret_token: secret_token }
    end

    it 'decreases the reference counter and returns the result' do
      expect(Gitlab::ReferenceCounter).to receive(:new).with(gl_repository)
        .and_return(reference_counter)
      expect(reference_counter).to receive(:increase).and_return(true)

      post api("/internal/pre_receive"), params: valid_params

      expect(json_response['reference_counter_increased']).to be(true)
    end
  end

  def gl_repository_for(project_or_wiki)
    case project_or_wiki
    when ProjectWiki
      Gitlab::GlRepository::WIKI.identifier_for_subject(project_or_wiki.project)
    when Project
      Gitlab::GlRepository::PROJECT.identifier_for_subject(project_or_wiki)
    else
      nil
    end
  end

  def pull(key, project, protocol = 'ssh')
    post(
      api("/internal/allowed"),
      params: {
        key_id: key.id,
        project: project.full_path,
        gl_repository: gl_repository_for(project),
        action: 'git-upload-pack',
        secret_token: secret_token,
        protocol: protocol
      }
    )
  end

  def push(key, project, protocol = 'ssh', env: nil)
    params = {
      changes: 'd14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/master',
      key_id: key.id,
      project: project.full_path,
      gl_repository: gl_repository_for(project),
      action: 'git-receive-pack',
      secret_token: secret_token,
      protocol: protocol,
      env: env
    }

    post(
      api("/internal/allowed"),
      params: params
    )
  end

  def archive(key, project)
    post(
      api("/internal/allowed"),
      params: {
        ref: 'master',
        key_id: key.id,
        project: project.full_path,
        gl_repository: gl_repository_for(project),
        action: 'git-upload-archive',
        secret_token: secret_token,
        protocol: 'ssh'
      }
    )
  end

  def lfs_auth_project(project)
    post(
      api("/internal/lfs_authenticate"),
      params: {
        secret_token: secret_token,
        project: project.full_path
      }
    )
  end

  def lfs_auth_key(key_id, project)
    post(
      api("/internal/lfs_authenticate"),
      params: {
        key_id: key_id,
        secret_token: secret_token,
        project: project.full_path
      }
    )
  end

  def lfs_auth_user(user_id, project)
    post(
      api("/internal/lfs_authenticate"),
      params: {
        user_id: user_id,
        secret_token: secret_token,
        project: project.full_path
      }
    )
  end

  def build_alert_message(message)
    { 'type' => 'alert', 'message' => message }
  end

  def build_basic_message(message)
    { 'type' => 'basic', 'message' => message }
  end

  def has_alert_messages?(messages)
    messages.any? do |message|
      message['type'] == 'alert'
    end
  end
end
