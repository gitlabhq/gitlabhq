require 'spec_helper'

describe API::API, 'ProjectPushRule', api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:user3) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id, namespace: user.namespace) }

  before do
    project.team << [user, :master]
    project.team << [user3, :developer]
  end

  describe "GET /projects/:id/push_rule" do
    before do
      create(:push_rule, project: project)
    end

    context "authorized user" do
      it "should return project push rule" do
        get api("/projects/#{project.id}/push_rule", user)
        expect(response.status).to eq(200)

        expect(json_response).to be_an Hash
        expect(json_response['project_id']).to eq(project.id)
      end
    end

    context "unauthorized user" do
      it "should not access project push rule" do
        get api("/projects/#{project.id}/push_rule", user3)
        expect(response.status).to eq(403)
      end
    end
  end

  describe "POST /projects/:id/push_rule" do
    context "authorized user" do
      it "should add push rule to project" do
        post api("/projects/#{project.id}/push_rule", user),
          deny_delete_tag: true
        expect(response.status).to eq(201)

        expect(json_response).to be_an Hash
        expect(json_response['project_id']).to eq(project.id)
        expect(json_response['deny_delete_tag']).to eq(true)
      end
    end

    context "unauthorized user" do
      it "should not add push rule to project" do
        post api("/projects/#{project.id}/push_rule", user3),
          deny_delete_tag: true
        expect(response.status).to eq(403)
      end
    end
  end

  describe "POST /projects/:id/push_rule" do
    before do
      create(:push_rule, project: project)
    end

    context "with existing push rule" do
      it "should not add push rule to project" do
        post api("/projects/#{project.id}/push_rule", user),
          deny_delete_tag: true
        expect(response.status).to eq(422)
      end
    end
  end

  describe "PUT /projects/:id/push_rule" do
    before do
      create(:push_rule, project: project)
    end

    it "should update an existing project push rule" do
      put api("/projects/#{project.id}/push_rule", user),
        deny_delete_tag: false, commit_message_regex: 'Fixes \d+\..*'
      expect(response.status).to eq(200)

      expect(json_response['deny_delete_tag']).to eq(false)
      expect(json_response['commit_message_regex']).to eq('Fixes \d+\..*')
    end
  end

  describe "PUT /projects/:id/push_rule" do
    it "should error on non existing project push rule" do
      put api("/projects/#{project.id}/push_rule", user),
        deny_delete_tag: false, commit_message_regex: 'Fixes \d+\..*'
      expect(response.status).to eq(404)
    end

    it "should not update push rule for unauthorized user" do
      post api("/projects/#{project.id}/push_rule", user3),
        deny_delete_tag: true
      expect(response.status).to eq(403)
    end
  end

  describe "DELETE /projects/:id/push_rule" do
    before do
      create(:push_rule, project: project)
    end

    context "authorized user" do
      it "should delete push rule from project" do
        delete api("/projects/#{project.id}/push_rule", user)
        expect(response.status).to eq(200)

        expect(json_response).to be_an Hash
      end
    end

    context "unauthorized user" do
      it "should return a 403 error" do
        delete api("/projects/#{project.id}/push_rule", user3)
        expect(response.status).to eq(403)
      end
    end
  end

  describe "DELETE /projects/:id/push_rule" do
    context "for non existing push rule" do
      it "should delete push rule from project" do
        delete api("/projects/#{project.id}/push_rule", user)
        expect(response.status).to eq(404)

        expect(json_response).to be_an Hash
        expect(json_response['message']).to eq("404 Not Found")
      end

      it "should return a 403 error if not authorized" do
        delete api("/projects/#{project.id}/push_rule", user3)
        expect(response.status).to eq(403)
      end
    end
  end
end
