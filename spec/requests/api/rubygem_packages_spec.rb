# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::RubygemPackages do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:personal_access_token) { create(:personal_access_token) }
  let_it_be(:user) { personal_access_token.user }
  let_it_be(:job) { create(:ci_build, :running, user: user) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }
  let_it_be(:headers) { {} }

  shared_examples 'when feature flag is disabled' do
    let(:headers) do
      { 'HTTP_AUTHORIZATION' => personal_access_token.token }
    end

    before do
      stub_feature_flags(rubygem_packages: false)
    end

    it_behaves_like 'returning response status', :not_found
  end

  shared_examples 'when package feature is disabled' do
    before do
      stub_config(packages: { enabled: false })
    end

    it_behaves_like 'returning response status', :not_found
  end

  shared_examples 'without authentication' do
    it_behaves_like 'returning response status', :unauthorized
  end

  shared_examples 'with authentication' do
    let(:headers) do
      { 'HTTP_AUTHORIZATION' => token }
    end

    let(:tokens) do
      {
        personal_access_token: personal_access_token.token,
        deploy_token: deploy_token.token,
        job_token: job.token
      }
    end

    where(:user_role, :token_type, :valid_token, :status) do
      :guest     | :personal_access_token   | true  | :not_found
      :guest     | :personal_access_token   | false | :unauthorized
      :guest     | :deploy_token            | true  | :not_found
      :guest     | :deploy_token            | false | :unauthorized
      :guest     | :job_token               | true  | :not_found
      :guest     | :job_token               | false | :unauthorized
      :reporter  | :personal_access_token   | true  | :not_found
      :reporter  | :personal_access_token   | false | :unauthorized
      :reporter  | :deploy_token            | true  | :not_found
      :reporter  | :deploy_token            | false | :unauthorized
      :reporter  | :job_token               | true  | :not_found
      :reporter  | :job_token               | false | :unauthorized
      :developer | :personal_access_token   | true  | :not_found
      :developer | :personal_access_token   | false | :unauthorized
      :developer | :deploy_token            | true  | :not_found
      :developer | :deploy_token            | false | :unauthorized
      :developer | :job_token               | true  | :not_found
      :developer | :job_token               | false | :unauthorized
    end

    with_them do
      before do
        project.send("add_#{user_role}", user) unless user_role == :anonymous
      end

      let(:token) { valid_token ? tokens[token_type] : 'invalid-token123' }

      it_behaves_like 'returning response status', params[:status]
    end
  end

  shared_examples 'an unimplemented route' do
    it_behaves_like 'without authentication'
    it_behaves_like 'with authentication'
    it_behaves_like 'when feature flag is disabled'
    it_behaves_like 'when package feature is disabled'
  end

  describe 'GET /api/v4/projects/:project_id/packages/rubygems/:filename' do
    let(:url) { api("/projects/#{project.id}/packages/rubygems/specs.4.8.gz") }

    subject { get(url, headers: headers) }

    it_behaves_like 'an unimplemented route'
  end

  describe 'GET /api/v4/projects/:project_id/packages/rubygems/quick/Marshal.4.8/:file_name' do
    let(:url) { api("/projects/#{project.id}/packages/rubygems/quick/Marshal.4.8/my_gem-1.0.0.gemspec.rz") }

    subject { get(url, headers: headers) }

    it_behaves_like 'an unimplemented route'
  end

  describe 'GET /api/v4/projects/:project_id/packages/rubygems/gems/:file_name' do
    let(:url) { api("/projects/#{project.id}/packages/rubygems/gems/my_gem-1.0.0.gem") }

    subject { get(url, headers: headers) }

    it_behaves_like 'an unimplemented route'
  end

  describe 'POST /api/v4/projects/:project_id/packages/rubygems/api/v1/gems/authorize' do
    let(:url) { api("/projects/#{project.id}/packages/rubygems/api/v1/gems/authorize") }

    subject { post(url, headers: headers) }

    it_behaves_like 'an unimplemented route'
  end

  describe 'POST /api/v4/projects/:project_id/packages/rubygems/api/v1/gems' do
    let(:url) { api("/projects/#{project.id}/packages/rubygems/api/v1/gems") }

    subject { post(url, headers: headers) }

    it_behaves_like 'an unimplemented route'
  end

  describe 'GET /api/v4/projects/:project_id/packages/rubygems/api/v1/dependencies' do
    let(:url) { api("/projects/#{project.id}/packages/rubygems/api/v1/dependencies") }

    subject { get(url, headers: headers) }

    it_behaves_like 'an unimplemented route'
  end
end
