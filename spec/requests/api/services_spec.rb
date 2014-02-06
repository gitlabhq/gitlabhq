require "spec_helper"

describe API::API do
  include ApiHelpers
  before(:each) { ActiveRecord::Base.observers.enable(:user_observer) }
  after(:each) { ActiveRecord::Base.observers.disable(:user_observer) }

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
end
