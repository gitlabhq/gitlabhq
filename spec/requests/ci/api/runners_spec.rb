require 'spec_helper'

describe Ci::API::API do
  include ApiHelpers
  include StubGitlabCalls

  let(:registration_token) { 'abcdefg123456' }

  before do
    stub_gitlab_calls
    stub_application_setting(runners_registration_token: registration_token)
  end

  describe "POST /runners/register" do
    describe "should create a runner if token provided" do
      before { post ci_api("/runners/register"), token: registration_token }

      it { expect(response.status).to eq(201) }
    end

    describe "should create a runner with description" do
      before { post ci_api("/runners/register"), token: registration_token, description: "server.hostname" }

      it { expect(response.status).to eq(201) }
      it { expect(Ci::Runner.first.description).to eq("server.hostname") }
    end

    describe "should create a runner with tags" do
      before { post ci_api("/runners/register"), token: registration_token, tag_list: "tag1, tag2" }

      it { expect(response.status).to eq(201) }
      it { expect(Ci::Runner.first.tag_list.sort).to eq(["tag1", "tag2"]) }
    end

    describe "should create a runner if project token provided" do
      let(:project) { FactoryGirl.create(:empty_project) }
      before { post ci_api("/runners/register"), token: project.runners_token }

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

    %w(name version revision platform architecture).each do |param|
      context "creates runner with #{param} saved" do
        let(:value) { "#{param}_value" }

        subject { Ci::Runner.first.read_attribute(param.to_sym) }

        it do
          post ci_api("/runners/register"), token: registration_token, info: { param => value }
          expect(response.status).to eq(201)
          is_expected.to eq(value)
        end
      end
    end
  end

  describe "DELETE /runners/delete" do
    let!(:runner) { FactoryGirl.create(:ci_runner) }
    before { delete ci_api("/runners/delete"), token: runner.token }

    it { expect(response.status).to eq(200) }
    it { expect(Ci::Runner.count).to eq(0) }
  end
end
