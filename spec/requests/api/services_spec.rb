require "spec_helper"

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:project) {create(:project, creator_id: user.id, namespace: user.namespace) }

  describe "POST /projects/:id/services/gitlab-ci" do
    it "should update gitlab-ci settings" do
      put api("/projects/#{project.id}/services/gitlab-ci", user), token: 'secret-token', project_url: "http://ci.example.com/projects/1"

      response.status.should == 200
    end

    it "should return if required fields missing" do
      put api("/projects/#{project.id}/services/gitlab-ci", user), project_url: "http://ci.example.com/projects/1", active: true

      response.status.should == 400
    end
  end

  describe "DELETE /projects/:id/services/gitlab-ci" do
    it "should update gitlab-ci settings" do
      delete api("/projects/#{project.id}/services/gitlab-ci", user)

      response.status.should == 200
      project.gitlab_ci_service.should be_nil
    end
  end

  describe 'PUT /projects/:id/services/hipchat' do
    it 'should update hipchat settings' do
      put api("/projects/#{project.id}/services/hipchat", user),
          token: 'secret-token', room: 'test'

      response.status.should == 200
      project.hipchat_service.should_not be_nil
    end

    it 'should return if required fields missing' do
      put api("/projects/#{project.id}/services/gitlab-ci", user),
          token: 'secret-token', active: true

      response.status.should == 400
    end
  end

  describe 'DELETE /projects/:id/services/hipchat' do
    it 'should delete hipchat settings' do
      delete api("/projects/#{project.id}/services/hipchat", user)

      response.status.should == 200
      project.hipchat_service.should be_nil
    end
  end
end
