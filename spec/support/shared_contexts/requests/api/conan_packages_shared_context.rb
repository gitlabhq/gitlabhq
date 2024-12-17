# frozen_string_literal: true

RSpec.shared_context 'conan api setup' do
  include PackagesManagerApiSpecHelpers
  include HttpBasicAuthHelpers

  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { create(:user, developer_of: [project]) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:base_secret) { SecureRandom.base64(64) }
  let_it_be(:deploy_token) do
    create(:deploy_token, read_package_registry: true, write_package_registry: true)
  end

  let_it_be(:project_deploy_token, freeze: true) do
    create(:project_deploy_token, deploy_token: deploy_token, project: project)
  end

  let_it_be(:job, freeze: true) { create(:ci_build, :running, user: user, project: project) }

  let_it_be(:conan_package_reference) { '1234567890abcdef1234567890abcdef12345678' }
  let_it_be_with_reload(:package) do
    create(:conan_package, project: project, package_references: [conan_package_reference])
  end

  let(:job_token) { job.token }
  let(:auth_token) { personal_access_token.token }

  let(:headers) do
    { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('foo', auth_token) }
  end

  let(:jwt_secret) do
    OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('SHA256'),
      base_secret,
      Gitlab::ConanToken::HMAC_KEY
    )
  end

  let(:snowplow_gitlab_standard_context) do
    { user: user, project: project, namespace: project.namespace, property: 'i_package_conan_user' }
  end

  before do
    allow(Settings).to receive(:attr_encrypted_db_key_base).and_return(base_secret)
  end
end

RSpec.shared_context 'conan recipe endpoints' do
  include PackagesManagerApiSpecHelpers
  include HttpBasicAuthHelpers

  let(:jwt) { build_jwt(personal_access_token) }
  let(:headers) { build_token_auth_header(jwt.encoded) }
end

RSpec.shared_context 'conan file download endpoints' do
  include PackagesManagerApiSpecHelpers
  include HttpBasicAuthHelpers

  let(:jwt) { build_jwt(personal_access_token) }
  let(:headers) { build_token_auth_header(jwt.encoded) }
  let(:recipe_path) { package.conan_recipe_path }
  let(:package_file) { package.package_files.find_by(file_name: 'conaninfo.txt') }
  let(:recipe_file) { package.package_files.find_by(file_name: 'conanfile.py') }
  let(:metadata) { package_file.conan_file_metadatum }
end

RSpec.shared_context 'conan file upload endpoints' do
  include PackagesManagerApiSpecHelpers
  include WorkhorseHelpers
  include HttpBasicAuthHelpers

  include_context 'workhorse headers'

  let(:jwt) { build_jwt(personal_access_token) }
  let(:headers_with_token) { build_token_auth_header(jwt.encoded).merge(workhorse_headers) }
  let(:recipe_path) { "#{recipe_path_name}/#{recipe_path_version}/#{recipe_path_username}/#{recipe_path_channel}" }
  let(:recipe_path_name) { "#{package.name}_new" }
  let(:recipe_path_version) { package.version }
  let(:recipe_path_username) { project.full_path.tr('/', '+') }
  let(:recipe_path_channel) { "stable" }
end
