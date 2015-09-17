require 'spec_helper'

describe Ci::API::API do
  include ApiHelpers

  let(:project) { FactoryGirl.create(:ci_project) }
  let(:private_token) { create(:user).private_token }

  let(:options) do
    {
      private_token: private_token,
      url: GitlabCi.config.gitlab_ci.url
    }
  end

  before do
    stub_gitlab_calls
  end


  describe "POST /forks" do
    let(:project_info) do
      {
        project_id: project.gitlab_id,
        project_token: project.token,
        data: {
          id:                  create(:empty_project).id,
          name_with_namespace: "Gitlab.org / Underscore",
          path_with_namespace: "gitlab-org/underscore",
          default_branch:      "master",
          ssh_url_to_repo:     "git@example.com:gitlab-org/underscore"
        }
      }
    end

    context "with valid info" do
      before do
        options.merge!(project_info)
      end

      it "should create a project with valid data" do
        post ci_api("/forks"), options
        expect(response.status).to eq(201)
        expect(json_response['name']).to eq("Gitlab.org / Underscore")
      end
    end

    context "with invalid project info" do
      before do
        options.merge!({})
      end

      it "should error with invalid data" do
        post ci_api("/forks"), options
        expect(response.status).to eq(400)
      end
    end
  end
end
