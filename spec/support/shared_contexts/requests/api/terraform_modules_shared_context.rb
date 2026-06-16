# frozen_string_literal: true

RSpec.shared_context 'for terraform modules api setup' do
  include PackagesManagerApiSpecHelpers
  include WorkhorseHelpers
  include HttpBasicAuthHelpers

  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, namespace: group) }
  let_it_be(:package, freeze: false) { create(:terraform_module_package, :with_metadatum, project:) }
  let_it_be(:personal_access_token, freeze: false) { create(:personal_access_token) }
  let_it_be(:user, freeze: false) { personal_access_token.user }
  let_it_be(:job, freeze: false) { create(:ci_build, :running, user: user, project: project) }
  let_it_be(:deploy_token, freeze: false) do
    create(:deploy_token, read_package_registry: true, write_package_registry: true, projects: [project])
  end

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
