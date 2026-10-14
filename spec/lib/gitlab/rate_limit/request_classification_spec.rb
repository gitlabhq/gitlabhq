# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RateLimit::RequestClassification, feature_category: :rate_limiting do
  using RSpec::Parameterized::TableSyntax

  let(:request_class) do
    Class.new(::Rack::Request) do
      include ::Gitlab::RateLimit::RequestClassification
    end
  end

  let(:path) { '/' }
  let(:env) { {} }
  let(:session) { {} }
  let(:request) do
    request_class.new(
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

  describe 'OAUTH_TOKEN_CHECK_PATH_REGEX' do
    subject { described_class::OAUTH_TOKEN_CHECK_PATH_REGEX }

    it { is_expected.to match('/oauth/token/info') }
    it { is_expected.to match('/oauth/token/info.json') }
    it { is_expected.not_to match('/oauth/token/info.xml') }
    it { is_expected.to match('/oauth/userinfo') }
    it { is_expected.to match('/o/my-org/oauth/token/info') }
    it { is_expected.to match('/o/my-org/oauth/userinfo') }
    it { is_expected.not_to match('/oauth/token') }
    it { is_expected.not_to match('/oauth/token/info/extra') }
    it { is_expected.not_to match('/group/project/oauth/userinfo') }
    it { is_expected.not_to match('/api/v4/oauth/userinfo') }
  end

  describe '#authenticated_requester' do
    subject { request.send(:authenticated_requester) }

    let_it_be(:user) { create(:user) }
    let_it_be(:token) { create(:oauth_access_token, resource_owner: user, scopes: [:openid]) }

    let(:env) { { 'HTTP_AUTHORIZATION' => "Bearer #{token.plaintext_token}" } }
    let(:request) { request_class.new(Rack::MockRequest.env_for(path).merge(env)) }

    where(:path) do
      %w[/oauth/token/info /oauth/userinfo /o/my-org/oauth/token/info /o/my-org/oauth/userinfo]
    end

    with_them do
      it { is_expected.to eq(user) }

      context 'with an unknown token' do
        let(:env) { { 'HTTP_AUTHORIZATION' => 'Bearer unknown' } }

        it { is_expected.to be_nil }
      end

      context 'without a token' do
        let(:env) { {} }

        it { is_expected.to be_nil }
      end
    end

    context 'on another OAuth path' do
      let(:path) { '/oauth/token/info/extra' }

      it { is_expected.to be_nil }
    end
  end

  describe 'MCP_PATH_REGEX' do
    subject { described_class::MCP_PATH_REGEX }

    it { is_expected.to match('/api/v4/mcp') }
    it { is_expected.to match('/api/v5/mcp') }
    it { is_expected.not_to match('/api/v4/mcp_tokens') }
    it { is_expected.not_to match('/api/v4/orbit/mcp') }
    it { is_expected.not_to match('/.well-known/oauth-protected-resource/api/v4/mcp') }
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

  describe '#web_request?' do
    subject { request.web_request? }

    where(:path, :expected) do
      '/'        | true
      '/groups'  | true
      '/foo/api' | true

      '/api'             | true
      '/api/'            | false
      '/api/v4/groups/1' | false

      '/-/collector/foo'   | true
      '/-/collector/i'     | false
      '/-/collector/i/foo' | false
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
      allow(session).to receive_messages(enabled?: true, loaded?: true)
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

  describe '#dependency_proxy_path?' do
    subject { request.send(:dependency_proxy_path?) }

    where(:path, :expected) do
      '/v2/mygroup/dependency_proxy/containers/alpine/manifests/latest'                       | true
      '/v2/mygroup/dependency_proxy/containers/alpine/blobs/sha256:cafebabe'                  | true

      '/v2'                                                                                   | false
      '/v2/mygroup/dependency_proxy/containers/alpine/referrers/latest'                       | false
      '/v2/mygroup/dependency_proxy/containers/alpine/blobs/sha256:cafebabe/upload'           | false
      '/v2/mygroup/dependency_proxy/containers/alpine/blobs/sha256:cafebabe/upload/authorize' | false
      '/jwt/auth'                                                                             | false
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
