# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::API do
  include GroupAPIHelpers

  describe 'Record user last activity in after hook' do
    # It does not matter which endpoint is used because last_activity_on should
    # be updated on every request. `/groups` is used as an example
    # to represent any API endpoint
    let(:user) { create(:user, last_activity_on: Date.yesterday) }

    it 'updates the users last_activity_on to the current date' do
      expect { get api('/groups', user) }.to change { user.reload.last_activity_on }.to(Date.today)
    end
  end

  describe 'User with only read_api scope personal access token' do
    # It does not matter which endpoint is used because this should behave
    # in the same way for every request. `/groups` is used as an example
    # to represent any API endpoint

    context 'when personal access token has only read_api scope' do
      let_it_be(:user) { create(:user) }
      let_it_be(:group) { create(:group) }
      let_it_be(:token) { create(:personal_access_token, user: user, scopes: [:read_api]) }

      before_all do
        group.add_owner(user)
      end

      it 'does authorize user for get request' do
        get api('/groups', personal_access_token: token)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'does authorize user for head request' do
        head api('/groups', personal_access_token: token)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'does not authorize user for revoked token' do
        revoked = create(:personal_access_token, :revoked, user: user, scopes: [:read_api])

        get api('/groups', personal_access_token: revoked)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'does not authorize user for post request' do
        params = attributes_for_group_api

        post api("/groups", personal_access_token: token), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'does not authorize user for put request' do
        group_param = { name: 'Test' }

        put api("/groups/#{group.id}", personal_access_token: token), params: group_param

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'does not authorize user for delete request' do
        delete api("/groups/#{group.id}", personal_access_token: token)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'authentication with deploy token' do
    context 'admin mode' do
      let_it_be(:project) { create(:project, :public) }
      let_it_be(:package) { create(:maven_package, project: project, name: project.full_path) }
      let_it_be(:maven_metadatum) { package.maven_metadatum }
      let_it_be(:package_file) { package.package_files.first }
      let_it_be(:deploy_token) { create(:deploy_token) }

      let(:headers_with_deploy_token) do
        {
          Gitlab::Auth::AuthFinders::DEPLOY_TOKEN_HEADER => deploy_token.token
        }
      end

      it 'does not bypass the session' do
        expect(Gitlab::Auth::CurrentUserMode).not_to receive(:bypass_session!)

        get(api("/packages/maven/#{maven_metadatum.path}/#{package_file.file_name}"),
            headers: headers_with_deploy_token)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end
    end
  end

  context 'application context' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { project.owner }

    it 'logs all application context fields' do
      allow_any_instance_of(Gitlab::GrapeLogging::Loggers::ContextLogger).to receive(:parameters) do
        Gitlab::ApplicationContext.current.tap do |log_context|
          expect(log_context).to match('correlation_id' => an_instance_of(String),
                                       'meta.caller_id' => 'GET /api/:version/projects/:id/issues',
                                       'meta.remote_ip' => an_instance_of(String),
                                       'meta.project' => project.full_path,
                                       'meta.root_namespace' => project.namespace.full_path,
                                       'meta.user' => user.username,
                                       'meta.client_id' => an_instance_of(String),
                                       'meta.feature_category' => 'issue_tracking')
        end
      end

      get(api("/projects/#{project.id}/issues", user))
    end

    it 'skips fields that do not apply' do
      allow_any_instance_of(Gitlab::GrapeLogging::Loggers::ContextLogger).to receive(:parameters) do
        Gitlab::ApplicationContext.current.tap do |log_context|
          expect(log_context).to match('correlation_id' => an_instance_of(String),
                                       'meta.caller_id' => 'GET /api/:version/users',
                                       'meta.remote_ip' => an_instance_of(String),
                                       'meta.client_id' => an_instance_of(String),
                                       'meta.feature_category' => 'users')
        end
      end

      get(api('/users'))
    end
  end

  describe 'Marginalia comments' do
    context 'GET /user/:id' do
      let_it_be(:user) { create(:user) }

      let(:component_map) do
        {
          "application" => "test",
          "endpoint_id" => "GET /api/:version/users/:id"
        }
      end

      subject { ActiveRecord::QueryRecorder.new { get api("/users/#{user.id}", user) } }

      it 'generates a query that includes the expected annotations' do
        expect(subject.log.last).to match(/correlation_id:.*/)

        component_map.each do |component, value|
          expect(subject.log.last).to include("#{component}:#{value}")
        end
      end
    end
  end

  describe 'supported content-types' do
    context 'GET /user/:id.txt' do
      let_it_be(:user) { create(:user) }

      subject { get api("/users/#{user.id}.txt", user) }

      it 'returns application/json' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/json')
        expect(response.body).to include('{"id":')
      end
    end
  end
end
