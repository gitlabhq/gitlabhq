# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::CargoProjectPackages, feature_category: :package_registry do
  include HttpBasicAuthHelpers
  include WorkhorseHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, group: group) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:deploy_token) do
    create(:deploy_token, read_package_registry: true, write_package_registry: true, projects: [project])
  end

  let_it_be(:deploy_token_without_permission) do
    create(:deploy_token, read_package_registry: false, write_package_registry: false)
  end

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
        it_behaves_like 'updating personal access token last used'
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

  describe 'GET /api/v4/projects/:id/packages/cargo/:name/:version/download' do
    let_it_be(:package) { create(:cargo_package, name: 'my-crate', version: '1.0.0', project: project) }
    let_it_be(:metadatum) { create(:cargo_metadatum, package: package) }

    let(:package_name) { package.name }
    let(:package_version) { package.version }
    let(:url) { "/projects/#{project.id}/packages/cargo/#{package_name}/#{package_version}/download" }

    subject(:request) do
      get api(url), headers: headers
    end

    shared_examples 'successful crate download' do
      it 'returns the crate file', :aggregate_failures do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end

      it 'bumps last_downloaded_at on the package' do
        expect { request }
          .to change { package.reload.last_downloaded_at }
          .from(nil).to(instance_of(ActiveSupport::TimeWithZone))
      end
    end

    context 'with public project' do
      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
      end

      it_behaves_like 'successful crate download'
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

        it_behaves_like 'successful crate download'
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

      it_behaves_like 'successful crate download'
    end

    context 'with job token' do
      let(:headers) { { 'Authorization' => "Bearer #{job.token}" } }

      before_all do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
        project.add_developer(user)
      end

      it_behaves_like 'successful crate download'
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

    context 'when package does not exist' do
      let(:package_name) { 'does-not-exist' }

      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
      end

      it 'returns not found' do
        request
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when version does not exist' do
      let(:package_version) { '9.9.9' }

      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
      end

      it 'returns not found' do
        request
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when package files are pending destruction' do
      let_it_be(:pending_destruction_package) do
        create(:cargo_package, name: 'pending-crate', version: '1.0.0', project: project)
      end

      let_it_be(:pending_destruction_metadatum) { create(:cargo_metadatum, package: pending_destruction_package) }

      let(:package_name) { pending_destruction_package.name }
      let(:package_version) { pending_destruction_package.version }

      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
        pending_destruction_package.package_files.update_all(status: :pending_destruction)
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

    describe 'package event tracking' do
      let(:headers) { { 'Authorization' => "Bearer #{personal_access_token.token}" } }
      let(:snowplow_gitlab_standard_context) do
        { project: project, namespace: project.namespace, user: user, property: 'i_package_cargo_user' }
      end

      before_all do
        project.add_developer(user)
      end

      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
      end

      it_behaves_like 'a package tracking event', described_class.name, 'pull_package'
    end

    it_behaves_like 'authorizing granular token permissions', :download_cargo_package do
      let(:boundary_object) { project }
      let(:headers) { { 'Authorization' => "Bearer #{pat.token}" } }
      let(:request) { get(api(url), headers: headers) }

      before_all do
        project.add_developer(user)
      end
    end
  end
end
