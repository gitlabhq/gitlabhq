# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::CargoProjectPackages, feature_category: :package_registry do
  include HttpBasicAuthHelpers
  include WorkhorseHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:deploy_token_without_permission) do
    create(:deploy_token, read_package_registry: false, write_package_registry: false)
  end

  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }
  let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }
  let(:headers) { {} }

  describe 'GET /api/v4/projects/:id/packages/cargo/config.json' do
    let(:url) { "/projects/#{project.id}/packages/cargo/config.json" }

    subject(:request) do
      get api(url), headers: headers
    end

    shared_examples 'successful config response' do
      it 'returns the config' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expected_url = URI.join(Gitlab.config.gitlab.url,
          "#{api_v4_projects_packages_path(id: project.id)}/packages/cargo").to_s
        expect(json_response).to match(
          "dl" => expected_url,
          "api" => expected_url,
          "auth-required" => !project.public?
        )
      end
    end

    context 'with public project' do
      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
      end

      it_behaves_like 'successful config response'
    end

    context 'with private project' do
      let(:headers) { { 'Authorization' => "Bearer #{personal_access_token.token}" } }

      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
      end

      context 'with authenticated user' do
        before_all do
          project.add_developer(user)
        end

        it_behaves_like 'successful config response'
      end

      context 'with unauthenticated user' do
        it 'returns not found' do
          request
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with deploy token' do
      let(:headers) { { 'Authorization' => "Bearer #{deploy_token.token}" } }

      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
      end

      it_behaves_like 'successful config response'
    end

    context 'with job token' do
      let(:headers) { { 'Authorization' => "Bearer #{job.token}" } }

      before_all do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
        project.add_developer(user)
      end

      it_behaves_like 'successful config response'
    end

    context 'without read permissions deploy token' do
      let(:headers) { { 'Authorization' => "Bearer #{deploy_token_without_permission.token}" } }

      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'returns not found' do
        request
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when package feature is disabled' do
      before do
        stub_config(packages: { enabled: false })
      end

      it_behaves_like 'returning response status', :not_found
    end

    context 'when feature flag is disabled' do
      let(:headers) { { 'Authorization' => "Bearer #{deploy_token.token}" } }

      before do
        stub_feature_flags(package_registry_cargo_support: false)
      end

      it_behaves_like 'returning response status', :not_found
    end
  end
end
