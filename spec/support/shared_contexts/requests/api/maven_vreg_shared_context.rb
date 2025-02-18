# frozen_string_literal: true

RSpec.shared_context 'for maven virtual registry api setup' do
  include WorkhorseHelpers
  include HttpBasicAuthHelpers

  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:registry) { create(:virtual_registries_packages_maven_registry, group: group) }
  let_it_be(:upstream) { create(:virtual_registries_packages_maven_upstream, registry: registry) }
  let_it_be_with_reload(:cache_entry) do
    create(:virtual_registries_packages_maven_cache_entry, upstream: upstream)
  end

  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:user) { create(:user, owner_of: project) }
  let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }
  let_it_be(:deploy_token) do
    create(:deploy_token, :group, groups: [group], read_virtual_registry: true)
  end

  let(:personal_access_token) { create(:personal_access_token, user: user) }
  let(:headers) { token_header(:personal_access_token) }

  before do
    stub_config(dependency_proxy: { enabled: true }) # not enabled by default
  end

  def token_header(token)
    case token
    when :personal_access_token
      { 'PRIVATE-TOKEN' => personal_access_token.token }
    when :deploy_token
      { 'Deploy-Token' => deploy_token.token }
    when :job_token
      { 'Job-Token' => job.token }
    end
  end

  def token_basic_auth(token)
    case token
    when :personal_access_token
      user_basic_auth_header(user, personal_access_token)
    when :deploy_token
      deploy_token_basic_auth_header(deploy_token)
    when :job_token
      job_basic_auth_header(job)
    end
  end
end
