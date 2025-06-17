# frozen_string_literal: true

RSpec.shared_context 'npm api setup' do
  include PackagesManagerApiSpecHelpers
  include HttpBasicAuthHelpers

  let_it_be(:user, reload: true) { create(:user) }
  let_it_be(:group, reload: true) { create(:group, name: 'test-group') }
  let_it_be(:namespace) { group }
  let_it_be(:project, reload: true) { create(:project, :public, namespace: namespace) }
  let_it_be(:package, reload: true) { create(:npm_package, project: project, name: "@#{group.path}/scoped_package", version: '1.2.3') }
  let_it_be(:token) { create(:oauth_access_token, scopes: 'api', resource_owner: user) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:job, reload: true) { create(:ci_build, user: user, status: :running, project: project) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true, projects: [project]) }

  let(:package_name) { package.name }
  let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace, property: 'i_package_npm_user' } }
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
