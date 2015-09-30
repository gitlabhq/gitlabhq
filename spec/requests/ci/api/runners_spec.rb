require 'spec_helper'

describe Ci::API::API do
  include ApiHelpers
  include StubGitlabCalls

  before do
    stub_gitlab_calls
  end

  describe "GET /runners" do
    let(:gitlab_url) { GitlabCi.config.gitlab_ci.url }
    let(:private_token) { create(:user).private_token }
    let(:options) do
      {
        private_token: private_token,
        url: gitlab_url
      }
    end

    before do
      5.times { FactoryGirl.create(:ci_runner) }
    end

    it "should retrieve a list of all runners" do
      get ci_api("/runners", nil), options
      expect(response.status).to eq(200)
      expect(json_response.count).to eq(5)
      expect(json_response.last).to have_key("id")
      expect(json_response.last).to have_key("token")
    end
  end

  describe "POST /runners/register" do
    describe "should create a runner if token provided" do
      before { post ci_api("/runners/register"), token: GitlabCi::REGISTRATION_TOKEN }

      it { expect(response.status).to eq(201) }
    end

    describe "should create a runner with description" do
      before { post ci_api("/runners/register"), token: GitlabCi::REGISTRATION_TOKEN, description: "server.hostname" }

      it { expect(response.status).to eq(201) }
      it { expect(Ci::Runner.first.description).to eq("server.hostname") }
    end

    describe "should create a runner with tags" do
      before { post ci_api("/runners/register"), token: GitlabCi::REGISTRATION_TOKEN, tag_list: "tag1, tag2" }

      it { expect(response.status).to eq(201) }
      it { expect(Ci::Runner.first.tag_list.sort).to eq(["tag1", "tag2"]) }
    end

    describe "should create a runner if project token provided" do
      let(:project) { FactoryGirl.create(:ci_project) }
      before { post ci_api("/runners/register"), token: project.token }

      it { expect(response.status).to eq(201) }
      it { expect(project.runners.size).to eq(1) }
    end

    it "should return 403 error if token is invalid" do
      post ci_api("/runners/register"), token: 'invalid'

      expect(response.status).to eq(403)
    end

    it "should return 400 error if no token" do
      post ci_api("/runners/register")

      expect(response.status).to eq(400)
    end
  end

  describe "DELETE /runners/delete" do
    let!(:runner) { FactoryGirl.create(:ci_runner) }
    before { delete ci_api("/runners/delete"), token: runner.token }

    it { expect(response.status).to eq(200) }
    it { expect(Ci::Runner.count).to eq(0) }
  end
end
