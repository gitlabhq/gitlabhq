# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::ComposerPackages, feature_category: :package_registry do
  include HttpBasicAuthHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group, reload: true) { create(:group, :public) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:package_name) { 'package-name' }
  let_it_be(:project, reload: true) { create(:project, :custom_repo, files: { 'composer.json' => { name: package_name }.to_json }, group: group) }
  let_it_be(:deploy_token_for_project) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token_for_project, project: project) }
  let_it_be(:deploy_token_for_group) { create(:deploy_token, :group, read_package_registry: true, write_package_registry: true) }
  let_it_be(:group_deploy_token) { create(:group_deploy_token, deploy_token: deploy_token_for_group, group: group) }
  let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }

  let(:snowplow_gitlab_standard_context) do
    { project: project, namespace: project.namespace, user: user, property: 'i_package_composer_user' }
  end

  let(:headers) { {} }

  using RSpec::Parameterized::TableSyntax

  describe 'GET /api/v4/group/:id/-/packages/composer/packages' do
    let(:url) { "/group/#{group.id}/-/packages/composer/packages.json" }

    subject { get api(url), headers: headers }

    context 'with valid project' do
      let_it_be(:package) { create(:composer_package, :with_metadatum, project: project) }

      context 'with a public group' do
        before do
          group.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        end

        context 'with basic auth' do
          where(:project_visibility_level, :member_role, :token_type, :valid_token, :package_returned) do
            'PUBLIC'  | :developer | :user | true  | true
            'PUBLIC'  | :developer | :user | false | true # Anonymous User - fallback
            'PUBLIC'  | :developer | :job  | true  | true
            'PUBLIC'  | :guest     | :user | true  | true
            'PUBLIC'  | :guest     | :user | false | true # Anonymous User - fallback
            'PUBLIC'  | :guest     | :job  | true  | true
            'PUBLIC'  | nil        | :user | true  | true
            'PUBLIC'  | nil        | :user | false | true # Anonymous User - fallback
            'PUBLIC'  | nil        | :job  | true  | true
            'PUBLIC'  | nil        | nil   | nil   | true # Anonymous User
            'PRIVATE' | :developer | :user | true  | true
            'PRIVATE' | :developer | :user | false | false # Anonymous User - fallback
            'PRIVATE' | :developer | :job  | true  | true
            'PRIVATE' | :guest     | :user | true  | true
            'PRIVATE' | :guest     | :user | false | false # Anonymous User - fallback
            'PRIVATE' | :guest     | :job  | true  | true
            'PRIVATE' | nil        | :user | true  | false
            'PRIVATE' | nil        | :user | false | false # Anonymous User - fallback
            'PRIVATE' | nil        | :job  | true  | false
            'PRIVATE' | nil        | nil   | nil   | false # Anonymous User
          end

          with_them do
            include_context 'Composer api project access', auth_method: :basic, project_visibility_level: params[:project_visibility_level], token_type: params[:token_type], valid_token: params[:valid_token] do
              it_behaves_like 'Composer package index', member_role: params[:member_role], expected_status: :success, package_returned: params[:package_returned]
            end
          end
        end

        context 'with token auth' do
          where(:project_visibility_level, :member_role, :token_type, :valid_token, :expected_status, :package_returned) do
            :PUBLIC  | :developer | :user | true  | :success      | true
            :PUBLIC  | :developer | :user | false | :unauthorized | false
            :PUBLIC  | :developer | :job  | true  | :success      | true # Anonymous User - fallback
            :PUBLIC  | :guest     | :user | true  | :success      | true
            :PUBLIC  | :guest     | :user | false | :unauthorized | false
            :PUBLIC  | :guest     | :job  | true  | :success      | true # Anonymous User - fallback
            :PUBLIC  | nil        | :user | true  | :success      | true
            :PUBLIC  | nil        | :user | false | :unauthorized | false
            :PUBLIC  | nil        | :job  | true  | :success      | true # Anonymous User - fallback
            :PUBLIC  | nil        | nil   | nil   | :success      | true # Anonymous User
            :PRIVATE | :developer | :user | true  | :success      | true
            :PRIVATE | :developer | :user | false | :unauthorized | false
            :PRIVATE | :developer | :job  | true  | :success      | false # Anonymous User - fallback
            :PRIVATE | :guest     | :user | true  | :success      | true
            :PRIVATE | :guest     | :user | false | :unauthorized | false
            :PRIVATE | :guest     | :job  | true  | :success      | false
            :PRIVATE | nil        | :user | true  | :success      | false
            :PRIVATE | nil        | :user | false | :unauthorized | false
            :PRIVATE | nil        | nil   | nil   | :success      | false # Anonymous User
          end

          with_them do
            include_context 'Composer api project access', auth_method: :token, project_visibility_level: params[:project_visibility_level], token_type: params[:token_type], valid_token: params[:valid_token] do
              it_behaves_like 'Composer package index', member_role: params[:member_role], expected_status: params[:expected_status], package_returned: params[:package_returned]
            end
          end
        end
      end

      context 'with a private group' do
        before do
          group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        end

        it_behaves_like 'Composer access with deploy tokens'

        context 'with basic auth' do
          where(:member_role, :token_type, :valid_token, :shared_examples_name, :expected_status, :package_returned) do
            :developer | :user | true  | 'Composer package index'       | :success      | true
            :developer | :user | false | 'process Composer api request' | :unauthorized | false
            :developer | :job  | true  | 'Composer package index'       | :success      | true
            :guest     | :user | true  | 'Composer package index'       | :success      | true
            :guest     | :user | false | 'process Composer api request' | :unauthorized | false
            :guest     | :job  | true  | 'Composer package index'       | :success      | true
            nil        | :user | true  | 'Composer package index'       | :not_found    | false
            nil        | :user | false | 'process Composer api request' | :unauthorized | false
            nil        | :job  | true  | 'Composer package index'       | :not_found    | false
            nil        | nil   | nil   | 'process Composer api request' | :unauthorized | false # Anonymous User
          end

          with_them do
            include_context 'Composer api project access', auth_method: :basic, project_visibility_level: :PRIVATE, token_type: params[:token_type], valid_token: params[:valid_token] do
              it_behaves_like params[:shared_examples_name], member_role: params[:member_role], expected_status: params[:expected_status], package_returned: params[:package_returned]
            end
          end
        end

        context 'with token auth' do
          where(:member_role, :token_type, :valid_token, :shared_examples_name, :expected_status, :package_returned) do
            :developer  | :user | true  | 'Composer package index'       | :success      | true
            :developer  | :user | false | 'process Composer api request' | :unauthorized | false
            :developer  | :job  | true  | 'process Composer api request' | :unauthorized | false
            :guest      | :user | true  | 'Composer package index'       | :success      | true
            :guest      | :user | false | 'process Composer api request' | :unauthorized | false
            :guest      | :job  | true  | 'process Composer api request' | :unauthorized | false
            nil         | :user | true  | 'Composer package index'       | :not_found    | false
            nil         | :user | false | 'Composer package index'       | :unauthorized | false
            nil         | :job  | true  | 'process Composer api request' | :unauthorized | false
            nil         | nil   | nil   | 'process Composer api request' | :unauthorized | false # Anonymous User
          end

          with_them do
            include_context 'Composer api project access', auth_method: :token, project_visibility_level: :PRIVATE, token_type: params[:token_type], valid_token: params[:valid_token] do
              it_behaves_like params[:shared_examples_name], member_role: params[:member_role], expected_status: params[:expected_status], package_returned: params[:package_returned]
            end
          end
        end
      end
    end

    it_behaves_like 'rejects Composer access with unknown group id'
  end

  describe 'GET /api/v4/group/:id/-/packages/composer/p/:sha.json' do
    let(:sha) { '123' }
    let(:url) { "/group/#{group.id}/-/packages/composer/p/#{sha}.json" }
    let!(:package) { create(:composer_package, :with_metadatum, project: project) }

    subject { get api(url), headers: headers }

    context 'with valid project' do
      context 'with basic auth' do
        where(:project_visibility_level, :member_role, :token_type, :valid_token, :shared_examples_name, :expected_status) do
          'PUBLIC'  | :developer | :user | true  | 'Composer provider index'       | :success
          'PUBLIC'  | :developer | :user | false | 'Composer provider index'       | :success # Anonymous User - fallback
          'PUBLIC'  | :developer | :job  | true  | 'Composer provider index'       | :success
          'PUBLIC'  | :guest     | :user | true  | 'Composer provider index'       | :success
          'PUBLIC'  | :guest     | :user | false | 'Composer provider index'       | :success # Anonymous User - fallback
          'PUBLIC'  | :guest     | :job  | true  | 'Composer provider index'       | :success
          'PUBLIC'  | nil        | :user | true  | 'Composer provider index'       | :success
          'PUBLIC'  | nil        | :user | false | 'Composer provider index'       | :success # Anonymous User - fallback
          'PUBLIC'  | nil        | :job  | true  | 'Composer provider index'       | :success
          'PUBLIC'  | nil        | nil   | nil   | 'Composer provider index'       | :success # Anonymous User
          'PRIVATE' | :developer | :user | true  | 'Composer provider index'       | :success
          'PRIVATE' | :developer | :user | false | 'process Composer api request'  | :unauthorized
          'PRIVATE' | :developer | :job  | true  | 'Composer provider index'       | :success
          'PRIVATE' | :guest     | :user | true  | 'Composer provider index'       | :success
          'PRIVATE' | :guest     | :user | false | 'process Composer api request'  | :unauthorized
          'PRIVATE' | :guest     | :job  | true  | 'Composer provider index'       | :success
          'PRIVATE' | nil        | :user | true  | 'process Composer api request'  | :not_found
          'PRIVATE' | nil        | :user | false | 'process Composer api request'  | :unauthorized
          'PRIVATE' | nil        | :job  | true  | 'process Composer api request'  | :not_found
          'PRIVATE' | nil        | nil   | nil   | 'process Composer api request'  | :unauthorized # Anonymous User
        end

        with_them do
          include_context 'Composer api group access', auth_method: :basic, project_visibility_level: params[:project_visibility_level], token_type: params[:token_type], valid_token: params[:valid_token] do
            it_behaves_like params[:shared_examples_name], member_role: params[:member_role], expected_status: params[:expected_status]
          end
        end
      end

      context 'with token auth' do
        where(:project_visibility_level, :member_role, :token_type, :valid_token, :shared_examples_name, :expected_status) do
          'PUBLIC'  | :developer | :user | true  | 'Composer provider index'       | :success
          'PUBLIC'  | :developer | :user | false | 'process Composer api request'  | :unauthorized
          'PUBLIC'  | :developer | :job  | true  | 'Composer provider index'       | :success # Anonymous User - fallback
          'PUBLIC'  | :guest     | :user | true  | 'Composer provider index'       | :success
          'PUBLIC'  | :guest     | :user | false | 'process Composer api request'  | :unauthorized
          'PUBLIC'  | :guest     | :job  | true  | 'Composer provider index'       | :success # Anonymous User - fallback
          'PUBLIC'  | nil        | :user | true  | 'Composer provider index'       | :success
          'PUBLIC'  | nil        | :user | false | 'process Composer api request'  | :unauthorized
          'PUBLIC'  | nil        | :job  | true  | 'Composer provider index'       | :success # Anonymous User - fallback
          'PUBLIC'  | nil        | nil   | nil   | 'Composer provider index'       | :success # Anonymous User
          'PRIVATE' | :developer | :user | true  | 'Composer provider index'       | :success
          'PRIVATE' | :developer | :user | false | 'process Composer api request'  | :unauthorized
          'PRIVATE' | :developer | :job  | true  | 'process Composer api request'  | :unauthorized
          'PRIVATE' | :guest     | :user | true  | 'Composer provider index'       | :success
          'PRIVATE' | :guest     | :user | false | 'process Composer api request'  | :unauthorized
          'PRIVATE' | :guest     | :job  | true  | 'process Composer api request'  | :unauthorized
          'PRIVATE' | nil        | :user | true  | 'process Composer api request'  | :not_found
          'PRIVATE' | nil        | :user | false | 'process Composer api request'  | :unauthorized
          'PRIVATE' | nil        | :job  | true  | 'process Composer api request'  | :unauthorized
          'PRIVATE' | nil        | nil   | nil   | 'process Composer api request'  | :unauthorized # Anonymous User
        end

        with_them do
          include_context 'Composer api group access', auth_method: :token, project_visibility_level: params[:project_visibility_level], token_type: params[:token_type], valid_token: params[:valid_token] do
            it_behaves_like params[:shared_examples_name], member_role: params[:member_role], expected_status: params[:expected_status]
          end
        end
      end

      it_behaves_like 'Composer access with deploy tokens'
    end

    it_behaves_like 'rejects Composer access with unknown group id'
  end

  describe 'GET /api/v4/group/:id/-/packages/composer/*package_name.json' do
    let(:package_name) { 'foobar' }
    let(:sha) { '$1234' }
    let(:url) { "/group/#{group.id}/-/packages/composer/#{package_name}#{sha}.json" }

    subject { get api(url), headers: headers }

    context 'with no packages' do
      include_context 'Composer user type', member_role: :developer do
        it_behaves_like 'returning response status', :not_found
      end
    end

    context 'with valid project' do
      let!(:package) { create(:composer_package, :with_metadatum, name: package_name, project: project) }

      context 'with basic auth' do
        where(:project_visibility_level, :member_role, :token_type, :valid_token, :shared_examples_name, :expected_status) do
          'PUBLIC'  | :developer | :user | true  | 'Composer package api request' | :success
          'PUBLIC'  | :developer | :user | false | 'Composer package api request' | :success # Anonymous User - fallback
          'PUBLIC'  | :developer | :job  | true  | 'Composer package api request' | :success
          'PUBLIC'  | :guest     | :user | true  | 'Composer package api request' | :success
          'PUBLIC'  | :guest     | :user | false | 'Composer package api request' | :success # Anonymous User - fallback
          'PUBLIC'  | :guest     | :job  | true  | 'Composer package api request' | :success
          'PUBLIC'  | nil        | :user | true  | 'Composer package api request' | :success
          'PUBLIC'  | nil        | :user | false | 'Composer package api request' | :success # Anonymous User - fallback
          'PUBLIC'  | nil        | :job  | true  | 'Composer package api request' | :success
          'PUBLIC'  | nil        | nil   | nil   | 'Composer package api request' | :success # Anonymous User
          'PRIVATE' | :developer | :user | true  | 'Composer package api request' | :success
          'PRIVATE' | :developer | :user | false | 'process Composer api request' | :unauthorized
          'PRIVATE' | :developer | :job  | true  | 'Composer package api request' | :success
          'PRIVATE' | :guest     | :user | true  | 'Composer package api request' | :success
          'PRIVATE' | :guest     | :user | false | 'process Composer api request' | :unauthorized
          'PRIVATE' | :guest     | :job  | true  | 'Composer package api request' | :success
          'PRIVATE' | nil        | :user | true  | 'process Composer api request' | :not_found
          'PRIVATE' | nil        | :user | false | 'process Composer api request' | :unauthorized
          'PRIVATE' | nil        | :job  | true  | 'process Composer api request' | :not_found
          'PRIVATE' | nil        | nil   | nil   | 'process Composer api request' | :unauthorized # Anonymous User
        end

        with_them do
          include_context 'Composer api group access', auth_method: :basic, project_visibility_level: params[:project_visibility_level], token_type: params[:token_type], valid_token: params[:valid_token] do
            it_behaves_like params[:shared_examples_name], member_role: params[:member_role], expected_status: params[:expected_status]
          end
        end
      end

      context 'with token auth' do
        where(:project_visibility_level, :member_role, :token_type, :valid_token, :shared_examples_name, :expected_status) do
          'PUBLIC'  | :developer | :user | true  | 'Composer package api request' | :success
          'PUBLIC'  | :developer | :user | false | 'process Composer api request' | :unauthorized
          'PUBLIC'  | :developer | :job  | true  | 'Composer package api request' | :success # Anonymous User - fallback
          'PUBLIC'  | :guest     | :user | true  | 'Composer package api request' | :success
          'PUBLIC'  | :guest     | :user | false | 'process Composer api request' | :unauthorized
          'PUBLIC'  | :guest     | :job  | true  | 'Composer package api request' | :success # Anonymous User - fallback
          'PUBLIC'  | nil        | :user | true  | 'Composer package api request' | :success
          'PUBLIC'  | nil        | :user | false | 'process Composer api request' | :unauthorized
          'PUBLIC'  | nil        | :job  | true  | 'Composer package api request' | :success # Anonymous User - fallback
          'PUBLIC'  | nil        | nil   | nil   | 'Composer package api request' | :success # Anonymous User
          'PRIVATE' | :developer | :user | true  | 'Composer package api request' | :success
          'PRIVATE' | :developer | :user | false | 'process Composer api request' | :unauthorized
          'PRIVATE' | :developer | :job  | true  | 'process Composer api request' | :unauthorized
          'PRIVATE' | :guest     | :user | true  | 'Composer package api request' | :success
          'PRIVATE' | :guest     | :user | false | 'process Composer api request' | :unauthorized
          'PRIVATE' | :guest     | :job  | true  | 'process Composer api request' | :unauthorized
          'PRIVATE' | nil        | :user | true  | 'process Composer api request' | :not_found
          'PRIVATE' | nil        | :user | false | 'process Composer api request' | :unauthorized
          'PRIVATE' | nil        | :job  | true  | 'process Composer api request' | :unauthorized
          'PRIVATE' | nil        | nil   | nil   | 'process Composer api request' | :unauthorized # Anonymous User
        end

        with_them do
          include_context 'Composer api group access', auth_method: :token, project_visibility_level: params[:project_visibility_level], token_type: params[:token_type], valid_token: params[:valid_token] do
            it_behaves_like params[:shared_examples_name], member_role: params[:member_role], expected_status: params[:expected_status]
          end
        end
      end

      context 'without a sha' do
        let(:sha) { '' }

        include_context 'Composer api group access', project_visibility_level: 'PRIVATE', token_type: :user, auth_method: :token do
          it_behaves_like 'process Composer api request', member_role: :developer, expected_status: :not_found
        end
      end

      it_behaves_like 'Composer access with deploy tokens'
    end

    it_behaves_like 'rejects Composer access with unknown group id'
  end

  describe 'GET /api/v4/group/:id/-/packages/composer/p2/*package_name.json' do
    let(:package_name) { 'foobar' }
    let(:url) { "/group/#{group.id}/-/packages/composer/p2/#{package_name}.json" }

    subject { get api(url), headers: headers }

    context 'with no packages' do
      include_context 'Composer user type', member_role: :developer do
        it_behaves_like 'returning response status', :not_found
      end
    end

    context 'with valid project' do
      let!(:package) { create(:composer_package, :with_metadatum, name: package_name, project: project) }

      context 'with basic auth' do
        where(:project_visibility_level, :member_role, :token_type, :valid_token, :shared_examples_name, :expected_status) do
          'PUBLIC'  | :developer | :user | true  | 'Composer package api request' | :success
          'PUBLIC'  | :developer | :user | false | 'Composer package api request' | :success # Anonymous User - fallback
          'PUBLIC'  | :developer | :job  | true  | 'Composer package api request' | :success
          'PUBLIC'  | :guest     | :user | true  | 'Composer package api request' | :success
          'PUBLIC'  | :guest     | :user | false | 'Composer package api request' | :success # Anonymous User - fallback
          'PUBLIC'  | :guest     | :job  | true  | 'Composer package api request' | :success
          'PUBLIC'  | nil        | :user | true  | 'Composer package api request' | :success
          'PUBLIC'  | nil        | :user | false | 'Composer package api request' | :success # Anonymous User - fallback
          'PUBLIC'  | nil        | :job  | true  | 'Composer package api request' | :success
          'PUBLIC'  | nil        | nil   | nil   | 'Composer package api request' | :success # Anonymous User
          'PRIVATE' | :developer | :user | true  | 'Composer package api request' | :success
          'PRIVATE' | :developer | :user | false | 'process Composer api request' | :unauthorized
          'PRIVATE' | :developer | :job  | true  | 'Composer package api request' | :success
          'PRIVATE' | :guest     | :user | true  | 'Composer package api request' | :success
          'PRIVATE' | :guest     | :user | false | 'process Composer api request' | :unauthorized
          'PRIVATE' | :guest     | :job  | true  | 'Composer package api request' | :success
          'PRIVATE' | nil        | :user | true  | 'process Composer api request' | :not_found
          'PRIVATE' | nil        | :user | false | 'process Composer api request' | :unauthorized
          'PRIVATE' | nil        | :job  | true  | 'process Composer api request' | :not_found
          'PRIVATE' | nil        | nil   | nil   | 'process Composer api request' | :unauthorized # Anonymous User
        end

        with_them do
          include_context 'Composer api group access', auth_method: :basic, project_visibility_level: params[:project_visibility_level], token_type: params[:token_type], valid_token: params[:valid_token] do
            it_behaves_like params[:shared_examples_name], member_role: params[:member_role], expected_status: params[:expected_status]
          end
        end
      end

      context 'with token auth' do
        where(:project_visibility_level, :member_role, :token_type, :valid_token, :shared_examples_name, :expected_status) do
          'PUBLIC'  | :developer | :user | true  | 'Composer package api request' | :success
          'PUBLIC'  | :developer | :user | false | 'process Composer api request' | :unauthorized
          'PUBLIC'  | :developer | :job  | true  | 'Composer package api request' | :success # Anonymous User - fallback
          'PUBLIC'  | :guest     | :user | true  | 'Composer package api request' | :success
          'PUBLIC'  | :guest     | :user | false | 'process Composer api request' | :unauthorized
          'PUBLIC'  | :guest     | :job  | true  | 'Composer package api request' | :success # Anonymous User - fallback
          'PUBLIC'  | nil        | :user | true  | 'Composer package api request' | :success
          'PUBLIC'  | nil        | :user | false | 'process Composer api request' | :unauthorized
          'PUBLIC'  | nil        | :job  | true  | 'Composer package api request' | :success # Anonymous User - fallback
          'PUBLIC'  | nil        | nil   | nil   | 'Composer package api request' | :success # Anonymous User
          'PRIVATE' | :developer | :user | true  | 'Composer package api request' | :success
          'PRIVATE' | :developer | :user | false | 'process Composer api request' | :unauthorized
          'PRIVATE' | :developer | :job  | true  | 'process Composer api request' | :unauthorized
          'PRIVATE' | :guest     | :user | true  | 'Composer package api request' | :success
          'PRIVATE' | :guest     | :user | false | 'process Composer api request' | :unauthorized
          'PRIVATE' | :guest     | :job  | true  | 'process Composer api request' | :unauthorized
          'PRIVATE' | nil        | :user | true  | 'process Composer api request' | :not_found
          'PRIVATE' | nil        | :user | false | 'process Composer api request' | :unauthorized
          'PRIVATE' | nil        | :job  | true  | 'process Composer api request' | :unauthorized
          'PRIVATE' | nil        | nil   | nil   | 'process Composer api request' | :unauthorized # Anonymous User
        end

        with_them do
          include_context 'Composer api group access', auth_method: :token, project_visibility_level: params[:project_visibility_level], token_type: params[:token_type], valid_token: params[:valid_token] do
            it_behaves_like params[:shared_examples_name], member_role: params[:member_role], expected_status: params[:expected_status]
          end
        end
      end

      it_behaves_like 'Composer access with deploy tokens'
    end

    it_behaves_like 'rejects Composer access with unknown group id'
  end

  describe 'POST /api/v4/projects/:id/packages/composer' do
    let(:url) { "/projects/#{project.id}/packages/composer" }
    let(:params) { {} }

    before_all do
      project.repository.add_tag(user, 'v1.2.99', 'master')
    end

    subject(:request) { post api(url), headers: headers, params: params }

    it_behaves_like 'enforcing job token policies', :admin_packages do
      before_all do
        project.add_developer(user)
      end

      let(:params) { { tag: 'v1.2.99', job_token: target_job.token } }
    end

    shared_examples 'composer package publish' do
      where(:project_visibility_level, :member_role, :token_type, :valid_token, :shared_examples_name, :expected_status) do
        'PUBLIC'  | :developer | :user | true  | 'Composer package creation'    | :created
        'PUBLIC'  | :developer | :user | false | 'process Composer api request' | :unauthorized
        'PUBLIC'  | :developer | :job  | true  | 'Composer package creation'    | :created
        'PUBLIC'  | :guest     | :user | true  | 'process Composer api request' | :forbidden
        'PUBLIC'  | :guest     | :user | false | 'process Composer api request' | :unauthorized
        'PUBLIC'  | :guest     | :job  | true  | 'process Composer api request' | :forbidden
        'PUBLIC'  | nil        | :user | true  | 'process Composer api request' | :forbidden
        'PUBLIC'  | nil        | :user | false | 'process Composer api request' | :unauthorized
        'PUBLIC'  | nil        | :job  | true  | 'process Composer api request' | :forbidden
        'PUBLIC'  | nil        | nil   | nil   | 'process Composer api request' | :unauthorized # Anonymous User
        'PRIVATE' | :developer | :user | true  | 'Composer package creation'    | :created
        'PRIVATE' | :developer | :user | false | 'process Composer api request' | :unauthorized
        'PRIVATE' | :developer | :job  | true  | 'Composer package creation'    | :created
        'PRIVATE' | :guest     | :user | true  | 'process Composer api request' | :forbidden
        'PRIVATE' | :guest     | :user | false | 'process Composer api request' | :unauthorized
        'PRIVATE' | :guest     | :job  | true  | 'process Composer api request' | :forbidden
        'PRIVATE' | nil        | :user | true  | 'process Composer api request' | :not_found
        'PRIVATE' | nil        | :user | false | 'process Composer api request' | :unauthorized
        'PRIVATE' | nil        | :job  | true  | 'process Composer api request' | :not_found
        'PRIVATE' | nil        | nil   | nil   | 'process Composer api request' | :unauthorized # Anonymous User
      end

      with_them do
        include_context 'Composer api project access', auth_method: :token, project_visibility_level: params[:project_visibility_level], token_type: params[:token_type], valid_token: params[:valid_token] do
          it_behaves_like params[:shared_examples_name], member_role: params[:member_role], expected_status: params[:expected_status]
        end
      end

      it_behaves_like 'Composer publish with deploy tokens'
      it_behaves_like 'rejects Composer access with unknown project id'
    end

    context 'with existing package' do
      include_context 'Composer api project access', auth_method: :token, project_visibility_level: 'PRIVATE', token_type: :user

      let_it_be_with_reload(:existing_package) { create(:composer_package, name: package_name, version: '1.2.99', project: project) }

      let(:params) { { tag: 'v1.2.99' } }

      before do
        project.add_maintainer(user)
      end

      it 'does not create a new package' do
        expect { subject }
          .to change { ::Packages::Composer::Package.for_projects(project).count }.by(0)

        expect(response).to have_gitlab_http_status(:created)
      end

      context 'marked as pending_destruction' do
        it 'does create a new package' do
          existing_package.pending_destruction!
          expect { subject }
            .to change { ::Packages::Composer::Package.for_projects(project).count }.by(1)

          expect(response).to have_gitlab_http_status(:created)
        end
      end
    end

    context 'with no tag or branch params' do
      let(:headers) { basic_auth_header(user.username, personal_access_token.token) }

      it_behaves_like 'process Composer api request', member_role: :developer, expected_status: :bad_request
    end

    context 'with a tag' do
      context 'with an existing branch' do
        let(:params) { { tag: 'v1.2.99' } }

        it_behaves_like 'composer package publish'
      end

      context 'with a non existing tag' do
        let(:params) { { tag: 'non-existing-tag' } }
        let(:headers) { basic_auth_header(user.username, personal_access_token.token) }

        it_behaves_like 'process Composer api request', member_role: :developer, expected_status: :not_found
      end
    end

    context 'with a branch' do
      context 'with an existing branch' do
        let(:params) { { branch: 'master' } }

        it_behaves_like 'composer package publish'
      end

      context 'with a non existing branch' do
        let(:params) { { branch: 'non-existing-branch' } }
        let(:headers) { basic_auth_header(user.username, personal_access_token.token) }

        it_behaves_like 'process Composer api request', member_role: :developer, expected_status: :not_found
      end
    end

    context 'with invalid composer.json' do
      let(:headers) { basic_auth_header(user.username, personal_access_token.token) }
      let(:params) { { tag: 'v1.2.99' } }
      let(:project) { create(:project, :custom_repo, files: files, group: group) }

      before do
        project.repository.add_tag(user, 'v1.2.99', 'master')
      end

      context 'with a missing composer.json file' do
        let(:files) { { 'some_other_file' => '' } }

        it_behaves_like 'process Composer api request', member_role: :developer, expected_status: :unprocessable_entity
      end

      context 'with an empty composer.json file' do
        let(:files) { { 'composer.json' => '' } }

        it_behaves_like 'process Composer api request', member_role: :developer, expected_status: :unprocessable_entity
      end

      context 'with a malformed composer.json file' do
        let(:files) { { 'composer.json' => 'not_valid_JSON' } }

        it_behaves_like 'process Composer api request', member_role: :developer, expected_status: :unprocessable_entity
      end
    end
  end

  describe 'GET /api/v4/projects/:id/packages/composer/archives/*package_name?sha=:sha' do
    let(:sha) { '123' }
    let(:url) { "/projects/#{project.id}/packages/composer/archives/#{package_name}.zip" }
    let(:params) { { sha: sha } }

    subject(:request) { get api(url), headers: headers, params: params }

    context 'with valid project' do
      let!(:package) { create(:composer_package, :with_metadatum, name: package_name, project: project) }
      let(:headers) { basic_auth_header(user.username, personal_access_token.token) }

      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      context 'when the sha does not match the package name' do
        let(:sha) { '123' }
        let(:headers) { basic_auth_header(user.username, personal_access_token.token) }

        context 'anonymous' do
          let(:headers) { {} }

          it_behaves_like 'process Composer api request', expected_status: :unauthorized
        end

        it_behaves_like 'process Composer api request', member_role: :developer, expected_status: :not_found
      end

      context 'when the package name does not match the sha' do
        let(:branch) { project.repository.find_branch('master') }
        let(:sha) { branch.target }
        let(:url) { "/projects/#{project.id}/packages/composer/archives/unexisting-package-name.zip" }

        context 'anonymous' do
          let(:headers) { {} }

          it_behaves_like 'process Composer api request', expected_status: :unauthorized
        end

        it_behaves_like 'process Composer api request', member_role: :developer, expected_status: :not_found
      end

      context 'with a match package name and sha' do
        let(:branch) { project.repository.find_branch('master') }
        let(:sha) { branch.target }

        it_behaves_like 'enforcing job token policies', :read_packages do
          before_all do
            project.add_developer(user)
          end

          let(:headers) { job_basic_auth_header(target_job) }
        end

        context 'with basic auth' do
          where(:project_visibility_level, :member_role, :token_type, :valid_token, :expected_status) do
            'PUBLIC'  | :developer | :user | true  | :success
            'PUBLIC'  | :developer | :user | false | :success # Anonymous User - fallback
            'PUBLIC'  | :developer | :job  | true  | :success
            'PUBLIC'  | :guest     | :user | true  | :success
            'PUBLIC'  | :guest     | :user | false | :success # Anonymous User - fallback
            'PUBLIC'  | :guest     | :job  | true  | :success
            'PUBLIC'  | nil        | :user | true  | :success
            'PUBLIC'  | nil        | :user | false | :success # Anonymous User - fallback
            'PUBLIC'  | nil        | :job  | true  | :success
            'PUBLIC'  | nil        | nil   | nil   | :success # Anonymous User
            'PRIVATE' | :developer | :user | true  | :success
            'PRIVATE' | :developer | :user | false | :unauthorized
            'PRIVATE' | :developer | :job  | true  | :success
            'PRIVATE' | :guest     | :user | true  | :success
            'PRIVATE' | :guest     | :user | false | :unauthorized
            'PRIVATE' | :guest     | :job  | true  | :success
            'PRIVATE' | nil        | :user | true  | :not_found
            'PRIVATE' | nil        | :user | false | :unauthorized
            'PRIVATE' | nil        | :job  | true  | :not_found
            'PRIVATE' | nil        | nil   | nil   | :unauthorized # Anonymous User
          end

          with_them do
            include_context 'Composer api project access', auth_method: :basic, project_visibility_level: params[:project_visibility_level], token_type: params[:token_type], valid_token: params[:valid_token] do
              it_behaves_like 'process Composer api request', member_role: params[:member_role], expected_status: params[:expected_status] do
                if params[:expected_status] == :success
                  let(:snowplow_gitlab_standard_context) do
                    if valid_token && (member_role || project_visibility_level == 'PUBLIC')
                      { project: project, namespace: project.namespace, property: 'i_package_composer_user', user: user }
                    else
                      { project: project, namespace: project.namespace, property: 'i_package_composer_user' }
                    end
                  end

                  it_behaves_like 'a package tracking event', described_class.name, 'pull_package'
                else
                  it_behaves_like 'not a package tracking event'
                end
              end

              context 'with another project' do
                include Ci::JobTokenScopeHelpers

                let_it_be(:project_two) { create(:project, group: group) }
                let_it_be(:job) { create(:ci_build, :running, user: user, project: project_two) }

                before do
                  add_inbound_accessible_linkage(project_two, project)
                end

                it_behaves_like 'process Composer api request', member_role: params[:member_role], expected_status: params[:expected_status]
              end
            end
          end
        end

        context 'with token auth' do
          where(:project_visibility_level, :member_role, :token_type, :valid_token, :expected_status) do
            'PUBLIC'  | :developer | :user | true  | :success
            'PUBLIC'  | :developer | :user | false | :unauthorized
            'PUBLIC'  | :developer | :job  | true  | :success # Anonymous User - fallback
            'PUBLIC'  | :guest     | :user | true  | :success
            'PUBLIC'  | :guest     | :user | false | :unauthorized
            'PUBLIC'  | :guest     | :job  | true  | :success # Anonymous User - fallback
            'PUBLIC'  | nil        | :user | true  | :success
            'PUBLIC'  | nil        | :user | false | :unauthorized
            'PUBLIC'  | nil        | :job  | true  | :success # Anonymous User - fallback
            'PUBLIC'  | nil        | nil   | nil   | :success # Anonymous User
            'PRIVATE' | :developer | :user | true  | :success
            'PRIVATE' | :developer | :user | false | :unauthorized
            'PRIVATE' | :developer | :job  | true  | :unauthorized
            'PRIVATE' | :guest     | :user | true  | :success
            'PRIVATE' | :guest     | :user | false | :unauthorized
            'PRIVATE' | :guest     | :job  | true  | :unauthorized
            'PRIVATE' | nil        | :user | true  | :not_found
            'PRIVATE' | nil        | :user | false | :unauthorized
            'PRIVATE' | nil        | :job  | true  | :unauthorized
            'PRIVATE' | nil        | nil   | nil   | :unauthorized # Anonymous User
          end

          with_them do
            include_context 'Composer api project access', auth_method: :token, project_visibility_level: params[:project_visibility_level], token_type: params[:token_type], valid_token: params[:valid_token] do
              it_behaves_like 'process Composer api request', member_role: params[:member_role], expected_status: params[:expected_status] do
                if params[:expected_status] == :success
                  let(:snowplow_gitlab_standard_context) do
                    # Job tokens sent over token auth means current_user is nil
                    if valid_token && token_type != :job && (member_role || project_visibility_level == 'PUBLIC')
                      { project: project, namespace: project.namespace, property: 'i_package_composer_user', user: user }
                    else
                      { project: project, namespace: project.namespace, property: 'i_package_composer_user' }
                    end
                  end

                  it_behaves_like 'a package tracking event', described_class.name, 'pull_package'
                else
                  it_behaves_like 'not a package tracking event'
                end
              end
            end
          end
        end

        it_behaves_like 'Composer publish with deploy tokens'

        context 'with access to package registry for everyone' do
          let(:headers) { {} }

          before do
            project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
            project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
          end

          it_behaves_like 'returning response status', :success
        end
      end
    end

    it_behaves_like 'rejects Composer access with unknown project id'
  end
end
