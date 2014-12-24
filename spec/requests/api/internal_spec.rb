require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:key) { create(:key, user: user) }
  let(:project) { create(:project) }
  let(:secret_token) { File.read Rails.root.join('.gitlab_shell_secret') }

  describe "GET /internal/check", no_db: true do
    it do
      get api("/internal/check"), secret_token: secret_token

      response.status.should == 200
      json_response['api_version'].should == API::API.version
    end
  end

  describe "GET /internal/discover" do
    it do
      get(api("/internal/discover"), key_id: key.id, secret_token: secret_token)

      response.status.should == 200

      json_response['name'].should == user.name
    end
  end

  describe "POST /internal/allowed" do
    context "access granted" do
      before do
        project.team << [user, :developer]
      end

      context "git pull" do
        it do
          pull(key, project)

          response.status.should == 200
          JSON.parse(response.body)["status"].should be_true
        end
      end

      context "git push" do
        it do
          push(key, project)

          response.status.should == 200
          JSON.parse(response.body)["status"].should be_true
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

          response.status.should == 200
          JSON.parse(response.body)["status"].should be_false
        end
      end

      context "git push" do
        it do
          push(key, project)

          response.status.should == 200
          JSON.parse(response.body)["status"].should be_false
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

          response.status.should == 200
          JSON.parse(response.body)["status"].should be_false
        end
      end

      context "git push" do
        it do
          push(key, personal_project)

          response.status.should == 200
          JSON.parse(response.body)["status"].should be_false
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

          response.status.should == 200
          JSON.parse(response.body)["status"].should be_true
        end
      end

      context "git push" do
        it do
          push(key, project)

          response.status.should == 200
          JSON.parse(response.body)["status"].should be_false
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

          response.status.should == 200
          JSON.parse(response.body)["status"].should be_true
        end
      end

      context "not added to project" do
        it do
          archive(key, project)

          response.status.should == 200
          JSON.parse(response.body)["status"].should be_false
        end
      end
    end

    context 'project does not exist' do
      it do
        pull(key, OpenStruct.new(path_with_namespace: 'gitlab/notexists'))

        response.status.should == 200
        JSON.parse(response.body)["status"].should be_false
      end
    end

    context 'user does not exist' do
      it do
        pull(OpenStruct.new(id: 0), project)

        response.status.should == 200
        JSON.parse(response.body)["status"].should be_false
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
