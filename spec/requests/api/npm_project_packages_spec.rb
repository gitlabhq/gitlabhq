# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::NpmProjectPackages, feature_category: :package_registry do
  include ExclusiveLeaseHelpers

  include_context 'npm api setup'

  shared_examples 'accept get request on private project with access to package registry for everyone' do
    subject { get(url) }

    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
    end

    it_behaves_like 'returning response status', :ok
  end

  describe 'GET /api/v4/projects/:id/packages/npm/*package_name' do
    let(:url) { api("/projects/#{project.id}/packages/npm/#{package_name}") }

    it_behaves_like 'handling get metadata requests', scope: :project
    it_behaves_like 'accept get request on private project with access to package registry for everyone'
    it_behaves_like 'rejects invalid package names' do
      subject { get(url) }
    end

    context 'when metadata cache exists', :aggregate_failures do
      let!(:npm_metadata_cache) { create(:npm_metadata_cache, package_name: package.name, project_id: project.id) }
      let(:metadata) { Gitlab::Json.parse(npm_metadata_cache.file.read.gsub('dist_tags', 'dist-tags')) }

      subject { get(url) }

      before do
        project.add_developer(user)
      end

      it 'returns response from metadata cache' do
        expect(Packages::Npm::GenerateMetadataService).not_to receive(:new)
        expect(Packages::Npm::MetadataCache).to receive(:find_by_package_name_and_project_id)
          .with(package.name, project.id).and_call_original

        subject

        expect(json_response).to eq(metadata)
      end

      it 'bumps last_downloaded_at of metadata cache' do
        expect { subject }
          .to change { npm_metadata_cache.reload.last_downloaded_at }.from(nil).to(instance_of(ActiveSupport::TimeWithZone))
      end

      it_behaves_like 'does not enqueue a worker to sync a metadata cache'

      context 'when metadata cache file does not exist' do
        before do
          FileUtils.rm_rf(npm_metadata_cache.file.path)
        end

        it_behaves_like 'generates metadata response "on-the-fly"'
        it_behaves_like 'enqueue a worker to sync a metadata cache'
      end
    end

    context 'when user is not authorized after exception was raised' do
      let(:exception) { Rack::Timeout::RequestTimeoutException.new('Request ran for longer than 60000ms') }

      subject { get(url) }

      before do
        project.add_developer(user)
      end

      it 'correctly reports an exception', :aggregate_failures do
        allow_next_instance_of(Packages::Npm::GenerateMetadataService) do |instance|
          allow(instance).to receive(:execute).and_raise(exception)
        end

        allow(Gitlab::Auth::UniqueIpsLimiter).to receive(:limit_user!)
          .and_invoke(-> { nil }, -> { raise Gitlab::Auth::UnauthorizedError })

        subject
      end
    end
  end

  describe 'GET /api/v4/projects/:id/packages/npm/-/package/*package_name/dist-tags' do
    let(:url) { api("/projects/#{project.id}/packages/npm/-/package/#{package_name}/dist-tags") }

    it_behaves_like 'handling get dist tags requests', scope: :project
    it_behaves_like 'accept get request on private project with access to package registry for everyone'
  end

  describe 'PUT /api/v4/projects/:id/packages/npm/-/package/*package_name/dist-tags/:tag' do
    it_behaves_like 'handling create dist tag requests', scope: :project do
      let(:url) { api("/projects/#{project.id}/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }
    end

    it_behaves_like 'enqueue a worker to sync a metadata cache' do
      let(:tag_name) { 'test' }
      let(:url) { api("/projects/#{project.id}/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }
      let(:env) { { 'api.request.body': package.version } }
      let(:headers) { build_token_auth_header(personal_access_token.token) }

      subject { put(url, env: env, headers: headers) }
    end
  end

  describe 'DELETE /api/v4/projects/:id/packages/npm/-/package/*package_name/dist-tags/:tag' do
    it_behaves_like 'handling delete dist tag requests', scope: :project do
      let(:url) { api("/projects/#{project.id}/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }
    end

    it_behaves_like 'enqueue a worker to sync a metadata cache' do
      let_it_be(:package_tag) { create(:packages_tag, package: package) }

      let(:tag_name) { package_tag.name }
      let(:url) { api("/projects/#{project.id}/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }
      let(:headers) { build_token_auth_header(personal_access_token.token) }

      subject { delete(url, headers: headers) }
    end
  end

  describe 'POST /api/v4/projects/:id/packages/npm/-/npm/v1/security/advisories/bulk' do
    it_behaves_like 'handling audit request', path: 'advisories/bulk', scope: :project do
      let(:url) { api("/projects/#{project.id}/packages/npm/-/npm/v1/security/advisories/bulk") }
    end
  end

  describe 'POST /api/v4/projects/:id/packages/npm/-/npm/v1/security/audits/quick' do
    it_behaves_like 'handling audit request', path: 'audits/quick', scope: :project do
      let(:url) { api("/projects/#{project.id}/packages/npm/-/npm/v1/security/audits/quick") }
    end
  end

  describe 'GET /api/v4/projects/:id/packages/npm/*package_name/-/*file_name' do
    let(:package_file) { package.package_files.first }

    let(:headers) { {} }
    let(:url) { api("/projects/#{project.id}/packages/npm/#{package.name}/-/#{package_file.file_name}") }

    subject(:request) { get(url, headers: headers) }

    before do
      project.add_developer(user)
    end

    shared_examples 'successfully downloads the file' do
      it 'returns the file' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end
    end

    shared_examples 'a package file that requires auth' do
      it 'denies download with no token' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'with access token' do
        let(:headers) { build_token_auth_header(token.plaintext_token) }

        it_behaves_like 'successfully downloads the file'
        it_behaves_like 'a package tracking event', 'API::NpmPackages', 'pull_package'
        it_behaves_like 'bumping the package last downloaded at field'
      end

      context 'with job token' do
        let(:headers) { build_token_auth_header(job.token) }

        it_behaves_like 'successfully downloads the file'
        it_behaves_like 'a package tracking event', 'API::NpmPackages', 'pull_package'
        it_behaves_like 'bumping the package last downloaded at field'
      end
    end

    context 'a public project' do
      it_behaves_like 'successfully downloads the file'
      it_behaves_like 'a package tracking event', 'API::NpmPackages', 'pull_package'
      it_behaves_like 'bumping the package last downloaded at field'

      context 'with a job token for a different user' do
        let_it_be(:other_user) { create(:user) }
        let_it_be_with_reload(:other_job) { create(:ci_build, :running, user: other_user, project: project) }

        let(:headers) { build_token_auth_header(other_job.token) }

        it_behaves_like 'successfully downloads the file'
      end
    end

    context 'private project' do
      let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace, user: user, property: 'i_package_npm_user' } }

      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it_behaves_like 'enforcing job token policies', :read_packages do
        let(:headers) { build_token_auth_header(target_job.token) }
      end

      it_behaves_like 'a package file that requires auth'

      context 'when allow_guest_plus_roles_to_pull_packages is disabled' do
        before do
          stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
        end

        context 'with guest' do
          let(:headers) { build_token_auth_header(token.plaintext_token) }

          it 'denies download when not enough permissions' do
            project.add_guest(user)

            subject

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end

      context 'with access to package registry for everyone' do
        before do
          project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
        end

        it_behaves_like 'successfully downloads the file'
      end
    end

    context 'internal project' do
      let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace, user: user, property: 'i_package_npm_user' } }

      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      end

      it_behaves_like 'a package file that requires auth'

      context 'with a job token for a different user' do
        let_it_be(:other_user) { create(:user) }
        let_it_be_with_reload(:other_job) { create(:ci_build, :running, user: other_user, project: project) }

        let(:headers) { build_token_auth_header(other_job.token) }

        it_behaves_like 'successfully downloads the file'
      end
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/npm/:package_name' do
    before do
      project.add_developer(user)
    end

    subject(:upload_package_with_token) { upload_with_token(package_name, params) }

    shared_examples 'handling invalid record with 400 error' do |error_message|
      it 'handles an ActiveRecord::RecordInvalid exception with 400 error' do
        expect { upload_package_with_token }
          .not_to change { project.packages.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq(error_message)
      end
    end

    context 'when params are correct' do
      context 'invalid package record' do
        context 'invalid package name' do
          let(:package_name) { "@#{group.path}/my_inv@@lid_package_name" }
          let(:params) { upload_params(package_name: package_name) }

          it_behaves_like 'handling invalid record with 400 error', "Validation failed: Name is invalid, Name #{Gitlab::Regex.npm_package_name_regex_message}"
          it_behaves_like 'not a package tracking event'
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

            it_behaves_like 'handling invalid record with 400 error', "Validation failed: Version #{Gitlab::Regex.semver_regex_message}"
            it_behaves_like 'not a package tracking event'
          end
        end

        context 'invalid package attachment data' do
          let(:package_name) { "@#{group.path}/my_package_name" }
          let(:params) { upload_params(package_name: package_name, file: 'npm/payload_with_empty_attachment.json') }

          it_behaves_like 'handling invalid record with 400 error', 'Attachment data is empty.'
          it_behaves_like 'not a package tracking event'
        end
      end

      context 'valid package params' do
        let_it_be(:version) { '1.2.3' }

        let(:params) { upload_params(package_name: package_name, package_version: version) }
        let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace, user: user, property: 'i_package_npm_user' } }

        shared_examples 'handling upload with different authentications' do
          context 'with access token' do
            it_behaves_like 'a package tracking event', 'API::NpmPackages', 'push_package'

            it_behaves_like 'a successful package creation'
          end

          it 'creates npm package with file with job token' do
            expect { upload_with_job_token(package_name, params) }
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
              upload_package_with_token

              expect(response).to have_gitlab_http_status(:ok)
              expect(project.reload.packages.find(json_response['id']).last_build_info.pipeline).to eq job.pipeline
            end
          end
        end

        shared_examples 'uploading the package' do
          it 'uploads the package' do
            expect { upload_package_with_token }
              .to change { project.packages.count }.by(1)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'with a scoped name' do
          let(:package_name) { "@#{group.path}/my_package_name" }

          it_behaves_like 'enforcing job token policies', :admin_packages do
            let(:request) { upload_package(package_name, params.merge(job_token: target_job.token)) }
          end

          it_behaves_like 'handling upload with different authentications'
        end

        context 'with any scoped name' do
          let(:package_name) { "@any_scope/my_package_name" }

          it_behaves_like 'handling upload with different authentications'
        end

        context 'with an unscoped name' do
          let(:package_name) { "my_unscoped_package_name" }

          it_behaves_like 'handling upload with different authentications'
        end

        it_behaves_like 'does not enqueue a worker to sync a metadata cache'

        context 'with an existing package' do
          let_it_be(:second_project) { create(:project, namespace: namespace) }

          context 'following the naming convention' do
            let_it_be(:second_package) { create(:npm_package, project: second_project, name: "@#{group.path}/test", version: version) }

            let(:package_name) { "@#{group.path}/test" }

            it_behaves_like 'handling invalid record with 400 error', 'Validation failed: Package already exists'
            it_behaves_like 'not a package tracking event'

            context 'with a new version' do
              let_it_be(:version) { '4.5.6' }

              it_behaves_like 'uploading the package'
            end
          end

          context 'not following the naming convention' do
            let_it_be(:second_package) { create(:npm_package, project: second_project, name: "@any_scope/test", version: version) }

            let(:package_name) { "@any_scope/test" }

            it_behaves_like 'uploading the package'
          end
        end
      end

      context 'package creation fails' do
        let(:package_name) { "@#{group.path}/my_package_name" }
        let(:params) { upload_params(package_name: package_name) }

        before do
          create(:npm_package, project: project, version: '1.0.1', name: "@#{group.path}/my_package_name")
        end

        it_behaves_like 'not a package tracking event'

        it 'returns an error if the package already exists' do
          expect { upload_package_with_token }
            .not_to change { project.packages.count }

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['error']).to eq('Package already exists.')
        end

        it_behaves_like 'does not enqueue a worker to sync a metadata cache' do
          subject { upload_package_with_token }
        end
      end

      context 'with dependencies' do
        let(:package_name) { "@#{group.path}/my_package_name" }
        let(:params) { upload_params(package_name: package_name, file: 'npm/payload_with_duplicated_packages.json') }

        it 'creates npm package with file and dependencies' do
          expect { upload_package_with_token }
            .to change { project.packages.count }.by(1)
            .and change { Packages::PackageFile.count }.by(1)
            .and change { Packages::Dependency.count }.by(4)
            .and change { Packages::DependencyLink.count }.by(6)

          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'with existing dependencies' do
          before do
            name = "@#{group.path}/existing_package"
            upload_with_token(name, upload_params(package_name: name, file: 'npm/payload_with_duplicated_packages.json'))
          end

          it 'reuses them' do
            expect { upload_package_with_token }
              .to change { project.packages.count }.by(1)
              .and change { Packages::PackageFile.count }.by(1)
              .and not_change { Packages::Dependency.count }
              .and change { Packages::DependencyLink.count }.by(6)
          end
        end
      end

      context 'when the lease to create a package is already taken' do
        let(:version) { '1.0.1' }
        let(:params) { upload_params(package_name: package_name, package_version: version) }
        let(:lease_key) { "packages:npm:create_package_service:packages:#{project.id}_#{package_name}_#{version}" }

        before do
          stub_exclusive_lease_taken(lease_key, timeout: Packages::Npm::CreatePackageService::DEFAULT_LEASE_TIMEOUT)
        end

        it_behaves_like 'not a package tracking event'

        it 'returns an error' do
          expect { upload_package_with_token }
            .not_to change { project.packages.count }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.body).to include('Could not obtain package lease. Please try again.')
          expect(json_response['error']).to eq('Could not obtain package lease. Please try again.')
        end
      end

      context 'with a too large metadata structure' do
        let(:package_name) { "@#{group.path}/my_package_name" }

        ::Packages::Npm::CreatePackageService::PACKAGE_JSON_NOT_ALLOWED_FIELDS.each do |field|
          context "when a large value for #{field} is set" do
            let(:params) do
              upload_params(package_name: package_name, package_version: '1.2.3').tap do |h|
                h['versions']['1.2.3'][field] = 'test' * 10000
              end
            end

            it_behaves_like 'a successful package creation'
          end
        end

        context 'when the large field is not one of the ignored fields' do
          let(:params) do
            upload_params(package_name: package_name, package_version: '1.2.3').tap do |h|
              h['versions']['1.2.3']['test'] = 'test' * 10000
            end
          end

          it_behaves_like 'handling invalid record with 400 error', 'Validation failed: Package json structure is too large. Maximum size is 20000 characters'
          it_behaves_like 'not a package tracking event'
        end
      end

      context 'when the Npm-Command in headers is deprecate' do
        let(:package_name) { "@#{group.path}/my_package_name" }
        let(:headers) { build_token_auth_header(token.plaintext_token).merge('Npm-Command' => 'deprecate') }
        let(:params) do
          {
            'id' => project.id.to_s,
            'package_name' => package_name,
            'versions' => {
              '1.0.1' => {
                'name' => package_name,
                'deprecated' => 'This version is deprecated'
              },
              '1.0.2' => {
                'name' => package_name
              }
            }
          }
        end

        subject(:request) { put api("/projects/#{project.id}/packages/npm/#{package_name.sub('/', '%2f')}"), params: params, headers: headers }

        context 'when the user is not authorized to deprecate the package' do
          before do
            project.add_developer(user)
          end

          it 'does not enqueue the deprecate npm packages worker' do
            expect(::Packages::Npm::DeprecatePackageWorker).not_to receive(:perform_async)

            request

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when the user is authorized to deprecate the package' do
          let(:filtered_params) do
            params.deep_dup.tap { |p| p['versions'].slice!('1.0.1') }
          end

          before do
            project.add_maintainer(user)
          end

          it 'enqueues the deprecate npm packages worker with the correct arguments' do
            expect(::Packages::Npm::DeprecatePackageWorker).to receive(:perform_async).with(project.id, filtered_params)

            request

            expect(response).to have_gitlab_http_status(:ok)
          end

          context 'when no package versions contain `deprecate` attribute' do
            let(:params) do
              super().tap { |p| p['versions'].slice!('1.0.2') }
            end

            it 'does not enqueue the deprecate npm packages worker' do
              expect(::Packages::Npm::DeprecatePackageWorker).not_to receive(:perform_async)

              request

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(response.parsed_body).to eq(
                'message' => '400 Bad request - "package versions to deprecate" not given',
                'error' => '"package versions to deprecate" not given'
              )
            end
          end
        end
      end
    end

    def upload_package(package_name, params = {})
      token = params.delete(:access_token) || params.delete(:job_token)
      headers = build_token_auth_header(token)
      put api("/projects/#{project.id}/packages/npm/#{package_name.sub('/', '%2f')}"), params: params, headers: headers
    end

    def upload_with_token(package_name, params = {})
      upload_package(package_name, params.merge(access_token: token.plaintext_token))
    end

    def upload_with_job_token(package_name, params = {})
      upload_package(package_name, params.merge(job_token: job.token))
    end

    def upload_params(package_name:, package_version: '1.0.1', file: 'npm/payload.json')
      Gitlab::Json.parse(fixture_file("packages/#{file}")
          .gsub('@root/npm-test', package_name)
          .gsub('1.0.1', package_version))
    end
  end
end
