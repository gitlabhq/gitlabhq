require 'spec_helper'

describe Ci::API::API do
  include ApiHelpers

  let(:gitlab_url) { GitlabCi.config.gitlab_ci.url }
  let(:user) { create(:user) }
  let(:private_token) { user.private_token }

  let(:options) do
    {
      private_token: private_token,
      url: gitlab_url
    }
  end

  before do
    stub_gitlab_calls
  end

  context "requests for scoped projects" do
    # NOTE: These ids are tied to the actual projects on demo.gitlab.com
    describe "GET /projects" do
      let!(:project1) { FactoryGirl.create(:ci_project) }
      let!(:project2) { FactoryGirl.create(:ci_project) }

      before do
        project1.gl_project.team << [user, :developer]
        project2.gl_project.team << [user, :developer]
      end

      it "should return all projects on the CI instance" do
        get ci_api("/projects"), options
        expect(response.status).to eq(200)
        expect(json_response.count).to eq(2)
        expect(json_response.first["id"]).to eq(project1.id)
        expect(json_response.last["id"]).to eq(project2.id)
      end
    end

    describe "GET /projects/owned" do
      let!(:gl_project1) {FactoryGirl.create(:empty_project, namespace: user.namespace)}
      let!(:gl_project2) {FactoryGirl.create(:empty_project, namespace: user.namespace)}
      let!(:project1) { gl_project1.ensure_gitlab_ci_project }
      let!(:project2) { gl_project2.ensure_gitlab_ci_project }

      before do
        project1.gl_project.team << [user, :developer]
        project2.gl_project.team << [user, :developer]
      end

      it "should return all projects on the CI instance" do
        get ci_api("/projects/owned"), options

        expect(response.status).to eq(200)
        expect(json_response.count).to eq(2)
      end
    end
  end

  describe "POST /projects/:project_id/webhooks" do
    let!(:project) { FactoryGirl.create(:ci_project) }

    context "Valid Webhook URL" do
      let!(:webhook) { { web_hook: "http://example.com/sth/1/ala_ma_kota" } }

      before do
        options.merge!(webhook)
      end

      it "should create webhook for specified project" do
        project.gl_project.team << [user, :master]
        post ci_api("/projects/#{project.id}/webhooks"), options
        expect(response.status).to eq(201)
        expect(json_response["url"]).to eq(webhook[:web_hook])
      end

      it "fails to create webhook for non existsing project" do
        post ci_api("/projects/non-existant-id/webhooks"), options
        expect(response.status).to eq(404)
      end

      it "non-manager is not authorized" do
        post ci_api("/projects/#{project.id}/webhooks"), options
        expect(response.status).to eq(401)
      end
    end

    context "Invalid Webhook URL" do
      let!(:webhook) { { web_hook: "ala_ma_kota" } }

      before do
        options.merge!(webhook)
      end

      it "fails to create webhook for not valid url" do
        project.gl_project.team << [user, :master]
        post ci_api("/projects/#{project.id}/webhooks"), options
        expect(response.status).to eq(400)
      end
    end

    context "Missed web_hook parameter" do
      it "fails to create webhook for not provided url" do
        project.gl_project.team << [user, :master]
        post ci_api("/projects/#{project.id}/webhooks"), options
        expect(response.status).to eq(400)
      end
    end
  end

  describe "GET /projects/:id" do
    let!(:project) { FactoryGirl.create(:ci_project) }

    before do
      project.gl_project.team << [user, :developer]
    end

    context "with an existing project" do
      it "should retrieve the project info" do
        get ci_api("/projects/#{project.id}"), options
        expect(response.status).to eq(200)
        expect(json_response['id']).to eq(project.id)
      end
    end

    context "with a non-existing project" do
      it "should return 404 error if project not found" do
        get ci_api("/projects/non_existent_id"), options
        expect(response.status).to eq(404)
      end
    end
  end

  describe "PUT /projects/:id" do
    let!(:project) { FactoryGirl.create(:ci_project) }
    let!(:project_info) { { default_ref: "develop" } }

    before do
      options.merge!(project_info)
    end

    it "should update a specific project's information" do
      project.gl_project.team << [user, :master]
      put ci_api("/projects/#{project.id}"), options
      expect(response.status).to eq(200)
      expect(json_response["default_ref"]).to eq(project_info[:default_ref])
    end

    it "fails to update a non-existing project" do
      put ci_api("/projects/non-existant-id"), options
      expect(response.status).to eq(404)
    end

    it "non-manager is not authorized" do
      put ci_api("/projects/#{project.id}"), options
      expect(response.status).to eq(401)
    end
  end

  describe "DELETE /projects/:id" do
    let!(:project) { FactoryGirl.create(:ci_project) }

    it "should delete a specific project" do
      project.gl_project.team << [user, :master]
      delete ci_api("/projects/#{project.id}"), options
      expect(response.status).to eq(200)
      expect { project.reload }.
        to raise_error(ActiveRecord::RecordNotFound)
    end

    it "non-manager is not authorized" do
      delete ci_api("/projects/#{project.id}"), options
      expect(response.status).to eq(401)
    end

    it "is getting not found error" do
      delete ci_api("/projects/not-existing_id"), options
      expect(response.status).to eq(404)
    end
  end

  describe "POST /projects/:id/runners/:id" do
    let(:project) { FactoryGirl.create(:ci_project) }
    let(:runner) { FactoryGirl.create(:ci_runner) }

    it "should add the project to the runner" do
      project.gl_project.team << [user, :master]
      post ci_api("/projects/#{project.id}/runners/#{runner.id}"), options
      expect(response.status).to eq(201)

      project.reload
      expect(project.runners.first.id).to eq(runner.id)
    end

    it "should fail if it tries to link a non-existing project or runner" do
      post ci_api("/projects/#{project.id}/runners/non-existing"), options
      expect(response.status).to eq(404)

      post ci_api("/projects/non-existing/runners/#{runner.id}"), options
      expect(response.status).to eq(404)
    end

    it "non-manager is not authorized" do
      allow_any_instance_of(User).to receive(:can_manage_project?).and_return(false)
      post ci_api("/projects/#{project.id}/runners/#{runner.id}"), options
      expect(response.status).to eq(401)
    end
  end

  describe "DELETE /projects/:id/runners/:id" do
    let(:project) { FactoryGirl.create(:ci_project) }
    let(:runner) { FactoryGirl.create(:ci_runner) }

    it "should remove the project from the runner" do
      project.gl_project.team << [user, :master]
      post ci_api("/projects/#{project.id}/runners/#{runner.id}"), options

      expect(project.runners).to be_present
      delete ci_api("/projects/#{project.id}/runners/#{runner.id}"), options
      expect(response.status).to eq(200)

      project.reload
      expect(project.runners).to be_empty
    end

    it "non-manager is not authorized" do
      delete ci_api("/projects/#{project.id}/runners/#{runner.id}"), options
      expect(response.status).to eq(401)
    end
  end
end
