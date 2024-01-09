# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::Pages, feature_category: :pages do
  let_it_be(:project) { create(:project) }
  let_it_be(:admin) { create(:admin) }

  let(:user) { create(:user) }

  before do
    stub_pages_setting(enabled: true)

    create(
      :project_setting,
      project: project,
      pages_unique_domain_enabled: true,
      pages_unique_domain: 'unique-domain')
  end

  context "when get pages setting endpoint" do
    let(:user) { create(:user) }

    it "returns the :ok for project maintainers (and above)" do
      project.add_maintainer(user)

      get api("/projects/#{project.id}/pages", user)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it "returns the :forbidden for project developers (and below)" do
      project.add_developer(user)

      get api("/projects/#{project.id}/pages", user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context "when the pages feature is disabled" do
      it "returns the :not_found when user is not in the project" do
        project.project_feature.update!(pages_access_level: 0)

        get api("/projects/#{project.id}/pages", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "when the project has pages deployments", :time_freeze, :aggregate_failures do
      let_it_be(:created_at) { Time.now.utc }

      before_all do
        create(:pages_deployment, path_prefix: '/foo', project: project, created_at: created_at)
        create(:pages_deployment, project: project, created_at: created_at)

        # this one is here to ensure the endpoint don't return "inactive" deployments
        create(
          :pages_deployment,
          path_prefix: '/bar',
          project: project,
          created_at: created_at,
          deleted_at: 5.minutes.from_now)
      end

      it "return the right data" do
        project.add_owner(user)

        get api("/projects/#{project.id}/pages", user)

        expect(json_response["force_https"]).to eq(false)
        expect(json_response["is_unique_domain_enabled"]).to eq(true)
        expect(json_response["url"]).to eq("http://unique-domain.example.com")
        expect(json_response["deployments"]).to match_array([
          {
            "created_at" => created_at.strftime('%Y-%m-%dT%H:%M:%S.%3LZ'),
            "path_prefix" => "/foo",
            "root_directory" => "public",
            "url" => "http://unique-domain.example.com/foo"
          },
          {
            "created_at" => created_at.strftime('%Y-%m-%dT%H:%M:%S.%3LZ'),
            "path_prefix" => nil,
            "root_directory" => "public",
            "url" => "http://unique-domain.example.com/"
          }
        ])
      end
    end
  end
end
