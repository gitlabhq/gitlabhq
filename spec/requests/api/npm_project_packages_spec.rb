# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::NpmProjectPackages, :aggregate_failures, feature_category: :package_registry do
  include ExclusiveLeaseHelpers
  include WorkhorseHelpers

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

    it_behaves_like 'authorizing granular token permissions', :read_npm_package do
      let(:boundary_object) { project }
      let(:request) do
        get api("/projects/#{project.id}/packages/npm/#{package_name}", personal_access_token: pat)
      end

      before do
        project.add_developer(user)
      end
    end

    context 'when metadata cache exists', :aggregate_failures do
      let!(:npm_metadata_cache) { create(:npm_metadata_cache, package_name: package.name, project_id: project.id) }

      subject { get(url) }

      before do
        project.add_developer(user)
      end

      it 'returns response from metadata cache' do
        expect(Packages::Npm::GenerateMetadataService).not_to receive(:new)
        expect(Packages::Npm::MetadataCache).to receive(:find_by_package_name_and_project_id)
          .with(package.name, project.id).and_call_original

        subject

        expect(response.headers['X-Sendfile']).to eq(npm_metadata_cache.file.path)
      end

      it 'bumps last_downloaded_at of metadata cache' do
        expect { subject }
          .to change { npm_metadata_cache.reload.last_downloaded_at }.from(nil).to(instance_of(ActiveSupport::TimeWithZone))
      end

      context 'for head request' do
        it 'does not update last_downloaded_at' do
          expect { head url }.not_to change { npm_metadata_cache.reload.last_downloaded_at }
        end
      end

      it_behaves_like 'does not enqueue a worker to sync a npm metadata cache'

      context 'when metadata cache file does not exist' do
        before do
          FileUtils.rm_rf(npm_metadata_cache.file.path)
        end

        it_behaves_like 'generates metadata response "on-the-fly"'
        it_behaves_like 'enqueue a worker to sync a npm metadata cache'
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

    it_behaves_like 'updating personal access token last used' do
      subject { get(url, headers: build_token_auth_header(personal_access_token.token)) }
    end
  end

  describe 'GET /api/v4/projects/:id/packages/npm/-/package/*package_name/dist-tags' do
    let(:url) { api("/projects/#{project.id}/packages/npm/-/package/#{package_name}/dist-tags") }

    it_behaves_like 'handling get dist tags requests', scope: :project
    it_behaves_like 'accept get request on private project with access to package registry for everyone'

    it_behaves_like 'authorizing granular token permissions', :read_npm_package_tag do
      let(:boundary_object) { project }
      let(:request) do
        get api("/projects/#{project.id}/packages/npm/-/package/#{package_name}/dist-tags", personal_access_token: pat)
      end

      before do
        project.add_developer(user)
      end
    end

    it_behaves_like 'updating personal access token last used' do
      subject { get(url, headers: build_token_auth_header(personal_access_token.token)) }
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/npm/-/package/*package_name/dist-tags/:tag' do
    it_behaves_like 'handling create dist tag requests', scope: :project do
      let(:url) { api("/projects/#{project.id}/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }
    end

    it_behaves_like 'authorizing granular token permissions', :create_npm_package_tag do
      let(:tag_name) { 'test' }
      let(:boundary_object) { project }
      let(:request) do
        put api("/projects/#{project.id}/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}",
          personal_access_token: pat), env: { 'api.request.body': package.version }
      end

      before do
        project.add_developer(user)
      end
    end

    it_behaves_like 'enqueue a worker to sync a npm metadata cache' do
      let(:tag_name) { 'test' }
      let(:url) { api("/projects/#{project.id}/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }
      let(:env) { { 'api.request.body': package.version } }
      let(:headers) { build_token_auth_header(personal_access_token.token) }

      subject { put(url, env: env, headers: headers) }
    end

    it_behaves_like 'updating personal access token last used' do
      let(:tag_name) { 'test' }
      let(:url) { api("/projects/#{project.id}/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }

      subject { put(url, headers: build_token_auth_header(personal_access_token.token)) }
    end
  end

  describe 'DELETE /api/v4/projects/:id/packages/npm/-/package/*package_name/dist-tags/:tag' do
    it_behaves_like 'handling delete dist tag requests', scope: :project do
      let(:url) { api("/projects/#{project.id}/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }
    end

    it_behaves_like 'authorizing granular token permissions', :delete_npm_package_tag do
      let_it_be(:package_tag) { create(:packages_tag, package: package) }

      let(:tag_name) { package_tag.name }
      let(:boundary_object) { project }
      let(:request) do
        delete api("/projects/#{project.id}/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}",
          personal_access_token: pat)
      end

      before do
        project.add_maintainer(user)
      end
    end

    it_behaves_like 'enqueue a worker to sync a npm metadata cache' do
      let_it_be(:package_tag) { create(:packages_tag, package: package) }

      let(:tag_name) { package_tag.name }
      let(:url) { api("/projects/#{project.id}/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }
      let(:headers) { build_token_auth_header(personal_access_token.token) }

      subject { delete(url, headers: headers) }
    end

    it_behaves_like 'updating personal access token last used' do
      let(:tag_name) { 'test' }
      let(:url) { api("/projects/#{project.id}/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }

      subject { delete(url, headers: build_token_auth_header(personal_access_token.token)) }
    end
  end

  describe 'POST /api/v4/projects/:id/packages/npm/-/npm/v1/security/advisories/bulk' do
    it_behaves_like 'handling audit request', path: 'advisories/bulk', scope: :project do
      let(:url) { api("/projects/#{project.id}/packages/npm/-/npm/v1/security/advisories/bulk") }
    end

    it_behaves_like 'updating personal access token last used' do
      let(:url) { api("/projects/#{project.id}/packages/npm/-/npm/v1/security/advisories/bulk") }

      subject { post(url, headers: build_token_auth_header(personal_access_token.token)) }
    end
  end

  describe 'POST /api/v4/projects/:id/packages/npm/-/npm/v1/security/audits/quick' do
    it_behaves_like 'handling audit request', path: 'audits/quick', scope: :project do
      let(:url) { api("/projects/#{project.id}/packages/npm/-/npm/v1/security/audits/quick") }
    end

    it_behaves_like 'updating personal access token last used' do
      let(:url) { api("/projects/#{project.id}/packages/npm/-/npm/v1/security/audits/quick") }

      subject { post(url, headers: build_token_auth_header(personal_access_token.token)) }
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

    it_behaves_like 'authorizing granular token permissions', :download_npm_package do
      let(:boundary_object) { project }
      let(:request) do
        get api("/projects/#{project.id}/packages/npm/#{package.name}/-/#{package_file.file_name}",
          personal_access_token: pat)
      end
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

      it_behaves_like 'enforcing job token policies', :read_packages,
        allow_public_access_for_enabled_project_features: :package_registry do
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

    it_behaves_like 'updating personal access token last used' do
      let(:headers) { build_token_auth_header(personal_access_token.token) }
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/npm/:package_name/authorize' do
    include_context 'workhorse headers'

    let(:encoded_package_name) { package_name.sub('/', '%2f') }
    let(:url) { api("/projects/#{project.id}/packages/npm/#{encoded_package_name}/authorize") }
    let(:headers) { build_token_auth_header(token.plaintext_token) }

    subject(:request) { put url, headers: headers, as: :json }

    it_behaves_like 'authorizing granular token permissions', :authorize_npm_package do
      let(:boundary_object) { project }
      let(:request) do
        put api("/projects/#{project.id}/packages/npm/#{encoded_package_name}/authorize", personal_access_token: pat),
          headers: workhorse_headers, as: :json
      end

      before do
        project.add_developer(user)
      end
    end

    context 'with workhorse headers' do
      let(:headers) { super().merge(workhorse_headers) }

      before do
        project.actual_limits.update!(npm_max_file_size: 1.megabyte)
      end

      context 'with a reporter' do
        before_all do
          project.add_reporter(user)
        end

        it_behaves_like 'returning response status with message', status: :forbidden, message: '403 Forbidden'
      end

      context 'with a developer' do
        before_all do
          project.add_developer(user)
        end

        it 'authorizes the upload' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          expect(json_response).to include(
            'TempPath' => Packages::PackageFileUploader.workhorse_local_upload_path,
            'MaximumSize' => 1.megabyte
          )
          expect(json_response['RemoteObject']).to be_nil
        end
      end

      context 'with a job token' do
        let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }

        let(:headers) { build_token_auth_header(job.token).merge(workhorse_headers) }

        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          project.add_developer(user)
        end

        context 'valid token' do
          it_behaves_like 'returning response status', :success
        end

        context 'with a job token from a different project' do
          let_it_be(:other_project) { create(:project) }
          let_it_be(:other_job) { create(:ci_build, :running, user: user, project: other_project) }

          let(:headers) { build_token_auth_header(other_job.token).merge(workhorse_headers) }

          it_behaves_like 'returning response status', :forbidden
        end
      end
    end

    context 'without workhorse headers' do
      it_behaves_like 'returning response status with message', status: :forbidden, message: '403 Forbidden'
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/npm/:package_name' do
    let(:url) { api("/projects/#{project.id}/packages/npm/#{package_name.sub('/', '%2f')}") }
    let(:headers) { build_token_auth_header(token.plaintext_token) }

    let(:fixture_file_path) { 'npm/payload.json' }
    let(:fixture_file_content) { fixture_file("packages/#{fixture_file_path}").gsub('@root/npm-test', package_name).gsub('1.0.1', package_version) }
    let(:params) { { file: temp_file('test-npm-upload', content: fixture_file_content) } }
    let(:package_name) { "@#{group.path}/my_package_name" }

    let_it_be(:package_version) { '1.0.1' }

    before do
      project.add_developer(user)
    end

    it_behaves_like 'authorizing granular token permissions', :upload_npm_package do
      let(:boundary_object) { project }
      let(:request) do
        workhorse_finalize(
          api("/projects/#{project.id}/packages/npm/#{package_name.sub('/', '%2f')}", personal_access_token: pat),
          method: :put,
          file_key: :file,
          params: params,
          headers: {},
          send_rewritten_field: true
        )
      end
    end

    shared_examples 'handling invalid record with 400 error' do |error_message|
      it 'handles an ActiveRecord::RecordInvalid exception with 400 error' do
        expect { request }.not_to change { ::Packages::Npm::Package.for_projects(project).count }
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq(error_message)
      end
    end

    subject(:request) do
      workhorse_finalize(
        url,
        method: :put,
        file_key: :file,
        params: params,
        headers: headers,
        send_rewritten_field: true
      )
    end

    context 'when params are correct' do
      context 'invalid package record' do
        context 'invalid package name' do
          let(:package_name) { "@#{group.path}/my_inv@@lid_package_name" }

          it_behaves_like 'handling invalid record with 400 error', "Validation failed: Name #{Gitlab::Regex.npm_package_name_regex_message}"
          it_behaves_like 'not a package tracking event'
        end
      end

      context 'valid package params' do
        let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace, user: user, property: 'i_package_npm_user' } }

        shared_examples 'handling upload with different authentications' do
          context 'with access token' do
            it_behaves_like 'a package tracking event', 'API::NpmPackages', 'push_package'
            it_behaves_like 'a successful package creation'
          end

          context 'with a job token' do
            let(:headers) { build_token_auth_header(job.token) }

            it_behaves_like 'a successful package creation'

            it 'links the correct pipeline' do
              request

              expect(response).to have_gitlab_http_status(:ok)
              expect(project.reload.packages.find(json_response['id']).last_build_info.pipeline).to eq job.pipeline
            end
          end
        end

        shared_examples 'uploading the package' do
          it 'uploads the package' do
            expect { request }.to change { ::Packages::Npm::Package.for_projects(project).count }.by(1)
            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'with a scoped name' do
          it_behaves_like 'enforcing job token policies', :admin_packages do
            let(:headers) { build_token_auth_header(target_job.token) }
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
      end

      context 'when the Npm-Command in headers is deprecate' do
        let(:headers) { super().merge('Npm-Command' => 'deprecate') }
        let(:fixture_file_path) { 'npm/deprecate_payload.json' }

        context 'when the user is not authorized to deprecate the package' do
          before do
            project.add_developer(user)
          end

          it 'does not create a temporary package' do
            expect(::Packages::Npm::CreateTemporaryPackageService).not_to receive(:new)

            request

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when the user is authorized to deprecate the package' do
          before do
            project.add_maintainer(user)
          end

          it 'creates a temporary package and enqueues the extract package file worker' do
            expect(::Packages::Npm::ProcessTemporaryPackageFileWorker).to receive(:perform_async)

            expect { request }
              .to change { ::Packages::Npm::Package.for_projects(project).count }.by(1)
              .and change { ::Packages::PackageFile.count }.by(1)

            package = ::Packages::Npm::Package.last

            expect(package.name).to eq(package_name)
            expect(package.version).to match(/^0\.0\.0-.+$/)
            expect(package.package_files.first.file.read).to eq(fixture_file_content)
            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end

    context 'when params are invalid' do
      let(:params) { {} }

      it_behaves_like 'returning response status with error', status: :bad_request, error: 'file is missing'
    end

    def temp_file(filename, content:)
      upload_path = ::Packages::Npm::PackageFileUploader.workhorse_local_upload_path
      file_path = "#{upload_path}/#{filename}"

      FileUtils.mkdir_p(upload_path)
      content ||= ''
      File.write(file_path, content)

      UploadedFile.new(file_path, filename: File.basename(file_path))
    end
  end
end
