# frozen_string_literal: true

RSpec.shared_context 'npm api setup' do
  include PackagesManagerApiSpecHelpers
  include HttpBasicAuthHelpers

  let_it_be(:user, reload: true) { create(:user) }
  let_it_be(:group) { create(:group, name: 'test-group') }
  let_it_be(:namespace) { group }
  let_it_be(:project, reload: true) { create(:project, :public, namespace: namespace) }
  let_it_be(:package, reload: true) { create(:npm_package, project: project, name: "@#{group.path}/scoped_package") }
  let_it_be(:token) { create(:oauth_access_token, scopes: 'api', resource_owner: user) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:job, reload: true) { create(:ci_build, user: user, status: :running, project: project) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }

  let(:package_name) { package.name }
end

RSpec.shared_context 'set package name from package name type' do
  let(:package_name) do
    case package_name_type
    when :scoped_naming_convention
      "@#{group.path}/scoped-package"
    when :scoped_no_naming_convention
      '@any-scope/scoped-package'
    when :unscoped
      'unscoped-package'
    when :non_existing
      'non-existing-package'
    end
  end
end
