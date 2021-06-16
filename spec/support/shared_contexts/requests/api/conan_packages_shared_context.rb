# frozen_string_literal: true

RSpec.shared_context 'conan api setup' do
  include PackagesManagerApiSpecHelpers
  include HttpBasicAuthHelpers

  let(:package) { create(:conan_package) }
  let_it_be(:personal_access_token) { create(:personal_access_token) }
  let_it_be(:user) { personal_access_token.user }
  let_it_be(:base_secret) { SecureRandom.base64(64) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }

  let(:project) { package.project }
  let(:job) { create(:ci_build, :running, user: user, project: project) }
  let(:job_token) { job.token }
  let(:auth_token) { personal_access_token.token }
  let(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }

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

  before do
    project.add_developer(user)
    allow(Settings).to receive(:attr_encrypted_db_key_base).and_return(base_secret)
  end
end

RSpec.shared_context 'conan recipe endpoints' do
  include PackagesManagerApiSpecHelpers
  include HttpBasicAuthHelpers

  let(:jwt) { build_jwt(personal_access_token) }
  let(:headers) { build_token_auth_header(jwt.encoded) }
  let(:conan_package_reference) { '123456789' }
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
  let(:recipe_path) { "foo/bar/#{project.full_path.tr('/', '+')}/baz"}
end
