# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RackAttack::Request, feature_category: :rate_limiting do
  using RSpec::Parameterized::TableSyntax

  let(:path) { '/' }
  let(:env) { {} }
  let(:session) { {} }
  let(:request) do
    ::Rack::Attack::Request.new(
      env.reverse_merge(
        'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => Gitlab.config.gitlab.relative_url_root + path,
        'rack.input' => StringIO.new,
        'rack.session' => session
      )
    )
  end

  describe 'FILES_PATH_REGEX' do
    subject { described_class::FILES_PATH_REGEX }

    it { is_expected.to match('/api/v4/projects/1/repository/files/README') }
    it { is_expected.to match('/api/v4/projects/1/repository/files/README?ref=master') }
    it { is_expected.to match('/api/v4/projects/1/repository/files/README/blame') }
    it { is_expected.to match('/api/v4/projects/1/repository/files/README/raw') }
    it { is_expected.to match('/api/v4/projects/some%2Fnested%2Frepo/repository/files/README') }
    it { is_expected.not_to match('/api/v4/projects/some/nested/repo/repository/files/README') }
  end

  describe '#api_request?' do
    subject { request.api_request? }

    where(:path, :expected) do
      '/'        | false
      '/groups'  | false
      '/foo/api' | false

      '/api'             | false
      '/api/'            | true
      '/api/v4/groups/1' | true

      '/oauth/tokens'    | true
      '/oauth/userinfo'  | true
    end

    with_them do
      it { is_expected.to eq(expected) }

      context 'when the application is mounted at a relative URL' do
        before do
          stub_config_setting(relative_url_root: '/gitlab/root')
        end

        it { is_expected.to eq(expected) }
      end
    end
  end

  describe '#api_internal_request?' do
    subject { request.api_internal_request? }

    where(:path, :expected) do
      '/'                    | false
      '/groups'              | false
      '/api'                 | false
      '/api/v4/groups/1'     | false
      '/api/v4/internal'     | false
      '/foo/api/v4/internal' | false

      '/api/v4/internal/'    | true
      '/api/v4/internal/foo' | true
      '/api/v1/internal/foo' | true
    end

    with_them do
      it { is_expected.to eq(expected) }

      context 'when the application is mounted at a relative URL' do
        before do
          stub_config_setting(relative_url_root: '/gitlab/root')
        end

        it { is_expected.to eq(expected) }
      end
    end
  end

  describe '#health_check_request?' do
    subject { request.health_check_request? }

    where(:path, :expected) do
      '/'             | false
      '/groups'       | false
      '/foo/-/health' | false

      '/-/health'        | true
      '/-/liveness'      | true
      '/-/readiness'     | true
      '/-/metrics'       | true
      '/-/health/foo'    | true
      '/-/liveness/foo'  | true
      '/-/readiness/foo' | true
      '/-/metrics/foo'   | true
    end

    with_them do
      it { is_expected.to eq(expected) }

      context 'when the application is mounted at a relative URL' do
        before do
          stub_config_setting(relative_url_root: '/gitlab/root')
        end

        it { is_expected.to eq(expected) }
      end
    end
  end

  describe '#container_registry_event?' do
    subject { request.container_registry_event? }

    where(:path, :expected) do
      '/'                                     | false
      '/groups'                               | false
      '/api/v4/container_registry_event'      | false
      '/foo/api/v4/container_registry_event/' | false

      '/api/v4/container_registry_event/'    | true
      '/api/v4/container_registry_event/foo' | true
      '/api/v1/container_registry_event/foo' | true
    end

    with_them do
      it { is_expected.to eq(expected) }

      context 'when the application is mounted at a relative URL' do
        before do
          stub_config_setting(relative_url_root: '/gitlab/root')
        end

        it { is_expected.to eq(expected) }
      end
    end
  end

  describe '#product_analytics_collector_request?' do
    subject { request.product_analytics_collector_request? }

    where(:path, :expected) do
      '/'                  | false
      '/groups'            | false
      '/-/collector'       | false
      '/-/collector/foo'   | false
      '/foo/-/collector/i' | false

      '/-/collector/i'     | true
      '/-/collector/ifoo'  | true
      '/-/collector/i/foo' | true
    end

    with_them do
      it { is_expected.to eq(expected) }

      context 'when the application is mounted at a relative URL' do
        before do
          stub_config_setting(relative_url_root: '/gitlab/root')
        end

        it { is_expected.to eq(expected) }
      end
    end
  end

  describe '#should_be_skipped?' do
    where(
      api_internal_request: [true, false],
      health_check_request: [true, false],
      container_registry_event: [true, false]
    )

    with_them do
      it 'returns true if any condition is true' do
        allow(request).to receive(:api_internal_request?).and_return(api_internal_request)
        allow(request).to receive(:health_check_request?).and_return(health_check_request)
        allow(request).to receive(:container_registry_event?).and_return(container_registry_event)

        expect(request.should_be_skipped?).to be(api_internal_request || health_check_request || container_registry_event)
      end
    end
  end

  describe '#web_request?' do
    subject { request.web_request? }

    where(:path, :expected) do
      '/'        | true
      '/groups'  | true
      '/foo/api' | true

      '/api'             | true
      '/api/'            | false
      '/api/v4/groups/1' | false
    end

    with_them do
      it { is_expected.to eq(expected) }

      context 'when the application is mounted at a relative URL' do
        before do
          stub_config_setting(relative_url_root: '/gitlab/root')
        end

        it { is_expected.to eq(expected) }
      end
    end
  end

  describe '#throttle_unauthenticated_git_http?' do
    let_it_be(:project) { create(:project) }

    let(:git_clone_project_path_get_info_refs) { "/#{project.full_path}.git/info/refs?service=git-upload-pack" }
    let(:git_clone_path_post_git_upload_pack) { "/#{project.full_path}.git/git-upload-pack" }

    subject { request.throttle_unauthenticated_git_http? }

    where(:path, :request_unauthenticated?, :application_setting_throttle_unauthenticated_git_http_enabled, :expected) do
      ref(:git_clone_project_path_get_info_refs) | true  | true  | true
      ref(:git_clone_project_path_get_info_refs) | false | true  | false
      ref(:git_clone_project_path_get_info_refs) | true  | false | false
      ref(:git_clone_project_path_get_info_refs) | false | false | false

      ref(:git_clone_path_post_git_upload_pack)  | true  | true  | true
      ref(:git_clone_path_post_git_upload_pack)  | false | false | false

      '/users/sign_in'                           | true  | true  | false
      '/users/sign_in'                           | false | false | false
    end

    with_them do
      before do
        stub_application_setting(throttle_unauthenticated_git_http_enabled: application_setting_throttle_unauthenticated_git_http_enabled)

        allow(request).to receive(:unauthenticated?).and_return(request_unauthenticated?)
      end

      it { is_expected.to eq expected }
    end
  end

  describe '#protected_path?' do
    subject { request.protected_path? }

    before do
      stub_application_setting(
        protected_paths: [
          '/protected',
          '/secure'
        ])
    end

    where(:path, :expected) do
      '/'              | false
      '/groups'        | false
      '/foo/protected' | false
      '/foo/secure'    | false

      '/protected'  | true
      '/secure'     | true
      '/secure/'    | true
      '/secure/foo' | true
    end

    with_them do
      it { is_expected.to eq(expected) }

      context 'when the application is mounted at a relative URL' do
        before do
          stub_config_setting(relative_url_root: '/gitlab/root')
        end

        it { is_expected.to eq(expected) }
      end
    end
  end

  describe '#get_request_protected_path?' do
    subject { request.get_request_protected_path? }

    before do
      stub_application_setting(
        protected_paths_for_get_request: %w[/protected /secure])
    end

    where(:path, :expected) do
      '/'              | false
      '/groups'        | false
      '/foo/protected' | false
      '/foo/secure'    | false

      '/protected'  | true
      '/secure'     | true
      '/secure/'    | true
      '/secure/foo' | true
    end

    with_them do
      it { is_expected.to eq(expected) }

      context 'when the application is mounted at a relative URL' do
        before do
          stub_config_setting(relative_url_root: '/gitlab/root')
        end

        it { is_expected.to eq(expected) }
      end
    end
  end

  describe '#frontend_request?', :allow_forgery_protection do
    subject { request.send(:frontend_request?) }

    let(:path) { '/' }

    # Define these as local variables so we can use them in the `where` block.
    valid_token = SecureRandom.base64(ActionController::RequestForgeryProtection::AUTHENTICITY_TOKEN_LENGTH)
    other_token = SecureRandom.base64(ActionController::RequestForgeryProtection::AUTHENTICITY_TOKEN_LENGTH)

    before do
      allow(session).to receive(:enabled?).and_return(true)
      allow(session).to receive(:loaded?).and_return(true)
    end

    where(:session, :env, :expected) do
      {}                           | {}                                     | false
      {}                           | { 'HTTP_X_CSRF_TOKEN' => valid_token } | false
      { _csrf_token: valid_token } | { 'HTTP_X_CSRF_TOKEN' => other_token } | false
      { _csrf_token: valid_token } | { 'HTTP_X_CSRF_TOKEN' => valid_token } | true
    end

    with_them do
      it { is_expected.to eq(expected) }
    end
  end

  describe '#deprecated_api_request?' do
    subject { request.send(:deprecated_api_request?) }

    let(:env) { { 'QUERY_STRING' => query } }

    where(:path, :query, :expected) do
      '/' | '' | false

      '/api/v4/groups/1/'   | '' | true
      '/api/v4/groups/1'    | '' | true
      '/api/v4/groups/foo/' | '' | true
      '/api/v4/groups/foo'  | '' | true

      '/api/v4/groups/1'  | 'with_projects='  | true
      '/api/v4/groups/1'  | 'with_projects=1' | true
      '/api/v4/groups/1'  | 'with_projects=0' | false

      '/foo/api/v4/groups/1' | '' | false
      '/api/v4/groups/1/foo' | '' | false

      '/api/v4/groups/nested%2Fgroup' | '' | true
    end

    with_them do
      it { is_expected.to eq(expected) }

      context 'when the application is mounted at a relative URL' do
        before do
          stub_config_setting(relative_url_root: '/gitlab/root')
        end

        it { is_expected.to eq(expected) }
      end
    end
  end
end
