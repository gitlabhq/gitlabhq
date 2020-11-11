# frozen_string_literal: true

RSpec.shared_context 'npm api setup' do
  include PackagesManagerApiSpecHelpers
  include HttpBasicAuthHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project, reload: true) { create(:project, :public, namespace: group) }
  let_it_be(:package, reload: true) { create(:npm_package, project: project) }
  let_it_be(:token) { create(:oauth_access_token, scopes: 'api', resource_owner: user) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:job, reload: true) { create(:ci_build, user: user, status: :running) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }

  let(:package_name) { package.name }

  before do
    project.add_developer(user)
  end
end
