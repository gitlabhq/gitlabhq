# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::NpmPackages do
  include PackagesManagerApiSpecHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project, reload: true) { create(:project, :public, namespace: group) }
  let_it_be(:package, reload: true) { create(:npm_package, project: project) }
  let_it_be(:token) { create(:oauth_access_token, scopes: 'api', resource_owner: user) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:job) { create(:ci_build, user: user) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }

  before do
    project.add_developer(user)
  end

  shared_examples 'a package that requires auth' do
    it 'returns the package info with oauth token' do
      get_package_with_token(package)

      expect_a_valid_package_response
    end

    it 'returns the package info with job token' do
      get_package_with_job_token(package)

      expect_a_valid_package_response
    end

    it 'denies request without oauth token' do
      get_package(package)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'returns the package info with deploy token' do
      get_package_with_deploy_token(package)

      expect_a_valid_package_response
    end
  end

  describe 'GET /api/v4/packages/npm/*package_name' do
    let_it_be(:package_dependency_link1) { create(:packages_dependency_link, package: package, dependency_type: :dependencies) }
    let_it_be(:package_dependency_link2) { create(:packages_dependency_link, package: package, dependency_type: :devDependencies) }
    let_it_be(:package_dependency_link3) { create(:packages_dependency_link, package: package, dependency_type: :bundleDependencies) }
    let_it_be(:package_dependency_link4) { create(:packages_dependency_link, package: package, dependency_type: :peerDependencies) }

    shared_examples 'returning the npm package info' do
      it 'returns the package info' do
        get_package(package)

        expect_a_valid_package_response
      end
    end

    shared_examples 'returning forbidden for unknown package' do
      context 'with an unknown package' do
        it 'returns forbidden' do
          get api("/packages/npm/unknown")

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'a public project' do
      it_behaves_like 'returning the npm package info'

      context 'with application setting enabled' do
        before do
          stub_application_setting(npm_package_requests_forwarding: true)
        end

        it_behaves_like 'returning the npm package info'

        context 'with unknown package' do
          it 'returns a redirect' do
            get api("/packages/npm/unknown")

            expect(response).to have_gitlab_http_status(:found)
            expect(response.headers['Location']).to eq('https://registry.npmjs.org/unknown')
          end
        end
      end

      context 'with application setting disabled' do
        before do
          stub_application_setting(npm_package_requests_forwarding: false)
        end

        it_behaves_like 'returning the npm package info'

        it_behaves_like 'returning forbidden for unknown package'
      end

      context 'project path with a dot' do
        before do
          project.update!(path: 'foo.bar')
        end

        it_behaves_like 'returning the npm package info'
      end
    end

    context 'internal project' do
      before do
        project.team.truncate
        project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      end

      it_behaves_like 'a package that requires auth'
    end

    context 'private project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it_behaves_like 'a package that requires auth'

      it 'denies request when not enough permissions' do
        project.add_guest(user)

        get_package_with_token(package)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    def get_package(package, params = {}, headers = {})
      get api("/packages/npm/#{package.name}"), params: params, headers: headers
    end

    def get_package_with_token(package, params = {})
      get_package(package, params.merge(access_token: token.token))
    end

    def get_package_with_job_token(package, params = {})
      get_package(package, params.merge(job_token: job.token))
    end

    def get_package_with_deploy_token(package, params = {})
      get_package(package, {}, build_token_auth_header(deploy_token.token))
    end
  end

  describe 'GET /api/v4/projects/:id/packages/npm/*package_name/-/*file_name' do
    let_it_be(:package_file) { package.package_files.first }

    shared_examples 'a package file that requires auth' do
      it 'returns the file with an access token' do
        get_file_with_token(package_file)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end

      it 'returns the file with a job token' do
        get_file_with_job_token(package_file)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end

      it 'denies download with no token' do
        get_file(package_file)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'a public project' do
      subject { get_file(package_file) }

      it 'returns the file with no token needed' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end

      it_behaves_like 'a gitlab tracking event', described_class.name, 'pull_package'
    end

    context 'private project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it_behaves_like 'a package file that requires auth'

      it 'denies download when not enough permissions' do
        project.add_guest(user)

        get_file_with_token(package_file)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'internal project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      end

      it_behaves_like 'a package file that requires auth'
    end

    def get_file(package_file, params = {})
      get api("/projects/#{project.id}/packages/npm/" \
              "#{package_file.package.name}/-/#{package_file.file_name}"), params: params
    end

    def get_file_with_token(package_file, params = {})
      get_file(package_file, params.merge(access_token: token.token))
    end

    def get_file_with_job_token(package_file, params = {})
      get_file(package_file, params.merge(job_token: job.token))
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/npm/:package_name' do
    RSpec.shared_examples 'handling invalid record with 400 error' do
      it 'handles an ActiveRecord::RecordInvalid exception with 400 error' do
        expect { upload_package_with_token(package_name, params) }
          .not_to change { project.packages.count }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when params are correct' do
      context 'invalid package record' do
        context 'unscoped package' do
          let(:package_name) { 'my_unscoped_package' }
          let(:params) { upload_params(package_name: package_name) }

          it_behaves_like 'handling invalid record with 400 error'

          context 'with empty versions' do
            let(:params) { upload_params(package_name: package_name).merge!(versions: {}) }

            it 'throws a 400 error' do
              expect { upload_package_with_token(package_name, params) }
              .not_to change { project.packages.count }

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end

        context 'invalid package name' do
          let(:package_name) { "@#{group.path}/my_inv@@lid_package_name" }
          let(:params) { upload_params(package_name: package_name) }

          it_behaves_like 'handling invalid record with 400 error'
        end

        context 'invalid package version' do
          using RSpec::Parameterized::TableSyntax

          let(:package_name) { "@#{group.path}/my_package_name" }

          where(:version) do
            [
              '1',
              '1.2',
              '1./2.3',
              '../../../../../1.2.3',
              '%2e%2e%2f1.2.3'
            ]
          end

          with_them do
            let(:params) { upload_params(package_name: package_name, package_version: version) }

            it_behaves_like 'handling invalid record with 400 error'
          end
        end
      end

      context 'scoped package' do
        let(:package_name) { "@#{group.path}/my_package_name" }
        let(:params) { upload_params(package_name: package_name) }

        context 'with access token' do
          subject { upload_package_with_token(package_name, params) }

          it_behaves_like 'a gitlab tracking event', described_class.name, 'push_package'

          it 'creates npm package with file' do
            expect { subject }
              .to change { project.packages.count }.by(1)
              .and change { Packages::PackageFile.count }.by(1)
              .and change { Packages::Tag.count }.by(1)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        it 'creates npm package with file with job token' do
          expect { upload_package_with_job_token(package_name, params) }
            .to change { project.packages.count }.by(1)
            .and change { Packages::PackageFile.count }.by(1)

          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'with an authenticated job token' do
          let!(:job) { create(:ci_build, user: user) }

          before do
            Grape::Endpoint.before_each do |endpoint|
              expect(endpoint).to receive(:current_authenticated_job) { job }
            end
          end

          after do
            Grape::Endpoint.before_each nil
          end

          it 'creates the package metadata' do
            upload_package_with_token(package_name, params)

            expect(response).to have_gitlab_http_status(:ok)
            expect(project.reload.packages.find(json_response['id']).build_info.pipeline).to eq job.pipeline
          end
        end
      end

      context 'package creation fails' do
        let(:package_name) { "@#{group.path}/my_package_name" }
        let(:params) { upload_params(package_name: package_name) }

        it 'returns an error if the package already exists' do
          create(:npm_package, project: project, version: '1.0.1', name: "@#{group.path}/my_package_name")
          expect { upload_package_with_token(package_name, params) }
            .not_to change { project.packages.count }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'with dependencies' do
        let(:package_name) { "@#{group.path}/my_package_name" }
        let(:params) { upload_params(package_name: package_name, file: 'npm/payload_with_duplicated_packages.json') }

        it 'creates npm package with file and dependencies' do
          expect { upload_package_with_token(package_name, params) }
            .to change { project.packages.count }.by(1)
            .and change { Packages::PackageFile.count }.by(1)
            .and change { Packages::Dependency.count}.by(4)
            .and change { Packages::DependencyLink.count}.by(6)

          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'with existing dependencies' do
          before do
            name = "@#{group.path}/existing_package"
            upload_package_with_token(name, upload_params(package_name: name, file: 'npm/payload_with_duplicated_packages.json'))
          end

          it 'reuses them' do
            expect { upload_package_with_token(package_name, params) }
              .to change { project.packages.count }.by(1)
              .and change { Packages::PackageFile.count }.by(1)
              .and not_change { Packages::Dependency.count}
              .and change { Packages::DependencyLink.count}.by(6)
          end
        end
      end
    end

    def upload_package(package_name, params = {})
      put api("/projects/#{project.id}/packages/npm/#{package_name.sub('/', '%2f')}"), params: params
    end

    def upload_package_with_token(package_name, params = {})
      upload_package(package_name, params.merge(access_token: token.token))
    end

    def upload_package_with_job_token(package_name, params = {})
      upload_package(package_name, params.merge(job_token: job.token))
    end

    def upload_params(package_name:, package_version: '1.0.1', file: 'npm/payload.json')
      Gitlab::Json.parse(fixture_file("packages/#{file}")
          .gsub('@root/npm-test', package_name)
          .gsub('1.0.1', package_version))
    end
  end

  describe 'GET /api/v4/packages/npm/-/package/*package_name/dist-tags' do
    let_it_be(:package_tag1) { create(:packages_tag, package: package) }
    let_it_be(:package_tag2) { create(:packages_tag, package: package) }

    let(:package_name) { package.name }
    let(:url) { "/packages/npm/-/package/#{package_name}/dist-tags" }

    subject { get api(url) }

    context 'without the need for a license' do
      context 'with public project' do
        context 'with authenticated user' do
          subject { get api(url, personal_access_token: personal_access_token) }

          it_behaves_like 'returns package tags', :maintainer
          it_behaves_like 'returns package tags', :developer
          it_behaves_like 'returns package tags', :reporter
          it_behaves_like 'returns package tags', :guest
        end

        context 'with unauthenticated user' do
          it_behaves_like 'returns package tags', :no_type
        end
      end

      context 'with private project' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        end

        context 'with authenticated user' do
          subject { get api(url, personal_access_token: personal_access_token) }

          it_behaves_like 'returns package tags', :maintainer
          it_behaves_like 'returns package tags', :developer
          it_behaves_like 'returns package tags', :reporter
          it_behaves_like 'rejects package tags access', :guest, :forbidden
        end

        context 'with unauthenticated user' do
          it_behaves_like 'rejects package tags access', :no_type, :forbidden
        end
      end
    end
  end

  describe 'PUT /api/v4/packages/npm/-/package/*package_name/dist-tags/:tag' do
    let_it_be(:tag_name) { 'test' }

    let(:package_name) { package.name }
    let(:version) { package.version }
    let(:url) { "/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}" }

    subject { put api(url), env: { 'api.request.body': version } }

    context 'without the need for a license' do
      context 'with public project' do
        context 'with authenticated user' do
          subject { put api(url, personal_access_token: personal_access_token), env: { 'api.request.body': version } }

          it_behaves_like 'create package tag', :maintainer
          it_behaves_like 'create package tag', :developer
          it_behaves_like 'rejects package tags access', :reporter, :forbidden
          it_behaves_like 'rejects package tags access', :guest, :forbidden
        end

        context 'with unauthenticated user' do
          it_behaves_like 'rejects package tags access', :no_type, :unauthorized
        end
      end

      context 'with private project' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        end

        context 'with authenticated user' do
          subject { put api(url, personal_access_token: personal_access_token), env: { 'api.request.body': version } }

          it_behaves_like 'create package tag', :maintainer
          it_behaves_like 'create package tag', :developer
          it_behaves_like 'rejects package tags access', :reporter, :forbidden
          it_behaves_like 'rejects package tags access', :guest, :forbidden
        end

        context 'with unauthenticated user' do
          it_behaves_like 'rejects package tags access', :no_type, :unauthorized
        end
      end
    end
  end

  describe 'DELETE /api/v4/packages/npm/-/package/*package_name/dist-tags/:tag' do
    let_it_be(:package_tag) { create(:packages_tag, package: package) }

    let(:package_name) { package.name }
    let(:tag_name) { package_tag.name }
    let(:url) { "/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}" }

    subject { delete api(url) }

    context 'without the need for a license' do
      context 'with public project' do
        context 'with authenticated user' do
          subject { delete api(url, personal_access_token: personal_access_token) }

          it_behaves_like 'delete package tag', :maintainer
          it_behaves_like 'rejects package tags access', :developer, :forbidden
          it_behaves_like 'rejects package tags access', :reporter, :forbidden
          it_behaves_like 'rejects package tags access', :guest, :forbidden
        end

        context 'with unauthenticated user' do
          it_behaves_like 'rejects package tags access', :no_type, :unauthorized
        end
      end

      context 'with private project' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        end

        context 'with authenticated user' do
          subject { delete api(url, personal_access_token: personal_access_token) }

          it_behaves_like 'delete package tag', :maintainer
          it_behaves_like 'rejects package tags access', :developer, :forbidden
          it_behaves_like 'rejects package tags access', :reporter, :forbidden
          it_behaves_like 'rejects package tags access', :guest, :forbidden
        end

        context 'with unauthenticated user' do
          it_behaves_like 'rejects package tags access', :no_type, :unauthorized
        end
      end
    end
  end

  def expect_a_valid_package_response
    expect(response).to have_gitlab_http_status(:ok)
    expect(response.media_type).to eq('application/json')
    expect(response).to match_response_schema('public_api/v4/packages/npm_package')
    expect(json_response['name']).to eq(package.name)
    expect(json_response['versions'][package.version]).to match_schema('public_api/v4/packages/npm_package_version')
    ::Packages::Npm::PackagePresenter::NPM_VALID_DEPENDENCY_TYPES.each do |dependency_type|
      expect(json_response.dig('versions', package.version, dependency_type.to_s)).to be_any
    end
    expect(json_response['dist-tags']).to match_schema('public_api/v4/packages/npm_package_tags')
  end
end
