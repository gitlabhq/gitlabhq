require 'spec_helper'

describe API::API do
  include ApiHelpers
  before(:each) { ActiveRecord::Base.observers.enable(:user_observer) }
  after(:each) { ActiveRecord::Base.observers.disable(:user_observer) }

  let(:user) { create(:user) }
  let(:key) { create(:key, user: user) }
  let(:project) { create(:project) }

  describe "GET /internal/check", no_db: true do
    it do
      get api("/internal/check")

      response.status.should == 200
      json_response['api_version'].should == API::API.version
    end
  end

  describe "GET /internal/discover" do
    it do
      get(api("/internal/discover"), key_id: key.id)

      response.status.should == 200

      json_response['name'].should == user.name
    end
  end

  describe "GET /internal/allowed" do
    context "access granted" do
      before do
        project.team << [user, :developer]
      end

      context "git pull" do
        it do
          pull(key, project)

          response.status.should == 200
          response.body.should == 'true'
        end
      end

      context "git push" do
        it do
          push(key, project)

          response.status.should == 200
          response.body.should == 'true'
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
          response.body.should == 'false'
        end
      end

      context "git push" do
        it do
          push(key, project)

          response.status.should == 200
          response.body.should == 'false'
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
          response.body.should == 'false'
        end
      end

      context "git push" do
        it do
          push(key, personal_project)

          response.status.should == 200
          response.body.should == 'false'
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
          response.body.should == 'true'
        end
      end

      context "git push" do
        it do
          push(key, project)

          response.status.should == 200
          response.body.should == 'false'
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
          response.body.should == 'true'
        end
      end

      context "not added to project" do
        it do
          archive(key, project)

          response.status.should == 200
          response.body.should == 'false'
        end
      end
    end
  end

  def pull(key, project)
    get(
      api("/internal/allowed"),
      ref: 'master',
      key_id: key.id,
      project: project.path_with_namespace,
      action: 'git-upload-pack'
    )
  end

  def push(key, project)
    get(
      api("/internal/allowed"),
      ref: 'master',
      key_id: key.id,
      project: project.path_with_namespace,
      action: 'git-receive-pack'
    )
  end

  def archive(key, project)
    get(
      api("/internal/allowed"),
      ref: 'master',
      key_id: key.id,
      project: project.path_with_namespace,
      action: 'git-upload-archive'
    )
  end
end
