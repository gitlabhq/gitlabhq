# frozen_string_literal: true

RSpec.shared_context 'for terraform modules api setup' do
  include PackagesManagerApiSpecHelpers
  include WorkhorseHelpers

  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, namespace: group) }
  let_it_be(:package) { create(:terraform_module_package, project: project) }
  let_it_be(:personal_access_token) { create(:personal_access_token) }
  let_it_be(:user) { personal_access_token.user }
  let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }

  let(:headers) { {} }
  let(:token) { tokens[token_type] }

  let(:tokens) do
    {
      personal_access_token: personal_access_token.token,
      deploy_token: deploy_token.token,
      job_token: job.token,
      invalid: 'invalid-token123'
    }
  end
end
