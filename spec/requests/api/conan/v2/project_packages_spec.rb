# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Conan::V2::ProjectPackages, feature_category: :package_registry do
  include_context 'conan api setup'

  describe 'GET /api/v4/projects/:id/packages/conan/v2/users/check_credentials' do
    let(:url) { "/projects/#{project.id}/packages/conan/v2/users/check_credentials" }

    it_behaves_like 'conan check_credentials endpoint'
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v2/conans/search' do
    let(:url) { "/projects/#{project.id}/packages/conan/v2/conans/search" }

    it_behaves_like 'conan search endpoint'

    it_behaves_like 'conan FIPS mode' do
      let(:params) { { q: package.conan_recipe } }

      subject { get api(url), params: params }
    end

    it_behaves_like 'conan search endpoint with access to package registry for everyone'
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/' \
    ':package_channel/revisions/:recipe_revision/files/:file_name' do
    include_context 'conan file download endpoints'

    let(:project_id) { project.id }
    let(:recipe_revision) { OpenSSL::Digest.hexdigest('MD5', 'valid_recipe_revision') }
    let(:file_name) { recipe_file.file_name }
    let(:url_suffix) { "#{recipe_path}/revisions/#{recipe_revision}/files/#{file_name}" }
    let(:url) { "/projects/#{project_id}/packages/conan/v2/conans/#{url_suffix}" }

    subject(:get_request) { get api(url), headers: headers }

    # TODO: Endpoint is not implemented yet. See https://gitlab.com/gitlab-org/gitlab/-/issues/333033#note_2060136937.
    it_behaves_like 'returning response status with message', status: :not_found, message: 'Not supported'

    it_behaves_like 'project not found by project id'

    # TODO remove expected_success_status: :not_found when endpoint is implemented
    it_behaves_like 'enforcing job token policies', :read_packages, expected_success_status: :not_found do
      let(:request) { get_request }
      let(:headers) { job_basic_auth_header(target_job) }
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(conan_package_revisions_support: false)
      end

      it_behaves_like 'returning response status with message', status: :not_found,
        message: "'conan_package_revisions_support' feature flag is disabled"
    end

    context 'when packages feature disabled' do
      before do
        stub_packages_setting(enabled: false)
      end

      it_behaves_like 'returning response status', :not_found
    end

    context 'in FIPS mode', :fips_mode do
      it_behaves_like 'returning response status', :not_found
    end

    describe 'parameter validation' do
      using RSpec::Parameterized::TableSyntax

      let(:url_suffix) { "#{url_recipe_path}/revisions/#{url_recipe_revision}/files/#{url_file_name}" }

      where(:error, :url_recipe_path, :url_recipe_revision, :url_file_name) do
        /package_name/     | 'pac$kage-1/1.0.0/namespace1+project-1/stable' | ref(:recipe_revision) | ref(:file_name)
        /package_version/  | 'package-1/1.0.$/namespace1+project-1/stable'  | ref(:recipe_revision) | ref(:file_name)
        /package_username/ | 'package-1/1.0.0/name$pace1+project-1/stable'  | ref(:recipe_revision) | ref(:file_name)
        /package_channel/  | 'package-1/1.0.0/namespace1+project-1/$table'  | ref(:recipe_revision) | ref(:file_name)
        /recipe_revision/  | ref(:recipe_path)                              | 'invalid_revi$ion'    | ref(:file_name)
        /file_name/        | ref(:recipe_path)                              | ref(:recipe_revision) | 'invalid_file.txt'
      end

      with_them do
        it_behaves_like 'returning response status with error', status: :bad_request, error: params[:error]
      end
    end
  end
end
