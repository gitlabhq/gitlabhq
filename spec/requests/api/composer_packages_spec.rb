# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::ComposerPackages do
  include HttpBasicAuthHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group, reload: true) { create(:group, :public) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:package_name) { 'package-name' }
  let_it_be(:project, reload: true) { create(:project, :custom_repo, files: { 'composer.json' => { name: package_name }.to_json }, group: group) }

  let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace, user: user } }
  let(:headers) { {} }

  using RSpec::Parameterized::TableSyntax

  describe 'GET /api/v4/group/:id/-/packages/composer/packages' do
    let(:url) { "/group/#{group.id}/-/packages/composer/packages.json" }

    subject { get api(url), headers: headers }

    context 'with valid project' do
      let!(:package) { create(:composer_package, :with_metadatum, project: project) }

      context 'with a public group' do
        before do
          group.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        end

        context 'with basic auth' do
          where(:project_visibility_level, :user_role, :member, :user_token, :include_package) do
            'PUBLIC'  | :developer  | true  | true  | :include_package
            'PUBLIC'  | :developer  | false | true  | :include_package
            'PUBLIC'  | :guest      | true  | true  | :include_package
            'PUBLIC'  | :guest      | false | true  | :include_package
            'PUBLIC'  | :anonymous  | false | true  | :include_package
            'PRIVATE' | :developer  | true  | true  | :include_package
            'PRIVATE' | :developer  | false | true  | :does_not_include_package
            'PRIVATE' | :guest      | true  | true  | :does_not_include_package
            'PRIVATE' | :guest      | false | true  | :does_not_include_package
            'PRIVATE' | :anonymous  | false | true  | :does_not_include_package
            'PRIVATE' | :guest      | false | false | :does_not_include_package
            'PRIVATE' | :guest      | true  | false | :does_not_include_package
            'PRIVATE' | :developer  | false | false | :does_not_include_package
            'PRIVATE' | :developer  | true  | false | :does_not_include_package
            'PUBLIC'  | :developer  | true  | false | :include_package
            'PUBLIC'  | :guest      | true  | false | :include_package
            'PUBLIC'  | :developer  | false | false | :include_package
            'PUBLIC'  | :guest      | false | false | :include_package
          end

          with_them do
            include_context 'Composer api project access', params[:project_visibility_level], params[:user_role], params[:user_token], :basic do
              it_behaves_like 'Composer package index', params[:user_role], :success, params[:member], params[:include_package]
            end
          end
        end

        context 'with private token header auth' do
          where(:project_visibility_level, :user_role, :member, :user_token, :expected_status, :include_package) do
            'PUBLIC'  | :developer  | true  | true  | :success | :include_package
            'PUBLIC'  | :developer  | false | true  | :success | :include_package
            'PUBLIC'  | :guest      | true  | true  | :success | :include_package
            'PUBLIC'  | :guest      | false | true  | :success | :include_package
            'PUBLIC'  | :anonymous  | false | true  | :success | :include_package
            'PRIVATE' | :developer  | true  | true  | :success | :include_package
            'PRIVATE' | :developer  | false | true  | :success | :does_not_include_package
            'PRIVATE' | :guest      | true  | true  | :success | :does_not_include_package
            'PRIVATE' | :guest      | false | true  | :success | :does_not_include_package
            'PRIVATE' | :anonymous  | false | true  | :success | :does_not_include_package
            'PRIVATE' | :guest      | false | false | :unauthorized | nil
            'PRIVATE' | :guest      | true  | false | :unauthorized | nil
            'PRIVATE' | :developer  | false | false | :unauthorized | nil
            'PRIVATE' | :developer  | true  | false | :unauthorized | nil
            'PUBLIC'  | :developer  | true  | false | :unauthorized | nil
            'PUBLIC'  | :guest      | true  | false | :unauthorized | nil
            'PUBLIC'  | :developer  | false | false | :unauthorized | nil
            'PUBLIC'  | :guest      | false | false | :unauthorized | nil
          end

          with_them do
            include_context 'Composer api project access', params[:project_visibility_level], params[:user_role], params[:user_token], :token do
              it_behaves_like 'Composer package index', params[:user_role], params[:expected_status], params[:member], params[:include_package]
            end
          end
        end
      end

      context 'with a private group' do
        before do
          group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        end

        context 'with access to the api' do
          where(:project_visibility_level, :user_role, :member, :user_token, :include_package) do
            'PRIVATE' | :developer  | true  | true  | :include_package
            'PRIVATE' | :guest      | true  | true  | :does_not_include_package
          end

          with_them do
            include_context 'Composer api project access', params[:project_visibility_level], params[:user_role], params[:user_token] do
              it_behaves_like 'Composer package index', params[:user_role], :success, params[:member], params[:include_package]
            end
          end
        end

        context 'without access to the api' do
          where(:project_visibility_level, :user_role, :member, :user_token) do
            'PRIVATE' | :developer  | true  | false
            'PRIVATE' | :developer  | false | true
            'PRIVATE' | :developer  | false | false
            'PRIVATE' | :guest      | true  | false
            'PRIVATE' | :guest      | false | true
            'PRIVATE' | :guest      | false | false
            'PRIVATE' | :anonymous  | false | true
          end

          with_them do
            include_context 'Composer api project access', params[:project_visibility_level], params[:user_role], params[:user_token] do
              it_behaves_like 'process Composer api request', params[:user_role], :not_found, params[:member]
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
      where(:project_visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
        'PUBLIC'  | :developer  | true  | true  | 'Composer provider index'       | :success
        'PUBLIC'  | :developer  | true  | false | 'process Composer api request'  | :unauthorized
        'PUBLIC'  | :developer  | false | true  | 'Composer provider index'       | :success
        'PUBLIC'  | :developer  | false | false | 'process Composer api request'  | :unauthorized
        'PUBLIC'  | :guest      | true  | true  | 'Composer provider index'       | :success
        'PUBLIC'  | :guest      | true  | false | 'process Composer api request'  | :unauthorized
        'PUBLIC'  | :guest      | false | true  | 'Composer provider index'       | :success
        'PUBLIC'  | :guest      | false | false | 'process Composer api request'  | :unauthorized
        'PUBLIC'  | :anonymous  | false | true  | 'Composer provider index'       | :success
        'PRIVATE' | :developer  | true  | true  | 'Composer provider index'       | :success
        'PRIVATE' | :developer  | true  | false | 'process Composer api request'  | :unauthorized
        'PRIVATE' | :developer  | false | true  | 'process Composer api request'  | :not_found
        'PRIVATE' | :developer  | false | false | 'process Composer api request'  | :unauthorized
        'PRIVATE' | :guest      | true  | true  | 'Composer empty provider index' | :success
        'PRIVATE' | :guest      | true  | false | 'process Composer api request'  | :unauthorized
        'PRIVATE' | :guest      | false | true  | 'process Composer api request'  | :not_found
        'PRIVATE' | :guest      | false | false | 'process Composer api request'  | :unauthorized
        'PRIVATE' | :anonymous  | false | true  | 'process Composer api request'  | :not_found
      end

      with_them do
        include_context 'Composer api group access', params[:project_visibility_level], params[:user_role], params[:user_token] do
          it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
        end
      end
    end

    it_behaves_like 'rejects Composer access with unknown group id'
  end

  describe 'GET /api/v4/group/:id/-/packages/composer/*package_name.json' do
    let(:package_name) { 'foobar' }
    let(:sha) { '$1234' }
    let(:url) { "/group/#{group.id}/-/packages/composer/#{package_name}#{sha}.json" }

    subject { get api(url), headers: headers }

    context 'with no packages' do
      include_context 'Composer user type', :developer, true do
        it_behaves_like 'returning response status', :not_found
      end
    end

    context 'with valid project' do
      let!(:package) { create(:composer_package, :with_metadatum, name: package_name, project: project) }

      where(:project_visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
        'PUBLIC'  | :developer  | true  | true  | 'Composer package api request' | :success
        'PUBLIC'  | :developer  | true  | false | 'process Composer api request' | :unauthorized
        'PUBLIC'  | :developer  | false | true  | 'Composer package api request' | :success
        'PUBLIC'  | :developer  | false | false | 'process Composer api request' | :unauthorized
        'PUBLIC'  | :guest      | true  | true  | 'Composer package api request' | :success
        'PUBLIC'  | :guest      | true  | false | 'process Composer api request' | :unauthorized
        'PUBLIC'  | :guest      | false | true  | 'Composer package api request' | :success
        'PUBLIC'  | :guest      | false | false | 'process Composer api request' | :unauthorized
        'PUBLIC'  | :anonymous  | false | true  | 'Composer package api request' | :success
        'PRIVATE' | :developer  | true  | true  | 'Composer package api request' | :success
        'PRIVATE' | :developer  | true  | false | 'process Composer api request' | :unauthorized
        'PRIVATE' | :developer  | false | true  | 'process Composer api request' | :not_found
        'PRIVATE' | :developer  | false | false | 'process Composer api request' | :unauthorized
        'PRIVATE' | :guest      | true  | true  | 'process Composer api request' | :not_found
        'PRIVATE' | :guest      | true  | false | 'process Composer api request' | :unauthorized
        'PRIVATE' | :guest      | false | true  | 'process Composer api request' | :not_found
        'PRIVATE' | :guest      | false | false | 'process Composer api request' | :unauthorized
        'PRIVATE' | :anonymous  | false | true  | 'process Composer api request' | :not_found
      end

      with_them do
        include_context 'Composer api group access', params[:project_visibility_level], params[:user_role], params[:user_token] do
          it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
        end
      end

      context 'without a sha' do
        let(:sha) { '' }

        include_context 'Composer api group access', 'PRIVATE', :developer, true do
          include_context 'Composer user type', :developer, true do
            it_behaves_like 'process Composer api request', :developer, :not_found, true
          end
        end
      end
    end

    it_behaves_like 'rejects Composer access with unknown group id'
  end

  describe 'GET /api/v4/group/:id/-/packages/composer/p2/*package_name.json' do
    let(:package_name) { 'foobar' }
    let(:url) { "/group/#{group.id}/-/packages/composer/p2/#{package_name}.json" }

    subject { get api(url), headers: headers }

    context 'with no packages' do
      include_context 'Composer user type', :developer, true do
        it_behaves_like 'returning response status', :not_found
      end
    end

    context 'with valid project' do
      let!(:package) { create(:composer_package, :with_metadatum, name: package_name, project: project) }

      where(:project_visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
        'PUBLIC'  | :developer  | true  | true  | 'Composer package api request' | :success
        'PUBLIC'  | :developer  | true  | false | 'process Composer api request' | :unauthorized
        'PUBLIC'  | :developer  | false | true  | 'Composer package api request' | :success
        'PUBLIC'  | :developer  | false | false | 'process Composer api request' | :unauthorized
        'PUBLIC'  | :guest      | true  | true  | 'Composer package api request' | :success
        'PUBLIC'  | :guest      | true  | false | 'process Composer api request' | :unauthorized
        'PUBLIC'  | :guest      | false | true  | 'Composer package api request' | :success
        'PUBLIC'  | :guest      | false | false | 'process Composer api request' | :unauthorized
        'PUBLIC'  | :anonymous  | false | true  | 'Composer package api request' | :success
        'PRIVATE' | :developer  | true  | true  | 'Composer package api request' | :success
        'PRIVATE' | :developer  | true  | false | 'process Composer api request' | :unauthorized
        'PRIVATE' | :developer  | false | true  | 'process Composer api request' | :not_found
        'PRIVATE' | :developer  | false | false | 'process Composer api request' | :unauthorized
        'PRIVATE' | :guest      | true  | true  | 'process Composer api request' | :not_found
        'PRIVATE' | :guest      | true  | false | 'process Composer api request' | :unauthorized
        'PRIVATE' | :guest      | false | true  | 'process Composer api request' | :not_found
        'PRIVATE' | :guest      | false | false | 'process Composer api request' | :unauthorized
        'PRIVATE' | :anonymous  | false | true  | 'process Composer api request' | :not_found
      end

      with_them do
        include_context 'Composer api group access', params[:project_visibility_level], params[:user_role], params[:user_token] do
          it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
        end
      end
    end

    it_behaves_like 'rejects Composer access with unknown group id'
  end

  describe 'POST /api/v4/projects/:id/packages/composer' do
    let(:url) { "/projects/#{project.id}/packages/composer" }
    let(:params) { {} }

    before(:all) do
      project.repository.add_tag(user, 'v1.2.99', 'master')
    end

    subject { post api(url), headers: headers, params: params }

    shared_examples 'composer package publish' do
      context 'with valid project' do
        where(:project_visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
          'PUBLIC'  | :developer  | true  | true  | 'Composer package creation'    | :created
          'PUBLIC'  | :developer  | true  | false | 'process Composer api request' | :unauthorized
          'PUBLIC'  | :developer  | false | true  | 'process Composer api request' | :forbidden
          'PUBLIC'  | :developer  | false | false | 'process Composer api request' | :unauthorized
          'PUBLIC'  | :guest      | true  | true  | 'process Composer api request' | :forbidden
          'PUBLIC'  | :guest      | true  | false | 'process Composer api request' | :unauthorized
          'PUBLIC'  | :guest      | false | true  | 'process Composer api request' | :forbidden
          'PUBLIC'  | :guest      | false | false | 'process Composer api request' | :unauthorized
          'PUBLIC'  | :anonymous  | false | true  | 'process Composer api request' | :unauthorized
          'PRIVATE' | :developer  | true  | true  | 'Composer package creation'    | :created
          'PRIVATE' | :developer  | true  | false | 'process Composer api request' | :unauthorized
          'PRIVATE' | :developer  | false | true  | 'process Composer api request' | :not_found
          'PRIVATE' | :developer  | false | false | 'process Composer api request' | :unauthorized
          'PRIVATE' | :guest      | true  | true  | 'process Composer api request' | :forbidden
          'PRIVATE' | :guest      | true  | false | 'process Composer api request' | :unauthorized
          'PRIVATE' | :guest      | false | true  | 'process Composer api request' | :not_found
          'PRIVATE' | :guest      | false | false | 'process Composer api request' | :unauthorized
          'PRIVATE' | :anonymous  | false | true  | 'process Composer api request' | :unauthorized
        end

        with_them do
          include_context 'Composer api project access', params[:project_visibility_level], params[:user_role], params[:user_token] do
            it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
          end
        end
      end

      it_behaves_like 'rejects Composer access with unknown project id'
    end

    context 'with no tag or branch params' do
      let(:headers) { basic_auth_header(user.username, personal_access_token.token) }

      it_behaves_like 'process Composer api request', :developer, :bad_request
    end

    context 'with a tag' do
      context 'with an existing branch' do
        let(:params) { { tag: 'v1.2.99' } }

        it_behaves_like 'composer package publish'
      end

      context 'with a non existing tag' do
        let(:params) { { tag: 'non-existing-tag' } }
        let(:headers) { basic_auth_header(user.username, personal_access_token.token) }

        it_behaves_like 'process Composer api request', :developer, :not_found
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

        it_behaves_like 'process Composer api request', :developer, :not_found
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

        it_behaves_like 'process Composer api request', :developer, :unprocessable_entity
      end

      context 'with an empty composer.json file' do
        let(:files) { { 'composer.json' => '' } }

        it_behaves_like 'process Composer api request', :developer, :unprocessable_entity
      end

      context 'with a malformed composer.json file' do
        let(:files) { { 'composer.json' => 'not_valid_JSON' } }

        it_behaves_like 'process Composer api request', :developer, :unprocessable_entity
      end
    end
  end

  describe 'GET /api/v4/projects/:id/packages/composer/archives/*package_name?sha=:sha' do
    let(:sha) { '123' }
    let(:url) { "/projects/#{project.id}/packages/composer/archives/#{package_name}.zip" }
    let(:params) { { sha: sha } }

    subject { get api(url), headers: headers, params: params }

    context 'with valid project' do
      let!(:package) { create(:composer_package, :with_metadatum, name: package_name, project: project) }

      context 'when the sha does not match the package name' do
        let(:sha) { '123' }

        it_behaves_like 'process Composer api request', :anonymous, :not_found
      end

      context 'when the package name does not match the sha' do
        let(:branch) { project.repository.find_branch('master') }
        let(:sha) { branch.target }
        let(:url) { "/projects/#{project.id}/packages/composer/archives/unexisting-package-name.zip" }

        it_behaves_like 'process Composer api request', :anonymous, :not_found
      end

      context 'with a match package name and sha' do
        let(:branch) { project.repository.find_branch('master') }
        let(:sha) { branch.target }

        where(:project_visibility_level, :user_role, :member, :user_token, :expected_status) do
          'PUBLIC'  | :developer  | true  | true  | :success
          'PUBLIC'  | :developer  | true  | false | :success
          'PUBLIC'  | :developer  | false | true  | :success
          'PUBLIC'  | :developer  | false | false | :success
          'PUBLIC'  | :guest      | true  | true  | :success
          'PUBLIC'  | :guest      | true  | false | :success
          'PUBLIC'  | :guest      | false | true  | :success
          'PUBLIC'  | :guest      | false | false | :success
          'PUBLIC'  | :anonymous  | false | true  | :success
          'PRIVATE' | :developer  | true  | true  | :success
          'PRIVATE' | :developer  | true  | false | :success
          'PRIVATE' | :developer  | false | true  | :success
          'PRIVATE' | :developer  | false | false | :success
          'PRIVATE' | :guest      | true  | true  | :success
          'PRIVATE' | :guest      | true  | false | :success
          'PRIVATE' | :guest      | false | true  | :success
          'PRIVATE' | :guest      | false | false | :success
          'PRIVATE' | :anonymous  | false | true  | :success
        end

        with_them do
          let(:token) { user_token ? personal_access_token.token : 'wrong' }
          let(:headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }
          let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace } }

          before do
            project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility_level, false))
          end

          it_behaves_like 'process Composer api request', params[:user_role], params[:expected_status], params[:member]
          it_behaves_like 'a package tracking event', described_class.name, 'pull_package'
        end
      end
    end

    it_behaves_like 'rejects Composer access with unknown project id'
  end
end
