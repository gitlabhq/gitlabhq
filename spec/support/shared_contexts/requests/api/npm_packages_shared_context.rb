# frozen_string_literal: true

RSpec.shared_context 'npm api setup' do
  include PackagesManagerApiSpecHelpers
  include HttpBasicAuthHelpers

  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group, name: 'test-group') }
  let_it_be(:namespace, freeze: false) { group }
  let_it_be_with_reload(:project) { create(:project, :public, namespace: namespace) }
  let_it_be_with_reload(:package) { create(:npm_package, project: project, name: "@#{group.path}/scoped_package", version: '1.2.3') }
  let_it_be(:token, freeze: false) { create(:oauth_access_token, scopes: 'api', resource_owner: user) }
  let_it_be(:personal_access_token, freeze: false) { create(:personal_access_token, user: user) }
  let_it_be_with_reload(:job) { create(:ci_build, user: user, status: :running, project: project) }
  let_it_be(:deploy_token, freeze: false) { create(:deploy_token, read_package_registry: true, write_package_registry: true, projects: [project]) }

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
