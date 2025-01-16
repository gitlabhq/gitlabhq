# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::MlModelPackages, feature_category: :mlops do
  include HttpBasicAuthHelpers
  include PackagesManagerApiSpecHelpers
  include WorkhorseHelpers
  using RSpec::Parameterized::TableSyntax

  include_context 'workhorse headers'

  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:personal_access_token) { create(:personal_access_token) }
  let_it_be(:job) { create(:ci_build, :running, user: personal_access_token.user, project: project) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }
  let_it_be(:another_project, reload: true) { create(:project) }
  let_it_be(:model) { create(:ml_models, user: project.owner, project: project) }
  let_it_be(:model_version) { create(:ml_model_versions, :with_package, model: model, version: '0.1.0') }
  let(:snowplow_gitlab_standard_context) do
    { user: user, project: project, namespace: project.namespace, property: 'i_package_ml_model_user' }
  end

  let(:tokens) do
    {
      personal_access_token: personal_access_token.token,
      deploy_token: deploy_token.token,
      job_token: job.token
    }
  end

  let(:user) { personal_access_token.user }
  let(:user_role) { :developer }
  let(:member) { true }
  let(:ci_build) { create(:ci_build, :running, user: user, project: project) }
  let(:project_to_enable_ff) { project }
  let(:headers) { {} }

  shared_context 'ml model authorize permissions table' do # rubocop:disable RSpec/ContextWording
    # rubocop:disable Metrics/AbcSize
    # :valid_token, :user_role, :visibility, :member, :token_type, :expected_status
    def authorize_permissions_table
      false | :developer  | :private | true  | :job_token             | :unauthorized
      false | :developer  | :private | true  | :personal_access_token | :unauthorized
      false | :developer  | :public  | true  | :job_token             | :unauthorized
      false | :developer  | :public  | true  | :personal_access_token | :unauthorized
      false | :guest      | :private | true  | :job_token             | :unauthorized
      false | :guest      | :private | true  | :personal_access_token | :unauthorized
      false | :guest      | :public  | true  | :job_token             | :unauthorized
      false | :guest      | :public  | true  | :personal_access_token | :unauthorized
      true  | :anonymous  | :private | false | :personal_access_token | :unauthorized
      true  | :anonymous  | :public  | false | :personal_access_token | :unauthorized
      true  | :developer  | :private | true  | :job_token             | :success
      true  | :developer  | :private | true  | :personal_access_token | :success
      true  | :developer  | :public  | true  | :job_token             | :success
      true  | :developer  | :public  | true  | :personal_access_token | :success
      true  | :guest      | :private | true  | :job_token             | :forbidden
      true  | :guest      | :private | true  | :personal_access_token | :forbidden
      true  | :guest      | :public  | true  | :job_token             | :forbidden
      true  | :guest      | :public  | true  | :personal_access_token | :forbidden
      true  | :reporter   | :private | true  | :job_token             | :forbidden
      true  | :reporter   | :private | true  | :personal_access_token | :forbidden
      true  | :reporter   | :public  | true  | :job_token             | :forbidden
      true  | :reporter   | :public  | true  | :personal_access_token | :forbidden
    end

    # ::valid_token, :user_role, visibility, :member, :token_type, :expected_status
    def download_permissions_tables
      false |  :developer  | :private | true  | :job_token             | :unauthorized
      false |  :developer  | :private | true  | :personal_access_token | :unauthorized
      false |  :developer  | :public  | true  | :job_token             | :unauthorized
      false |  :developer  | :public  | true  | :personal_access_token | :unauthorized
      false |  :guest      | :private | true  | :job_token             | :unauthorized
      false |  :guest      | :private | true  | :personal_access_token | :unauthorized
      false |  :guest      | :public  | true  | :job_token             | :unauthorized
      false |  :guest      | :public  | true  | :personal_access_token | :unauthorized
      true  |  :anonymous  | :private | false | :personal_access_token | :not_found
      true  |  :anonymous  | :public  | false | :personal_access_token | :success
      true  |  :developer  | :private | true  | :job_token             | :success
      true  |  :developer  | :private | true  | :personal_access_token | :success
      true  |  :developer  | :public  | true  | :job_token             | :success
      true  |  :developer  | :public  | true  | :personal_access_token | :success
      true  |  :guest      | :private | true  | :job_token             | :success
      true  |  :guest      | :private | true  | :personal_access_token | :success
      true  |  :guest      | :public  | true  | :job_token             | :success
      true  |  :guest      | :public  | true  | :personal_access_token | :success
      true  |  :reporter   | :private | true  | :job_token             | :success
      true  |  :reporter   | :private | true  | :personal_access_token | :success
      true  |  :reporter   | :public  | true  | :job_token             | :success
      true  |  :reporter   | :public  | true  | :personal_access_token | :success
    end
    # rubocop:enable Metrics/AbcSize
  end

  before do
    project.send("add_#{user_role}", user) if member && user_role != :anonymous
  end

  describe 'PUT /api/v4/projects/:id/packages/ml_models/:model_version_id/files/(*path)/:file_name/authorize' do
    include_context 'ml model authorize permissions table'

    let_it_be(:file_name) { 'model.md5' }

    let(:token) { tokens[:personal_access_token] }
    let(:user_headers) { { 'Authorization' => "Bearer #{token}" } }
    let(:headers) { user_headers.merge(workhorse_headers) }
    let(:request) { authorize_upload_file(headers) }
    let(:model_name) { model_version.name }
    let(:version) { model_version.version }

    let(:file_path) { '' }
    let(:full_path) { "#{file_path}#{file_name}" }

    subject(:api_response) do
      url = "/projects/#{project.id}/packages/ml_models/#{model_version.id}/files/#{full_path}/authorize"

      put api(url), headers: headers

      response
    end

    context 'when file has path' do
      let(:file_path) { 'my_dir' }

      it { is_expected.to have_gitlab_http_status(:success) }
    end

    describe 'user access' do
      where(:valid_token, :user_role, :visibility, :member, :token_type, :expected_status) do
        authorize_permissions_table
      end

      with_them do
        let(:token) { valid_token ? tokens[token_type] : 'invalid-token123' }
        let(:user_headers) { user_role == :anonymous ? {} : { 'Authorization' => "Bearer #{token}" } }

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility.to_s))
        end

        context 'when file does not have path' do
          it { is_expected.to have_gitlab_http_status(expected_status) }
        end
      end

      it_behaves_like 'Endpoint not found if read_model_registry not available'
    end

    describe 'application security' do
      context 'when path has back directory' do
        let(:file_name) { '../.ssh%2fauthorized_keys' }

        it 'rejects malicious request' do
          is_expected.to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when path has invalid characters' do
        let(:file_name) { '%2e%2e%2f.ssh%2fauthorized_keys' }

        it 'rejects malicious request' do
          is_expected.to have_gitlab_http_status(:bad_request)
        end
      end
    end
  end

  # rubocop:disable RSpec/MultipleMemoizedHelpers -- This test requires many different variables to be set
  describe 'PUT /api/v4/projects/:id/packages/ml_models/:model_version_id/(*path)/files/:file_name' do
    include_context 'ml model authorize permissions table'

    let_it_be(:file_name) { 'model.md5' }

    let(:token) { tokens[:personal_access_token] }
    let(:user_headers) { { 'Authorization' => "Bearer #{token}" } }
    let(:headers) { user_headers.merge(workhorse_headers) }
    let(:params) { { file: temp_file(file_name) } }
    let(:file_key) { :file }
    let(:send_rewritten_field) { true }
    let(:version_id) { model_version.id }

    let(:file_path) { '' }
    let(:full_path) { "#{file_path}#{file_name}" }
    let(:saved_file_name) { file_name }

    subject(:api_response) do
      url = "/projects/#{project.id}/packages/ml_models/#{version_id}/files/#{full_path}"

      workhorse_finalize(
        api(url),
        method: :put,
        file_key: file_key,
        params: params,
        headers: headers,
        send_rewritten_field: send_rewritten_field
      )

      response
    end

    describe  'upload' do
      context 'when file does not have path' do
        it_behaves_like 'process ml model package upload'
      end

      context 'when file has path' do
        let(:file_path) { 'my_dir/' }
        let(:saved_file_name) { "my_dir%2F#{file_name}" }

        it_behaves_like 'process ml model package upload'
      end

      context 'when file is for candidate' do
        let_it_be(:candidate) do
          create(:ml_candidates, project: model.project, experiment: model.default_experiment, model_version: nil)
        end

        let(:version_id) { "candidate:#{candidate.iid}" }

        it 'creates package files', :aggregate_failures do
          expect { api_response }
            .to change { Packages::PackageFile.count }.by(1)
                                                      .and change { Packages::Package.count }.by(1)

          expect(api_response).to have_gitlab_http_status(:created)

          package_file = project.packages.last.package_files.reload.last
          expect(package_file.file_name).to eq(saved_file_name)
          expect(package_file.package.name).to eq(model.name)
          expect(package_file.package.version).to eq("candidate_#{candidate.iid}")
        end

        context 'when candidate does not exist' do
          let(:version_id) { "candidate:#{non_existing_record_id}" }

          it { is_expected.to have_gitlab_http_status(:not_found) }
        end
      end

      it_behaves_like 'Not found when model version does not exist'
    end

    describe 'user access' do
      where(:valid_token, :user_role, :visibility, :member, :token_type, :expected_status) do
        authorize_permissions_table
      end

      with_them do
        let(:token) { valid_token ? tokens[token_type] : 'invalid-token123' }
        let(:user_headers) { user_role == :anonymous ? {} : { 'Authorization' => "Bearer #{token}" } }

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility.to_s))
        end

        it { is_expected.to have_gitlab_http_status(expected_status) }
      end

      it_behaves_like 'Endpoint not found if read_model_registry not available'
      it_behaves_like 'Endpoint not found if write_model_registry not available'
    end
  end

  describe 'GET /api/v4/projects/:project_id/packages/ml_models/:model_version_id/files/(*path)/:file_name' do
    include_context 'ml model authorize permissions table'

    let_it_be(:file_name) { Addressable::URI.escape('Mo_de-l v12.md5') }
    let_it_be(:package) { model_version.package }
    let_it_be(:package_file_1) { create(:package_file, :generic, package: package, file_name: file_name) }
    let_it_be(:package_file_2) { create(:package_file, :generic, package: package, file_name: "my_dir%2F#{file_name}") }

    let(:file_path) { '' }
    let(:full_path) { "#{file_path}#{file_name}" }
    let(:saved_file_name) { file_name }

    let(:version_id) { model_version.id }

    let(:token) { tokens[:personal_access_token] }
    let(:user_headers) { { 'Authorization' => "Bearer #{token}" } }
    let(:headers) { user_headers.merge(workhorse_headers) }

    subject(:api_response) do
      url = "/projects/#{project.id}/packages/ml_models/#{version_id}/files/#{full_path}"

      get api(url), headers: headers

      response
    end

    describe 'download' do
      it_behaves_like 'process ml model package download'

      context 'when file has path' do
        let(:file_path) { 'my_dir/' }

        it_behaves_like 'process ml model package download'
      end

      it_behaves_like 'Not found when model version does not exist'
    end

    describe 'user access' do
      where(:valid_token, :user_role, :visibility, :member, :token_type, :expected_status) do
        download_permissions_tables
      end

      with_them do
        let(:token) { valid_token ? tokens[token_type] : 'invalid-token123' }
        let(:user_headers) { user_role == :anonymous ? {} : { 'Authorization' => "Bearer #{token}" } }

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility.to_s))
        end

        it { is_expected.to have_gitlab_http_status(expected_status) }
      end

      it_behaves_like 'Endpoint not found if read_model_registry not available'
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
