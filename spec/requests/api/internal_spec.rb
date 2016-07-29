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
        end
      end

      context "git push" do
        it do
          push(key, project)

          expect(response).to have_http_status(200)
          expect(json_response["status"]).to be_truthy
          expect(json_response["repository_path"]).to eq(project.repository.path_to_repo)
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
