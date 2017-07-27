require 'spec_helper'

describe API::Internal do
  let(:user) { create(:user) }
  let(:key) { create(:key, user: user) }
  let(:project) { create(:project, :repository) }
  let(:secret_token) { Gitlab::Shell.secret_token }

  describe "GET /internal/check" do
    it do
      get api("/internal/check"), secret_token: secret_token

      expect(response).to have_http_status(200)
      expect(json_response['api_version']).to eq(API::API.version)
    end
  end

  describe 'GET /internal/broadcast_message' do
    context 'broadcast message exists' do
      let!(:broadcast_message) { create(:broadcast_message, starts_at: 1.day.ago, ends_at: 1.day.from_now ) }

      it 'returns one broadcast message'  do
        get api('/internal/broadcast_message'), secret_token: secret_token

        expect(response).to have_http_status(200)
        expect(json_response['message']).to eq(broadcast_message.message)
      end
    end

    context 'broadcast message does not exist' do
      it 'returns nothing'  do
        get api('/internal/broadcast_message'), secret_token: secret_token

        expect(response).to have_http_status(200)
        expect(json_response).to be_empty
      end
    end

    context 'nil broadcast message' do
      it 'returns nothing' do
        allow(BroadcastMessage).to receive(:current).and_return(nil)

        get api('/internal/broadcast_message'), secret_token: secret_token

        expect(response).to have_http_status(200)
        expect(json_response).to be_empty
      end
    end
  end

  describe 'GET /internal/broadcast_messages' do
    context 'broadcast message(s) exist' do
      let!(:broadcast_message) { create(:broadcast_message, starts_at: 1.day.ago, ends_at: 1.day.from_now ) }

      it 'returns active broadcast message(s)' do
        get api('/internal/broadcast_messages'), secret_token: secret_token

        expect(response).to have_http_status(200)
        expect(json_response[0]['message']).to eq(broadcast_message.message)
      end
    end

    context 'broadcast message does not exist' do
      it 'returns nothing' do
        get api('/internal/broadcast_messages'), secret_token: secret_token

        expect(response).to have_http_status(200)
        expect(json_response).to be_empty
      end
    end
  end

  describe 'GET /internal/two_factor_recovery_codes' do
    it 'returns an error message when the key does not exist' do
      post api('/internal/two_factor_recovery_codes'),
           secret_token: secret_token,
           key_id: 12345

      expect(json_response['success']).to be_falsey
      expect(json_response['message']).to eq('Could not find the given key')
    end

    it 'returns an error message when the key is a deploy key' do
      deploy_key = create(:deploy_key)

      post api('/internal/two_factor_recovery_codes'),
           secret_token: secret_token,
           key_id: deploy_key.id

      expect(json_response['success']).to be_falsey
      expect(json_response['message']).to eq('Deploy keys cannot be used to retrieve recovery codes')
    end

    it 'returns an error message when the user does not exist' do
      key_without_user = create(:key, user: nil)

      post api('/internal/two_factor_recovery_codes'),
           secret_token: secret_token,
           key_id: key_without_user.id

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
             secret_token: secret_token,
             key_id: key.id

        expect(json_response['success']).to be_truthy
        expect(json_response['recovery_codes']).to match_array(%w(119135e5a3ebce8e 34bd7b74adbc8861))
      end
    end

    context 'when two-factor is not enabled' do
      it 'returns an error message' do
        allow_any_instance_of(User).to receive(:two_factor_enabled?).and_return(false)

        post api('/internal/two_factor_recovery_codes'),
             secret_token: secret_token,
             key_id: key.id

        expect(json_response['success']).to be_falsey
        expect(json_response['recovery_codes']).to be_nil
      end
    end
  end

  describe "POST /internal/lfs_authenticate" do
    before do
      project.team << [user, :developer]
    end

    context 'user key' do
      it 'returns the correct information about the key' do
        lfs_auth(key.id, project)

        expect(response).to have_http_status(200)
        expect(json_response['username']).to eq(user.username)
        expect(json_response['lfs_token']).to eq(Gitlab::LfsToken.new(key).token)

        expect(json_response['repository_http_path']).to eq(project.http_url_to_repo)
      end

      it 'returns a 404 when the wrong key is provided' do
        lfs_auth(nil, project)

        expect(response).to have_http_status(404)
      end
    end

    context 'deploy key' do
      let(:key) { create(:deploy_key) }

      it 'returns the correct information about the key' do
        lfs_auth(key.id, project)

        expect(response).to have_http_status(200)
        expect(json_response['username']).to eq("lfs+deploy-key-#{key.id}")
        expect(json_response['lfs_token']).to eq(Gitlab::LfsToken.new(key).token)
        expect(json_response['repository_http_path']).to eq(project.http_url_to_repo)
      end
    end
  end

  describe "GET /internal/discover" do
    it do
      get(api("/internal/discover"), key_id: key.id, secret_token: secret_token)

      expect(response).to have_http_status(200)

      expect(json_response['name']).to eq(user.name)
    end
  end

  describe "GET /internal/authorized_keys" do
    context "unsing an existing key's fingerprint" do
      it "finds the key" do
        get(api('/internal/authorized_keys'), fingerprint: key.fingerprint, secret_token: secret_token)

        expect(response.status).to eq(200)
        expect(json_response["key"]).to eq(key.key)
      end
    end

    context "non existing key's fingerprint" do
      it "returns 404" do
        get(api('/internal/authorized_keys'), fingerprint: "no:t-:va:li:d0", secret_token: secret_token)

        expect(response.status).to eq(404)
      end
    end

    context "using a partial fingerprint" do
      it "returns 404" do
        get(api('/internal/authorized_keys'), fingerprint: "#{key.fingerprint[0..5]}%", secret_token: secret_token)

        expect(response.status).to eq(404)
      end
    end

    context "sending the key" do
      it "finds the key" do
        get(api('/internal/authorized_keys'), key: key.key.split[1], secret_token: secret_token)

        expect(response.status).to eq(200)
        expect(json_response["key"]).to eq(key.key)
      end

      it "returns 404 with a partial key" do
        get(api('/internal/authorized_keys'), key: key.key.split[1][0...-3], secret_token: secret_token)

        expect(response.status).to eq(404)
      end

      it "returns 404 with an not valid base64 string" do
        get(api('/internal/authorized_keys'), key: "whatever!", secret_token: secret_token)

        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST /internal/allowed", :clean_gitlab_redis_shared_state do
    context "access granted" do
      before do
        project.team << [user, :developer]
        Timecop.freeze
      end

      after do
        Timecop.return
      end

      context 'with env passed as a JSON' do
        it 'sets env in RequestStore' do
          expect(Gitlab::Git::Env).to receive(:set).with({
            'GIT_OBJECT_DIRECTORY' => 'foo',
            'GIT_ALTERNATE_OBJECT_DIRECTORIES' => 'bar'
          })

          push(key, project.wiki, env: {
            GIT_OBJECT_DIRECTORY: 'foo',
            GIT_ALTERNATE_OBJECT_DIRECTORIES: 'bar'
          }.to_json)

          expect(response).to have_http_status(200)
        end
      end

      context "git push with project.wiki" do
        it 'responds with success' do
          push(key, project.wiki)

          expect(response).to have_http_status(200)
          expect(json_response["status"]).to be_truthy
          expect(json_response["repository_path"]).to eq(project.wiki.repository.path_to_repo)
          expect(json_response["gl_repository"]).to eq("wiki-#{project.id}")
          expect(user).not_to have_an_activity_record
        end
      end

      context "git pull with project.wiki" do
        it 'responds with success' do
          pull(key, project.wiki)

          expect(response).to have_http_status(200)
          expect(json_response["status"]).to be_truthy
          expect(json_response["repository_path"]).to eq(project.wiki.repository.path_to_repo)
          expect(json_response["gl_repository"]).to eq("wiki-#{project.id}")
          expect(user).to have_an_activity_record
        end
      end

      context "git pull" do
        context "gitaly disabled" do
          it "has the correct payload" do
            allow(Gitlab::GitalyClient).to receive(:feature_enabled?).with(:ssh_upload_pack).and_return(false)
            pull(key, project)

            expect(response).to have_http_status(200)
            expect(json_response["status"]).to be_truthy
            expect(json_response["repository_path"]).to eq(project.repository.path_to_repo)
            expect(json_response["gl_repository"]).to eq("project-#{project.id}")
            expect(json_response["gitaly"]).to be_nil
            expect(user).to have_an_activity_record
          end
        end

        context "gitaly enabled" do
          it "has the correct payload" do
            allow(Gitlab::GitalyClient).to receive(:feature_enabled?).with(:ssh_upload_pack).and_return(true)
            pull(key, project)

            expect(response).to have_http_status(200)
            expect(json_response["status"]).to be_truthy
            expect(json_response["repository_path"]).to eq(project.repository.path_to_repo)
            expect(json_response["gl_repository"]).to eq("project-#{project.id}")
            expect(json_response["gitaly"]).not_to be_nil
            expect(json_response["gitaly"]["repository"]).not_to be_nil
            expect(json_response["gitaly"]["repository"]["storage_name"]).to eq(project.repository.gitaly_repository.storage_name)
            expect(json_response["gitaly"]["repository"]["relative_path"]).to eq(project.repository.gitaly_repository.relative_path)
            expect(json_response["gitaly"]["address"]).to eq(Gitlab::GitalyClient.address(project.repository_storage))
            expect(json_response["gitaly"]["token"]).to eq(Gitlab::GitalyClient.token(project.repository_storage))
            expect(user).to have_an_activity_record
          end
        end
      end

      context "git push" do
        context "gitaly disabled" do
          it "has the correct payload" do
            allow(Gitlab::GitalyClient).to receive(:feature_enabled?).with(:ssh_receive_pack).and_return(false)
            push(key, project)

            expect(response).to have_http_status(200)
            expect(json_response["status"]).to be_truthy
            expect(json_response["repository_path"]).to eq(project.repository.path_to_repo)
            expect(json_response["gl_repository"]).to eq("project-#{project.id}")
            expect(json_response["gitaly"]).to be_nil
            expect(user).not_to have_an_activity_record
          end
        end

        context "gitaly enabled" do
          it "has the correct payload" do
            allow(Gitlab::GitalyClient).to receive(:feature_enabled?).with(:ssh_receive_pack).and_return(true)
            push(key, project)

            expect(response).to have_http_status(200)
            expect(json_response["status"]).to be_truthy
            expect(json_response["repository_path"]).to eq(project.repository.path_to_repo)
            expect(json_response["gl_repository"]).to eq("project-#{project.id}")
            expect(json_response["gitaly"]).not_to be_nil
            expect(json_response["gitaly"]["repository"]).not_to be_nil
            expect(json_response["gitaly"]["repository"]["storage_name"]).to eq(project.repository.gitaly_repository.storage_name)
            expect(json_response["gitaly"]["repository"]["relative_path"]).to eq(project.repository.gitaly_repository.relative_path)
            expect(json_response["gitaly"]["address"]).to eq(Gitlab::GitalyClient.address(project.repository_storage))
            expect(json_response["gitaly"]["token"]).to eq(Gitlab::GitalyClient.token(project.repository_storage))
            expect(user).not_to have_an_activity_record
          end
        end

        context 'project as /namespace/project' do
          it do
            pull(key, project_with_repo_path('/' + project.path_with_namespace))

            expect(response).to have_http_status(200)
            expect(json_response["status"]).to be_truthy
            expect(json_response["repository_path"]).to eq(project.repository.path_to_repo)
            expect(json_response["gl_repository"]).to eq("project-#{project.id}")
          end
        end

        context 'project as namespace/project' do
          it do
            pull(key, project_with_repo_path(project.path_with_namespace))

            expect(response).to have_http_status(200)
            expect(json_response["status"]).to be_truthy
            expect(json_response["repository_path"]).to eq(project.repository.path_to_repo)
            expect(json_response["gl_repository"]).to eq("project-#{project.id}")
          end
        end
      end
    end

    context "access denied" do
      before do
        project.team << [user, :guest]
      end

      context "git pull" do
        it do
          pull(key, project)

          expect(response).to have_http_status(200)
          expect(json_response["status"]).to be_falsey
          expect(user).not_to have_an_activity_record
        end
      end

      context "git push" do
        it do
          push(key, project)

          expect(response).to have_http_status(200)
          expect(json_response["status"]).to be_falsey
          expect(user).not_to have_an_activity_record
        end
      end
    end

    context "blocked user" do
      let(:personal_project) { create(:empty_project, namespace: user.namespace) }

      before do
        user.block
      end

      context "git pull" do
        it do
          pull(key, personal_project)

          expect(response).to have_http_status(200)
          expect(json_response["status"]).to be_falsey
          expect(user).not_to have_an_activity_record
        end
      end

      context "git push" do
        it do
          push(key, personal_project)

          expect(response).to have_http_status(200)
          expect(json_response["status"]).to be_falsey
          expect(user).not_to have_an_activity_record
        end
      end
    end

    context "archived project" do
      before do
        project.team << [user, :developer]
        project.archive!
      end

      context "git pull" do
        it do
          pull(key, project)

          expect(response).to have_http_status(200)
          expect(json_response["status"]).to be_truthy
        end
      end

      context "git push" do
        it do
          push(key, project)

          expect(response).to have_http_status(200)
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

          expect(response).to have_http_status(200)
          expect(json_response["status"]).to be_truthy
        end
      end

      context "not added to project" do
        it do
          archive(key, project)

          expect(response).to have_http_status(200)
          expect(json_response["status"]).to be_falsey
        end
      end
    end

    context 'project does not exist' do
      it do
        pull(key, project_with_repo_path('gitlab/notexist'))

        expect(response).to have_http_status(200)
        expect(json_response["status"]).to be_falsey
      end
    end

    context 'user does not exist' do
      it do
        pull(OpenStruct.new(id: 0), project)

        expect(response).to have_http_status(200)
        expect(json_response["status"]).to be_falsey
      end
    end

    context 'ssh access has been disabled' do
      before do
        stub_application_setting(enabled_git_access_protocol: 'http')
      end

      it 'rejects the SSH push' do
        push(key, project)

        expect(response.status).to eq(200)
        expect(json_response['status']).to be_falsey
        expect(json_response['message']).to eq 'Git access over SSH is not allowed'
      end

      it 'rejects the SSH pull' do
        pull(key, project)

        expect(response.status).to eq(200)
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

        expect(response.status).to eq(200)
        expect(json_response['status']).to be_falsey
        expect(json_response['message']).to eq 'Git access over HTTP is not allowed'
      end

      it 'rejects the HTTP pull' do
        pull(key, project, 'http')

        expect(response.status).to eq(200)
        expect(json_response['status']).to be_falsey
        expect(json_response['message']).to eq 'Git access over HTTP is not allowed'
      end
    end

    context 'web actions are always allowed' do
      it 'allows WEB push' do
        stub_application_setting(enabled_git_access_protocol: 'ssh')
        project.team << [user, :developer]
        push(key, project, 'web')

        expect(response.status).to eq(200)
        expect(json_response['status']).to be_truthy
      end
    end

    context 'the project path was changed' do
      let!(:old_path_to_repo) { project.repository.path_to_repo }
      let!(:old_full_path) { project.full_path }
      let(:project_moved_message) do
        <<-MSG.strip_heredoc
          Project '#{old_full_path}' was moved to '#{project.full_path}'.

          Please update your Git remote and try again:

            git remote set-url origin #{project.ssh_url_to_repo}
        MSG
      end

      before do
        project.team << [user, :developer]
        project.path = 'new_path'
        project.save!
      end

      it 'rejects the push' do
        push_with_path(key, old_path_to_repo)

        expect(response).to have_http_status(200)
        expect(json_response['status']).to be_falsey
        expect(json_response['message']).to eq(project_moved_message)
      end

      it 'rejects the SSH pull' do
        pull_with_path(key, old_path_to_repo)

        expect(response).to have_http_status(200)
        expect(json_response['status']).to be_falsey
        expect(json_response['message']).to eq(project_moved_message)
      end
    end
  end

  describe 'GET /internal/merge_request_urls' do
    let(:repo_name) { "#{project.namespace.name}/#{project.path}" }
    let(:changes) { URI.escape("#{Gitlab::Git::BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/new_branch") }

    before do
      project.team << [user, :developer]
    end

    it 'returns link to create new merge request' do
      get api("/internal/merge_request_urls?project=#{repo_name}&changes=#{changes}"), secret_token: secret_token

      expect(json_response).to match [{
        "branch_name" => "new_branch",
        "url" => "http://#{Gitlab.config.gitlab.host}/#{project.namespace.name}/#{project.path}/merge_requests/new?merge_request%5Bsource_branch%5D=new_branch",
        "new_merge_request" => true
      }]
    end

    it 'returns empty array if printing_merge_request_link_enabled is false' do
      project.update!(printing_merge_request_link_enabled: false)

      get api("/internal/merge_request_urls?project=#{repo_name}&changes=#{changes}"), secret_token: secret_token

      expect(json_response).to eq([])
    end

    context 'with a gl_repository parameter' do
      let(:gl_repository) { "project-#{project.id}" }

      it 'returns link to create new merge request' do
        get api("/internal/merge_request_urls?gl_repository=#{gl_repository}&changes=#{changes}"), secret_token: secret_token

        expect(json_response).to match [{
          "branch_name" => "new_branch",
          "url" => "http://#{Gitlab.config.gitlab.host}/#{project.namespace.name}/#{project.path}/merge_requests/new?merge_request%5Bsource_branch%5D=new_branch",
          "new_merge_request" => true
        }]
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
  #     expect(response).to have_http_status(200)
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
  #     expect(response).to have_http_status(200)
  #   end
  #
  #   it "returns 500 if the gitaly call fails" do
  #     expect_any_instance_of(Gitlab::GitalyClient::NotificationService).
  #       to receive(:post_receive).and_raise(GRPC::Unavailable)
  #
  #     post api("/internal/notify_post_receive"), valid_params
  #
  #     expect(response).to have_http_status(500)
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
  #       expect(response).to have_http_status(200)
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
  #       expect(response).to have_http_status(200)
  #     end
  #   end
  # end

  def project_with_repo_path(path)
    double().tap do |fake_project|
      allow(fake_project).to receive_message_chain('repository.path_to_repo' => path)
    end
  end

  def pull(key, project, protocol = 'ssh')
    post(
      api("/internal/allowed"),
      key_id: key.id,
      project: project.repository.path_to_repo,
      action: 'git-upload-pack',
      secret_token: secret_token,
      protocol: protocol
    )
  end

  def pull_with_path(key, path_to_repo, protocol = 'ssh')
    post(
      api("/internal/allowed"),
      key_id: key.id,
      project: path_to_repo,
      action: 'git-upload-pack',
      secret_token: secret_token,
      protocol: protocol
    )
  end

  def push(key, project, protocol = 'ssh', env: nil)
    post(
      api("/internal/allowed"),
      changes: 'd14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/master',
      key_id: key.id,
      project: project.repository.path_to_repo,
      action: 'git-receive-pack',
      secret_token: secret_token,
      protocol: protocol,
      env: env
    )
  end

  def push_with_path(key, path_to_repo, protocol = 'ssh', env: nil)
    post(
      api("/internal/allowed"),
      changes: 'd14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/master',
      key_id: key.id,
      project: path_to_repo,
      action: 'git-receive-pack',
      secret_token: secret_token,
      protocol: protocol,
      env: env
    )
  end

  def archive(key, project)
    post(
      api("/internal/allowed"),
      ref: 'master',
      key_id: key.id,
      project: project.repository.path_to_repo,
      action: 'git-upload-archive',
      secret_token: secret_token,
      protocol: 'ssh'
    )
  end

  def lfs_auth(key_id, project)
    post(
      api("/internal/lfs_authenticate"),
      key_id: key_id,
      secret_token: secret_token,
      project: project.repository.path_to_repo
    )
  end
end
