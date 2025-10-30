# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::HelmPackages, feature_category: :package_registry do
  include_context 'helm api setup'

  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:project) { create(:project, :public) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true, projects: [project]) }
  let_it_be(:package) { create(:helm_package, project: project, without_package_files: true) }
  let_it_be(:package_file1) { create(:helm_package_file, package: package) }
  let_it_be(:package_file2) { create(:helm_package_file, package: package) }
  let_it_be(:package2) { create(:helm_package, project: project, without_package_files: true) }
  let_it_be(:package2_file1) { create(:helm_package_file, package: package2, file_sha256: 'file2', file_name: 'filename2.tgz', description: 'hello from stable channel') }
  let_it_be(:package2_file2) { create(:helm_package_file, package: package2, file_sha256: 'file2', file_name: 'filename2.tgz', channel: 'test', description: 'hello from test channel') }
  let_it_be(:other_package) { create(:npm_package, project: project) }
  let(:expect_metadatum) { package2_file1.helm_file_metadatum }

  let(:snowplow_gitlab_standard_context) { snowplow_context }

  def snowplow_context(user_role: :developer)
    if user_role == :anonymous
      { project: project, namespace: project.namespace, property: 'i_package_helm_user' }
    else
      { project: project, namespace: project.namespace, property: 'i_package_helm_user', user: user }
    end
  end

  describe 'GET /api/v4/projects/:id/packages/helm/:channel/index.yaml' do
    subject(:api_request) { get api(url) }

    let(:project_id) { project.id }
    let(:channel) { 'stable' }
    let(:url) { "/projects/#{project_id}/packages/helm/#{channel}/index.yaml" }

    it 'enqueue a worker to sync a helm metadata cache' do
      allow(Packages::Helm::CreateMetadataCacheWorker).to receive(:bulk_perform_async_with_contexts)

      api_request
      expect(Packages::Helm::CreateMetadataCacheWorker)
        .to have_received(:bulk_perform_async_with_contexts) do |metadata, arguments_proc:, context_proc:|
          expect(metadata.map(&:channel)).to match_array([channel])

          expect(arguments_proc.call(expect_metadatum)).to eq([project_id, channel])
          expect(context_proc.call(expect_metadatum)).to eq(project: project, user: nil)
        end
    end

    context 'with a project id' do
      it_behaves_like 'handling helm chart index requests'
    end

    context 'with an url encoded project id' do
      let(:project_id) { ERB::Util.url_encode(project.full_path) }

      it_behaves_like 'handling helm chart index requests'
    end

    context 'with dot in channel' do
      let(:channel) { 'with.dot' }

      before do
        project.update!(visibility: 'public')
      end

      it_behaves_like 'returning response status', :success
    end

    context 'when helm metadata has appVersion' do
      where(:app_version, :expected_app_version) do
        '4852e000'  | "\"4852e000\""
        '1.0.0'     | "\"1.0.0\""
        'v1.0.0'    | "\"v1.0.0\""
        'master'    | "\"master\""
      end

      with_them do
        before do
          Packages::Helm::FileMetadatum.where(project_id: project_id).update_all(
            metadata: {
              'name' => 'Package Name',
              'version' => '1.0.0',
              'apiVersion' => 'v2',
              'appVersion' => app_version
            }
          )
        end

        it 'returns yaml content with quoted appVersion' do
          api_request

          expect(response.body).to include("appVersion: #{expected_app_version}")
        end
      end
    end

    context 'when metadata cache exists' do
      let_it_be(:channel) { 'stable' }
      let_it_be(:metadata_cache) { create(:helm_metadata_cache, project: project, channel: channel) }

      it 'returns response from metadata cache' do
        expect(metadata_cache).to receive(:file).and_call_original

        api_request

        expect(response.headers['X-Sendfile']).to eq(metadata_cache.file.path)
      end

      it 'updates last_downloaded_at' do
        freeze_time do
          api_request

          metadata_cache.reload
          expect(metadata_cache.last_downloaded_at).to eq(Time.zone.now.utc.strftime('%Y-%m-%dT%H:%M:%S.%NZ'))
        end
      end

      context 'when file is stored in object storage' do
        let(:channel) { 'test' }
        let(:metadata_cache) { create(:helm_metadata_cache, :object_storage, project: project, channel: channel) }

        context 'when direct download enabled' do
          before do
            stub_object_storage_uploader(
              config: Gitlab.config.packages.object_store,
              uploader: Packages::Helm::MetadataCacheUploader,
              proxy_download: false
            )
          end

          it 'returns redirect to object storage URL' do
            expect(metadata_cache.file.file_storage?).to be_falsey
            expect(metadata_cache.file.direct_download_enabled?).to be_truthy

            api_request

            expect(response).to have_gitlab_http_status(:redirect)
            expect(response.headers).to include('Location')
          end
        end

        context 'when direct download disabled' do
          before do
            stub_object_storage_uploader(
              config: Gitlab.config.packages.object_store,
              uploader: Packages::Helm::MetadataCacheUploader,
              proxy_download: true
            )
          end

          it 'returns with Workhorse-Send-Data header' do
            expect(metadata_cache.file.file_storage?).to be_falsey

            api_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.headers).to include('Gitlab-Workhorse-Send-Data')
          end
        end
      end
    end
  end

  describe 'GET /api/v4/projects/:id/packages/helm/:channel/charts/:file_name.tgz' do
    let(:url) { "/projects/#{project.id}/packages/helm/stable/charts/#{package.name}-#{package.version}.tgz" }

    subject { get api(url), headers: headers }

    context 'with valid project' do
      where(:visibility, :user_role, :shared_examples_name, :expected_status) do
        :public  | :guest        | 'process helm download content request'   | :success
        :public  | :not_a_member | 'process helm download content request'   | :success
        :public  | :anonymous    | 'process helm download content request'   | :success
        :private | :reporter     | 'process helm download content request'   | :success
        :private | :guest        | 'process helm download content request'   | :success
        :private | :not_a_member | 'rejects helm packages access'            | :not_found
        :private | :anonymous    | 'rejects helm packages access'            | :unauthorized
      end

      with_them do
        let(:headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, personal_access_token.token) }
        let(:snowplow_gitlab_standard_context) { snowplow_context(user_role: user_role) }

        before do
          project.update!(visibility: visibility.to_s)
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status]
      end
    end

    context 'with access to package registry for everyone' do
      let(:snowplow_gitlab_standard_context) { snowplow_context(user_role: :anonymous) }

      before do
        project.update!(visibility: Gitlab::VisibilityLevel::PRIVATE)
        project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
      end

      it_behaves_like 'process helm download content request', :anonymous, :success
    end

    context 'when an invalid token is passed' do
      let(:headers) { basic_auth_header(user.username, 'wrong') }

      it_behaves_like 'returning response status', :unauthorized
    end

    it_behaves_like 'deploy token for package GET requests'

    context 'when format param is not nil' do
      let(:url) { "/projects/#{project.id}/packages/helm/stable/charts/#{package.name}-#{package.version}.tgz.prov" }

      it_behaves_like 'rejects helm packages access', :maintainer, :not_found, '{"message":"404 Format prov Not Found"}'
    end

    it_behaves_like 'updating personal access token last used' do
      let(:headers) { basic_auth_header(user.username, personal_access_token.token) }
    end
  end

  describe 'POST /api/v4/projects/:id/packages/helm/api/:channel/charts/authorize' do
    include_context 'workhorse headers'

    let(:channel) { 'stable' }
    let(:url) { "/projects/#{project.id}/packages/helm/api/#{channel}/charts/authorize" }
    let(:headers) { {} }

    subject { post api(url), headers: headers }

    context 'with valid project' do
      where(:visibility_level, :user_role, :shared_examples_name, :expected_status) do
        :public  | :developer    | 'process helm workhorse authorization' | :success
        :public  | :reporter     | 'rejects helm packages access'         | :forbidden
        :public  | :not_a_member | 'rejects helm packages access'         | :forbidden
        :public  | :anonymous    | 'rejects helm packages access'         | :unauthorized
        :private | :developer    | 'process helm workhorse authorization' | :success
        :private | :reporter     | 'rejects helm packages access'         | :forbidden
        :private | :not_a_member | 'rejects helm packages access'         | :not_found
        :private | :anonymous    | 'rejects helm packages access'         | :unauthorized
      end

      with_them do
        let(:user_headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, personal_access_token.token) }
        let(:headers) { user_headers.merge(workhorse_headers) }
        let(:snowplow_gitlab_standard_context) { snowplow_context(user_role: user_role) }

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility_level.to_s))
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status]
      end
    end

    context 'when an invalid token is passed' do
      let(:headers) { basic_auth_header(user.username, 'wrong') }

      it_behaves_like 'returning response status', :unauthorized
    end

    it_behaves_like 'deploy token for package uploads'

    it_behaves_like 'job token for package uploads', authorize_endpoint: true, accept_invalid_username: true do
      let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }
    end

    it_behaves_like 'rejects helm access with unknown project id'

    it_behaves_like 'updating personal access token last used' do
      let(:headers) { basic_auth_header(user.username, personal_access_token.token) }
    end
  end

  describe 'POST /api/v4/projects/:id/packages/helm/api/:channel/charts' do
    include_context 'workhorse headers'

    let_it_be(:file_name) { 'package.tgz' }

    let(:channel) { 'stable' }
    let(:url) { "/projects/#{project.id}/packages/helm/api/#{channel}/charts" }
    let(:headers) { {} }
    let(:params) { { chart: temp_file(file_name) } }
    let(:file_key) { :chart }
    let(:send_rewritten_field) { true }

    subject do
      workhorse_finalize(
        api(url),
        method: :post,
        file_key: file_key,
        params: params,
        headers: headers,
        send_rewritten_field: send_rewritten_field
      )
    end

    context 'with valid project' do
      where(:visibility_level, :user_role, :shared_examples_name, :expected_status) do
        :public  | :developer     | 'process helm upload'          | :created
        :public  | :reporter      | 'rejects helm packages access' | :forbidden
        :public  | :not_a_member  | 'rejects helm packages access' | :forbidden
        :public  | :anonymous     | 'rejects helm packages access' | :unauthorized
        :private | :developer     | 'process helm upload'          | :created
        :private | :guest         | 'rejects helm packages access' | :forbidden
        :private | :not_a_member  | 'rejects helm packages access' | :not_found
        :private | :anonymous     | 'rejects helm packages access' | :unauthorized
      end

      with_them do
        let(:user_headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, personal_access_token.token) }
        let(:headers) { user_headers.merge(workhorse_headers) }
        let(:snowplow_gitlab_standard_context) { snowplow_context(user_role: user_role) }

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility_level.to_s))
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status]
      end
    end

    context 'with package protection rule' do
      let_it_be_with_reload(:package_protection_rule) do
        create(:package_protection_rule, package_name_pattern: 'rook-ceph', package_type: :helm, project: project)
      end

      # The helm chart contains the file Chart.yml that defined the name 'rook-ceph' of the helm chart.
      let(:params) { { chart: fixture_file_upload('spec/fixtures/packages/helm/rook-ceph-v1.5.8.tgz') } }

      let(:user_headers) { basic_auth_header(user.username, personal_access_token.token) }
      let(:headers) { user_headers.merge(workhorse_headers) }
      let(:snowplow_gitlab_standard_context) { snowplow_context(user_role: :developer) }

      it_behaves_like 'process helm upload', :developer, :created
    end

    context 'when an invalid token is passed' do
      let(:headers) { basic_auth_header(user.username, 'wrong') }

      it_behaves_like 'returning response status', :unauthorized
    end

    it_behaves_like 'deploy token for package uploads'

    it_behaves_like 'job token for package uploads', accept_invalid_username: true do
      let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }
    end

    it_behaves_like 'rejects helm access with unknown project id'

    context 'file size above maximum limit' do
      let(:headers) { basic_auth_header(deploy_token.username, deploy_token.token).merge(workhorse_headers) }

      before do
        allow_next_instance_of(UploadedFile) do |uploaded_file|
          allow(uploaded_file).to receive(:size).and_return(project.actual_limits.helm_max_file_size + 1)
        end
      end

      it_behaves_like 'returning response status', :bad_request
    end

    it_behaves_like 'updating personal access token last used' do
      let(:headers) { basic_auth_header(user.username, personal_access_token.token) }
    end
  end
end
