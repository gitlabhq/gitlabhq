# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::HelmPackages do
  include_context 'helm api setup'

  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:project) { create(:project, :public) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }
  let_it_be(:package) { create(:helm_package, project: project) }

  describe 'GET /api/v4/projects/:id/packages/helm/:channel/index.yaml' do
    it_behaves_like 'handling helm chart index requests' do
      let(:url) { "/projects/#{project.id}/packages/helm/#{package.package_files.first.helm_channel}/index.yaml" }
    end
  end

  describe 'GET /api/v4/projects/:id/packages/helm/:channel/charts/:file_name.tgz' do
    let(:url) { "/projects/#{project.id}/packages/helm/#{package.package_files.first.helm_channel}/charts/#{package.name}-#{package.version}.tgz" }

    subject { get api(url) }

    context 'with valid project' do
      where(:visibility, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | true  | 'process helm download content request'   | :success
        :public  | :guest      | true  | true  | 'process helm download content request'   | :success
        :public  | :developer  | true  | false | 'rejects helm packages access'            | :unauthorized
        :public  | :guest      | true  | false | 'rejects helm packages access'            | :unauthorized
        :public  | :developer  | false | true  | 'process helm download content request'   | :success
        :public  | :guest      | false | true  | 'process helm download content request'   | :success
        :public  | :developer  | false | false | 'rejects helm packages access'            | :unauthorized
        :public  | :guest      | false | false | 'rejects helm packages access'            | :unauthorized
        :public  | :anonymous  | false | true  | 'process helm download content request'   | :success
        :private | :developer  | true  | true  | 'process helm download content request'   | :success
        :private | :guest      | true  | true  | 'rejects helm packages access'            | :forbidden
        :private | :developer  | true  | false | 'rejects helm packages access'            | :unauthorized
        :private | :guest      | true  | false | 'rejects helm packages access'            | :unauthorized
        :private | :developer  | false | true  | 'rejects helm packages access'            | :not_found
        :private | :guest      | false | true  | 'rejects helm packages access'            | :not_found
        :private | :developer  | false | false | 'rejects helm packages access'            | :unauthorized
        :private | :guest      | false | false | 'rejects helm packages access'            | :unauthorized
        :private | :anonymous  | false | true  | 'rejects helm packages access'            | :unauthorized
      end

      with_them do
        let(:token) { user_token ? personal_access_token.token : 'wrong' }
        let(:headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }
        let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace } }

        subject { get api(url), headers: headers }

        before do
          project.update!(visibility: visibility.to_s)
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end

    it_behaves_like 'deploy token for package GET requests'

    it_behaves_like 'rejects helm access with unknown project id'
  end
end
