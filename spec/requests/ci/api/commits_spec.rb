require 'spec_helper'

describe Ci::API::API, 'Commits' do
  include ApiHelpers

  let(:project) { FactoryGirl.create(:ci_project) }
  let(:gl_project) { FactoryGirl.create(:empty_project, gitlab_ci_project: project) }
  let(:commit) { FactoryGirl.create(:ci_commit, gl_project: gl_project) }

  let(:options) do
    {
      project_token: project.token,
      project_id: project.id
    }
  end

  describe "GET /commits" do
    before { commit }

    it "should return commits per project" do
      get ci_api("/commits"), options

      expect(response.status).to eq(200)
      expect(json_response.count).to eq(1)
      expect(json_response.first["project_id"]).to eq(project.id)
      expect(json_response.first["sha"]).to eq(commit.sha)
    end
  end

  describe "POST /commits" do
    let(:data) do
      {
        "before" => "95790bf891e76fee5e1747ab589903a6a1f80f22",
        "after" => "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
        "ref" => "refs/heads/master",
        "commits" => [
          {
            "id" => "b6568db1bc1dcd7f8b4d5a946b0b91f9dacd7327",
            "message" => "Update Catalan translation to e38cb41.",
            "timestamp" => "2011-12-12T14:27:31+02:00",
            "url" => "http://localhost/diaspora/commits/b6568db1bc1dcd7f8b4d5a946b0b91f9dacd7327",
            "author" => {
              "name" => "Jordi Mallach",
              "email" => "jordi@softcatala.org",
            }
          }
        ]
      }
    end

    it "should create a build" do
      post ci_api("/commits"), options.merge(data: data)

      expect(response.status).to eq(201)
      expect(json_response['sha']).to eq("da1560886d4f094c3e6c9ef40349f7d38b5d27d7")
    end

    it "should return 400 error if no data passed" do
      post ci_api("/commits"), options

      expect(response.status).to eq(400)
      expect(json_response['message']).to eq("400 (Bad request) \"data\" not given")
    end
  end
end
