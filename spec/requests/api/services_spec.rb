require "spec_helper"

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:project) {create(:project, creator_id: user.id, namespace: user.namespace) }

  describe "POST /projects/:id/services/gitlab-ci" do
    it "should update gitlab-ci settings" do
      put api("/projects/#{project.id}/services/gitlab-ci", user), token: 'secrettoken', project_url: "http://ci.example.com/projects/1"

      expect(response.status).to eq(200)
    end

    it "should return if required fields missing" do
      put api("/projects/#{project.id}/services/gitlab-ci", user), project_url: "http://ci.example.com/projects/1", active: true

      expect(response.status).to eq(400)
    end

    it "should return if the format of token is invalid" do
      put api("/projects/#{project.id}/services/gitlab-ci", user), token: 'token-with dashes and spaces%', project_url: "http://ci.example.com/projects/1", active: true

      expect(response.status).to eq(404)
    end

    it "should return if the format of token is invalid" do
      put api("/projects/#{project.id}/services/gitlab-ci", user), token: 'token-with dashes and spaces%', project_url: "ftp://ci.example/projects/1", active: true

      expect(response.status).to eq(404)
    end
  end

  describe "DELETE /projects/:id/services/gitlab-ci" do
    it "should update gitlab-ci settings" do
      delete api("/projects/#{project.id}/services/gitlab-ci", user)

      expect(response.status).to eq(200)
      expect(project.gitlab_ci_service).to be_nil
    end
  end

  describe 'PUT /projects/:id/services/hipchat' do
    it 'should update hipchat settings' do
      put api("/projects/#{project.id}/services/hipchat", user),
          token: 'secret-token', room: 'test'

      expect(response.status).to eq(200)
      expect(project.hipchat_service).not_to be_nil
    end

    it 'should return if required fields missing' do
      put api("/projects/#{project.id}/services/gitlab-ci", user),
          token: 'secret-token', active: true

      expect(response.status).to eq(400)
    end
  end

  describe 'DELETE /projects/:id/services/hipchat' do
    it 'should delete hipchat settings' do
      delete api("/projects/#{project.id}/services/hipchat", user)

      expect(response.status).to eq(200)
      expect(project.hipchat_service).to be_nil
    end
  end
end
