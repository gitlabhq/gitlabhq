require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:key) { create(:key, user: user) }
  let(:project) { create(:project) }
  let(:secret_token) { File.read Gitlab.config.gitlab_shell.secret_file }

  describe "GET /internal/check", no_db: true do
    it do
      get api("/internal/check"), secret_token: secret_token

      expect(response).to have_http_status(200)
      expect(json_response['api_version']).to eq(API::API.version)
    end
  end

  describe "GET /internal/broadcast_message" do
    context "broadcast message exists" do
      let!(:broadcast_message) { create(:broadcast_message, starts_at: Time.now.yesterday, ends_at: Time.now.tomorrow ) }

      it do
        get api("/internal/broadcast_message"), secret_token: secret_token

        expect(response).to have_http_status(200)
        expect(json_response["message"]).to eq(broadcast_message.message)
      end
    end

    context "broadcast message doesn't exist" do
      it do
        get api("/internal/broadcast_message"), secret_token: secret_token

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

  describe "GET /internal/discover" do
    context 'user key' do
      it 'returns the correct information about the key' do
        get(api("/internal/discover"), key_id: key.id, secret_token: secret_token)

        expect(response).to have_http_status(200)

        expect(json_response['name']).to eq(user.name)
        expect(json_response['lfs_token']).to eq(user.lfs_token)
      end
    end

    context 'deploy key' do
      let(:key) { create(:deploy_key) }

      it 'returns the correct information about the key' do
        get(api("/internal/discover"), key_id: key.id, secret_token: secret_token)

        expect(response).to have_http_status(200)

        expect(json_response['username']).to eq('lfs-deploy-key')
        expect(json_response['lfs_token']).to eq(key.lfs_token)
      end
    end
  end

  describe "POST /internal/allowed" do
    context "access granted" do
      before do
        project.team << [user, :developer]
      end

      context "git push with project.wiki" do
        it 'responds with success' do
          push(key, project.wiki)

          expect(response).to have_http_status(200)
          expect(json_response["status"]).to be_truthy
          expect(json_response["repository_path"]).to eq(project.wiki.repository.path_to_repo)
        end
      end

      context "git pull with project.wiki" do
        it 'responds with success' do
          pull(key, project.wiki)

          expect(response).to have_http_status(200)
          expect(json_response["status"]).to be_truthy
          expect(json_response["repository_path"]).to eq(project.wiki.repository.path_to_repo)
        end
      end

      context "git pull" do
        it do
          pull(key, project)

          expect(response).to have_http_status(200)
          expect(json_response["status"]).to be_truthy
          expect(json_response["repository_path"]).to eq(project.repository.path_to_repo)
          expect(json_response["repository_http_path"]).to eq(project.http_url_to_repo)
        end
      end

      context "git push" do
        it do
          push(key, project)

          expect(response).to have_http_status(200)
          expect(json_response["status"]).to be_truthy
          expect(json_response["repository_path"]).to eq(project.repository.path_to_repo)
          expect(json_response["repository_http_path"]).to eq(project.http_url_to_repo)
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

    context "blocked user" do
      let(:personal_project) { create(:project, namespace: user.namespace) }

      before do
        user.block
      end

      context "git pull" do
        it do
          pull(key, personal_project)

          expect(response).to have_http_status(200)
          expect(json_response["status"]).to be_falsey
        end
      end

      context "git push" do
        it do
          push(key, personal_project)

          expect(response).to have_http_status(200)
          expect(json_response["status"]).to be_falsey
        end
      end
    end

    context "archived project" do
      let(:personal_project) { create(:project, namespace: user.namespace) }

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
        pull(key, OpenStruct.new(path_with_namespace: 'gitlab/notexists'))

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
        settings = ::ApplicationSetting.create_from_defaults
        settings.update_attribute(:enabled_git_access_protocol, 'http')
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
        settings = ::ApplicationSetting.create_from_defaults
        settings.update_attribute(:enabled_git_access_protocol, 'ssh')
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
        settings = ::ApplicationSetting.create_from_defaults
        settings.update_attribute(:enabled_git_access_protocol, 'ssh')
        project.team << [user, :developer]
        push(key, project, 'web')

        expect(response.status).to eq(200)
        expect(json_response['status']).to be_truthy
      end
    end
  end

  describe 'GET /internal/merge_request_urls' do
    let(:repo_name) { "#{project.namespace.name}/#{project.path}" }
    let(:changes) { URI.escape("#{Gitlab::Git::BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/new_branch") }

    before do
      project.team << [user, :developer]
      get api("/internal/merge_request_urls?project=#{repo_name}&changes=#{changes}"), secret_token: secret_token
    end

    it 'returns link to create new merge request' do
      expect(json_response).to match [{
        "branch_name" => "new_branch",
        "url" => "http://localhost/#{project.namespace.name}/#{project.path}/merge_requests/new?merge_request%5Bsource_branch%5D=new_branch",
        "new_merge_request" => true
      }]
    end
  end

  def pull(key, project, protocol = 'ssh')
    post(
      api("/internal/allowed"),
      key_id: key.id,
      project: project.path_with_namespace,
      action: 'git-upload-pack',
      secret_token: secret_token,
      protocol: protocol
    )
  end

  def push(key, project, protocol = 'ssh')
    post(
      api("/internal/allowed"),
      changes: 'd14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/master',
      key_id: key.id,
      project: project.path_with_namespace,
      action: 'git-receive-pack',
      secret_token: secret_token,
      protocol: protocol
    )
  end

  def archive(key, project)
    post(
      api("/internal/allowed"),
      ref: 'master',
      key_id: key.id,
      project: project.path_with_namespace,
      action: 'git-upload-archive',
      secret_token: secret_token,
      protocol: 'ssh'
    )
  end
end
