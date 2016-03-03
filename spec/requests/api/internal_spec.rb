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

      expect(response.status).to eq(200)
      expect(json_response['api_version']).to eq(API::API.version)
    end
  end

  describe "GET /internal/broadcast_message" do
    context "broadcast message exists" do
      let!(:broadcast_message) { create(:broadcast_message, starts_at: Time.now.yesterday, ends_at: Time.now.tomorrow ) }

      it do
        get api("/internal/broadcast_message"), secret_token: secret_token

        expect(response.status).to eq(200)
        expect(json_response["message"]).to eq(broadcast_message.message)
      end
    end

    context "broadcast message doesn't exist" do
      it do
        get api("/internal/broadcast_message"), secret_token: secret_token

        expect(response.status).to eq(200)
        expect(json_response).to be_empty
      end
    end
  end

  describe "GET /internal/discover" do
    it do
      get(api("/internal/discover"), key_id: key.id, secret_token: secret_token)

      expect(response.status).to eq(200)

      expect(json_response['name']).to eq(user.name)
    end
  end

  describe "POST /internal/allowed" do
    context "access granted" do
      before do
        project.team << [user, :developer]
      end

      context "git push with project.wiki" do
        it 'responds with success' do
          project_wiki = create(:project, name: 'my.wiki', path: 'my.wiki')
          project_wiki.team << [user, :developer]

          push(key, project_wiki)

          expect(response.status).to eq(200)
          expect(json_response["status"]).to be_truthy
        end
      end

      context "git pull" do
        it do
          pull(key, project)

          expect(response.status).to eq(200)
          expect(json_response["status"]).to be_truthy
        end
      end

      context "git push" do
        it do
          push(key, project)

          expect(response.status).to eq(200)
          expect(json_response["status"]).to be_truthy
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

          expect(response.status).to eq(200)
          expect(json_response["status"]).to be_falsey
        end
      end

      context "git push" do
        it do
          push(key, project)

          expect(response.status).to eq(200)
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

          expect(response.status).to eq(200)
          expect(json_response["status"]).to be_falsey
        end
      end

      context "git push" do
        it do
          push(key, personal_project)

          expect(response.status).to eq(200)
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

          expect(response.status).to eq(200)
          expect(json_response["status"]).to be_truthy
        end
      end

      context "git push" do
        it do
          push(key, project)

          expect(response.status).to eq(200)
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

          expect(response.status).to eq(200)
          expect(json_response["status"]).to be_truthy
        end
      end

      context "not added to project" do
        it do
          archive(key, project)

          expect(response.status).to eq(200)
          expect(json_response["status"]).to be_falsey
        end
      end
    end

    context 'project does not exist' do
      it do
        pull(key, OpenStruct.new(path_with_namespace: 'gitlab/notexists'))

        expect(response.status).to eq(200)
        expect(json_response["status"]).to be_falsey
      end
    end

    context 'user does not exist' do
      it do
        pull(OpenStruct.new(id: 0), project)

        expect(response.status).to eq(200)
        expect(json_response["status"]).to be_falsey
      end
    end
  end

  def pull(key, project)
    post(
      api("/internal/allowed"),
      key_id: key.id,
      project: project.path_with_namespace,
      action: 'git-upload-pack',
      secret_token: secret_token
    )
  end

  def push(key, project)
    post(
      api("/internal/allowed"),
      changes: 'd14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/master',
      key_id: key.id,
      project: project.path_with_namespace,
      action: 'git-receive-pack',
      secret_token: secret_token
    )
  end

  def archive(key, project)
    post(
      api("/internal/allowed"),
      ref: 'master',
      key_id: key.id,
      project: project.path_with_namespace,
      action: 'git-upload-archive',
      secret_token: secret_token
    )
  end
end
