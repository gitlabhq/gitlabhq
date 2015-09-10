require 'spec_helper'

describe Ci::API::API do
  include ApiHelpers

  let(:gitlab_url) { GitlabCi.config.gitlab_server.url }
  let(:private_token) { Network.new.authenticate(access_token: "some_token")["private_token"] }

  let(:options) {
    {
      private_token: private_token,
      url: gitlab_url
    }
  }

  before {
    stub_gitlab_calls
  }

  context "requests for scoped projects" do
    # NOTE: These ids are tied to the actual projects on demo.gitlab.com
    describe "GET /projects" do
      let!(:project1) { FactoryGirl.create(:ci_project, name: "gitlabhq", gitlab_id: 3) }
      let!(:project2) { FactoryGirl.create(:ci_project, name: "gitlab-ci", gitlab_id: 4) }

      it "should return all projects on the CI instance" do
        get api("/projects"), options
        expect(response.status).to eq(200)
        expect(json_response.count).to eq(2)
        expect(json_response.first["id"]).to eq(project1.id)
        expect(json_response.last["id"]).to eq(project2.id)
      end
    end

    describe "GET /projects/owned" do
      # NOTE: This user doesn't own any of these projects on demo.gitlab.com
      let!(:project1) { FactoryGirl.create(:ci_project, name: "gitlabhq", gitlab_id: 3) }
      let!(:project2) { FactoryGirl.create(:ci_project, name: "random-project", gitlab_id: 9898) }

      it "should return all projects on the CI instance" do
        get api("/projects/owned"), options

        expect(response.status).to eq(200)
        expect(json_response.count).to eq(0)
      end
    end
  end

  describe "POST /projects/:project_id/webhooks" do
    let!(:project) { FactoryGirl.create(:ci_project) }

    context "Valid Webhook URL" do
      let!(:webhook) { {web_hook: "http://example.com/sth/1/ala_ma_kota" } }

      before do
        options.merge!(webhook)
      end

      it "should create webhook for specified project" do
        post api("/projects/#{project.id}/webhooks"), options
        expect(response.status).to eq(201)
        expect(json_response["url"]).to eq(webhook[:web_hook])
      end

      it "fails to create webhook for non existsing project" do
        post api("/projects/non-existant-id/webhooks"), options
        expect(response.status).to eq(404)
      end

      it "non-manager is not authorized" do
        allow_any_instance_of(User).to receive(:can_manage_project?).and_return(false)
        post api("/projects/#{project.id}/webhooks"), options
        expect(response.status).to eq(401)
      end
    end

    context "Invalid Webhook URL" do
      let!(:webhook) { {web_hook: "ala_ma_kota" } }

      before do
        options.merge!(webhook)
      end

      it "fails to create webhook for not valid url" do
        post api("/projects/#{project.id}/webhooks"), options
        expect(response.status).to eq(400)
      end
    end

    context "Missed web_hook parameter" do
      it "fails to create webhook for not provided url" do
        post api("/projects/#{project.id}/webhooks"), options
        expect(response.status).to eq(400)
      end
    end
  end

  describe "GET /projects/:id" do
    let!(:project) { FactoryGirl.create(:ci_project) }

    context "with an existing project" do
      it "should retrieve the project info" do
        get api("/projects/#{project.id}"), options
        expect(response.status).to eq(200)
        expect(json_response['id']).to eq(project.id)
      end
    end

    context "with a non-existing project" do
      it "should return 404 error if project not found" do
        get api("/projects/non_existent_id"), options
        expect(response.status).to eq(404)
      end
    end
  end

  describe "PUT /projects/:id" do
    let!(:project) { FactoryGirl.create(:ci_project) }
    let!(:project_info) { {name: "An updated name!" } }

    before do
      options.merge!(project_info)
    end

    it "should update a specific project's information" do
      put api("/projects/#{project.id}"), options
      expect(response.status).to eq(200)
      expect(json_response["name"]).to eq(project_info[:name])
    end

    it "fails to update a non-existing project" do
      put api("/projects/non-existant-id"), options
      expect(response.status).to eq(404)
    end

    it "non-manager is not authorized" do
      allow_any_instance_of(User).to receive(:can_manage_project?).and_return(false)
      put api("/projects/#{project.id}"), options
      expect(response.status).to eq(401)
    end
  end

  describe "DELETE /projects/:id" do
    let!(:project) { FactoryGirl.create(:ci_project) }

    it "should delete a specific project" do
      delete api("/projects/#{project.id}"), options
      expect(response.status).to eq(200)

      expect { project.reload }.to raise_error
    end

    it "non-manager is not authorized" do
      allow_any_instance_of(User).to receive(:can_manage_project?).and_return(false)
      delete api("/projects/#{project.id}"), options
      expect(response.status).to eq(401)
    end

    it "is getting not found error" do
      delete api("/projects/not-existing_id"), options
      expect(response.status).to eq(404)
    end
  end

  describe "POST /projects" do
    let(:project_info) {
      {
        name: "My project",
        gitlab_id: 1,
        path: "testing/testing",
        ssh_url_to_repo: "ssh://example.com/testing/testing.git"
      }
    }

    let(:invalid_project_info) { {} }

    context "with valid project info" do
      before do
        options.merge!(project_info)
      end

      it "should create a project with valid data" do
        post api("/projects"), options
        expect(response.status).to eq(201)
        expect(json_response['name']).to eq(project_info[:name])
      end
    end

    context "with invalid project info" do
      before do
        options.merge!(invalid_project_info)
      end

      it "should error with invalid data" do
        post api("/projects"), options
        expect(response.status).to eq(400)
      end
    end

    describe "POST /projects/:id/runners/:id" do
      let(:project) { FactoryGirl.create(:ci_project) }
      let(:runner) { FactoryGirl.create(:ci_runner) }

      it "should add the project to the runner" do
        post api("/projects/#{project.id}/runners/#{runner.id}"), options
        expect(response.status).to eq(201)

        project.reload
        expect(project.runners.first.id).to eq(runner.id)
      end

      it "should fail if it tries to link a non-existing project or runner" do
        post api("/projects/#{project.id}/runners/non-existing"), options
        expect(response.status).to eq(404)

        post api("/projects/non-existing/runners/#{runner.id}"), options
        expect(response.status).to eq(404)
      end

      it "non-manager is not authorized" do
        allow_any_instance_of(User).to receive(:can_manage_project?).and_return(false)
        post api("/projects/#{project.id}/runners/#{runner.id}"), options
        expect(response.status).to eq(401)
      end
    end

    describe "DELETE /projects/:id/runners/:id" do
      let(:project) { FactoryGirl.create(:ci_project) }
      let(:runner) { FactoryGirl.create(:ci_runner) }

      before do
        post api("/projects/#{project.id}/runners/#{runner.id}"), options
      end

      it "should remove the project from the runner" do
        expect(project.runners).to be_present
        delete api("/projects/#{project.id}/runners/#{runner.id}"), options
        expect(response.status).to eq(200)

        project.reload
        expect(project.runners).to be_empty
      end

      it "non-manager is not authorized" do
        allow_any_instance_of(User).to receive(:can_manage_project?).and_return(false)
        post api("/projects/#{project.id}/runners/#{runner.id}"), options
        expect(response.status).to eq(401)
      end
    end
  end
end
