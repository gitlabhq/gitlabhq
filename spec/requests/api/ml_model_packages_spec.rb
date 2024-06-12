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

  let_it_be(:tokens) do
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
    # :visibility, :user_role, :member, :token_type, :valid_token, :expected_status
    def authorize_permissions_table
      :public  | :developer  | true  | :personal_access_token | true  | :success
      :public  | :guest      | true  | :personal_access_token | true  | :forbidden
      :public  | :developer  | true  | :personal_access_token | false | :unauthorized
      :public  | :guest      | true  | :personal_access_token | false | :unauthorized
      :public  | :developer  | false | :personal_access_token | true  | :forbidden
      :public  | :guest      | false | :personal_access_token | true  | :forbidden
      :public  | :developer  | false | :personal_access_token | false | :unauthorized
      :public  | :guest      | false | :personal_access_token | false | :unauthorized
      :public  | :anonymous  | false | :personal_access_token | true  | :unauthorized
      :private | :developer  | true  | :personal_access_token | true  | :success
      :private | :guest      | true  | :personal_access_token | true  | :forbidden
      :private | :developer  | true  | :personal_access_token | false | :unauthorized
      :private | :guest      | true  | :personal_access_token | false | :unauthorized
      :private | :developer  | false | :personal_access_token | true  | :not_found
      :private | :guest      | false | :personal_access_token | true  | :not_found
      :private | :developer  | false | :personal_access_token | false | :unauthorized
      :private | :guest      | false | :personal_access_token | false | :unauthorized
      :private | :anonymous  | false | :personal_access_token | true  | :unauthorized
      :public  | :developer  | true  | :job_token             | true  | :success
      :public  | :guest      | true  | :job_token             | true  | :forbidden
      :public  | :developer  | true  | :job_token             | false | :unauthorized
      :public  | :guest      | true  | :job_token             | false | :unauthorized
      :public  | :developer  | false | :job_token             | true  | :forbidden
      :public  | :guest      | false | :job_token             | true  | :forbidden
      :public  | :developer  | false | :job_token             | false | :unauthorized
      :public  | :guest      | false | :job_token             | false | :unauthorized
      :private | :developer  | true  | :job_token             | true  | :success
      :private | :guest      | true  | :job_token             | true  | :forbidden
      :private | :developer  | true  | :job_token             | false | :unauthorized
      :private | :guest      | true  | :job_token             | false | :unauthorized
      :private | :developer  | false | :job_token             | true  | :not_found
      :private | :guest      | false | :job_token             | true  | :not_found
      :private | :developer  | false | :job_token             | false | :unauthorized
      :private | :guest      | false | :job_token             | false | :unauthorized
    end

    # :visibility, :user_role, :member, :token_type, :valid_token, :expected_status
    def download_permissions_tables
      :public  | :developer  | true  | :personal_access_token | true  |  :success
      :public  | :guest      | true  | :personal_access_token | true  |  :success
      :public  | :developer  | true  | :personal_access_token | false |  :unauthorized
      :public  | :guest      | true  | :personal_access_token | false |  :unauthorized
      :public  | :developer  | false | :personal_access_token | true  |  :success
      :public  | :guest      | false | :personal_access_token | true  |  :success
      :public  | :developer  | false | :personal_access_token | false |  :unauthorized
      :public  | :guest      | false | :personal_access_token | false |  :unauthorized
      :public  | :anonymous  | false | :personal_access_token | true  |  :success
      :private | :developer  | true  | :personal_access_token | true  |  :success
      :private | :guest      | true  | :personal_access_token | true  |  :forbidden
      :private | :developer  | true  | :personal_access_token | false |  :unauthorized
      :private | :guest      | true  | :personal_access_token | false |  :unauthorized
      :private | :developer  | false | :personal_access_token | true | :not_found
      :private | :guest      | false | :personal_access_token | true  |  :not_found
      :private | :developer  | false | :personal_access_token | false |  :unauthorized
      :private | :guest      | false | :personal_access_token | false |  :unauthorized
      :private | :anonymous  | false | :personal_access_token | true  |  :not_found
      :public  | :developer  | true  | :job_token             | true  |  :success
      :public  | :guest      | true  | :job_token             | true  |  :success
      :public  | :developer  | true  | :job_token             | false |  :unauthorized
      :public  | :guest      | true  | :job_token             | false |  :unauthorized
      :public  | :developer  | false | :job_token             | true  |  :success
      :public  | :guest      | false | :job_token             | true  |  :success
      :public  | :developer  | false | :job_token             | false |  :unauthorized
      :public  | :guest      | false | :job_token             | false |  :unauthorized
      :private | :developer  | true  | :job_token             | true  |  :success
      :private | :guest      | true  | :job_token             | true  |  :forbidden
      :private | :developer  | true  | :job_token             | false |  :unauthorized
      :private | :guest      | true  | :job_token             | false |  :unauthorized
      :private | :developer  | false | :job_token             | true  |  :not_found
      :private | :guest      | false | :job_token             | true  |  :not_found
      :private | :developer  | false | :job_token             | false |  :unauthorized
      :private | :guest      | false | :job_token             | false |  :unauthorized
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
      where(:visibility, :user_role, :member, :token_type, :valid_token, :expected_status) do
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

      # rubocop:disable RSpec/MultipleMemoizedHelpers -- This test requires many different variables to be set
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
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    describe 'user access' do
      where(:visibility, :user_role, :member, :token_type, :valid_token, :expected_status) do
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

    let_it_be(:file_name) { 'model.md5' }
    let_it_be(:package) { model_version.package }
    let_it_be(:package_file_1) { create(:package_file, :generic, package: package, file_name: 'model.md5') }
    let_it_be(:package_file_2) { create(:package_file, :generic, package: package, file_name: 'my_dir%2Fmodel.md5') }

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
      where(:visibility, :user_role, :member, :token_type, :valid_token, :expected_status) do
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
end
