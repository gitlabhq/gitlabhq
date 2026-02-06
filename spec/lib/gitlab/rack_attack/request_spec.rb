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

  describe '#throttle_authenticated_get_protected_paths_web?' do
    let(:protected_web_path) { '/users/sign_in' }
    let(:unprotected_web_path) { '/dashboard' }
    let(:api_path) { '/api/v4/projects' }

    let(:env) { { 'REQUEST_METHOD' => request_method } }

    subject { request.throttle_authenticated_get_protected_paths_web? }

    before do
      stub_application_setting(protected_paths_for_get_request: ['/users/sign_in'])
      stub_application_setting(throttle_protected_paths_enabled: protected_paths_enabled)
    end

    where(:path, :request_method, :protected_paths_enabled, :expected) do
      # Protected web paths with GET are throttled when enabled
      ref(:protected_web_path)   | 'GET'  | true  | true
      ref(:protected_web_path)   | 'GET'  | false | false

      # POST requests to protected web paths are NOT throttled by GET throttle
      ref(:protected_web_path)   | 'POST' | true  | false
      ref(:protected_web_path)   | 'POST' | false | false

      # Unprotected web paths are NOT throttled
      ref(:unprotected_web_path) | 'GET'  | true  | false
      ref(:unprotected_web_path) | 'GET'  | false | false

      # API paths are NOT throttled by web throttle
      ref(:api_path)             | 'GET'  | true  | false
      ref(:api_path)             | 'GET'  | false | false
    end

    with_them do
      it { is_expected.to eq expected }
    end
  end

  describe '#throttle_authenticated_get_protected_paths_api?' do
    let(:protected_api_path) { '/api/v4/user/emails' }
    let(:unprotected_api_path) { '/api/v4/projects' }
    let(:web_path) { '/users/sign_in' }

    let(:env) { { 'REQUEST_METHOD' => request_method } }

    subject { request.throttle_authenticated_get_protected_paths_api? }

    before do
      stub_application_setting(protected_paths_for_get_request: ['/api/v4/user/emails'])
      stub_application_setting(throttle_protected_paths_enabled: protected_paths_enabled)
    end

    where(:path, :request_method, :protected_paths_enabled, :expected) do
      # Protected API paths with GET are throttled when enabled
      ref(:protected_api_path)   | 'GET'  | true  | true
      ref(:protected_api_path)   | 'GET'  | false | false

      # POST requests to protected API paths are NOT throttled by GET throttle
      ref(:protected_api_path)   | 'POST' | true  | false
      ref(:protected_api_path)   | 'POST' | false | false

      # Unprotected API paths are NOT throttled
      ref(:unprotected_api_path) | 'GET'  | true  | false
      ref(:unprotected_api_path) | 'GET'  | false | false

      # Web paths are NOT throttled by API throttle
      ref(:web_path)             | 'GET'  | true  | false
      ref(:web_path)             | 'GET'  | false | false
    end

    with_them do
      it { is_expected.to eq expected }
    end
  end

  describe '#throttle_unauthenticated_get_protected_paths?' do
    let(:protected_path) { '/users/sign_in' }
    let(:unprotected_path) { '/users' }
    let(:api_internal_path) { '/api/v4/internal/check' }
    let(:health_check_path) { '/-/health' }

    let(:env) { { 'REQUEST_METHOD' => request_method } }

    subject { request.throttle_unauthenticated_get_protected_paths? }

    before do
      stub_application_setting(protected_paths_for_get_request: ['/users/sign_in'])
      stub_application_setting(throttle_protected_paths_enabled: protected_paths_enabled)
      allow(request).to receive(:unauthenticated?).and_return(unauthenticated)
    end

    where(:path, :request_method, :protected_paths_enabled, :unauthenticated, :expected) do
      # Protected paths with GET are throttled when enabled and unauthenticated
      ref(:protected_path)   | 'GET'  | true  | true  | true
      ref(:protected_path)   | 'GET'  | true  | false | false
      ref(:protected_path)   | 'GET'  | false | true  | false
      ref(:protected_path)   | 'GET'  | false | false | false

      # POST requests to protected paths are NOT throttled by GET throttle
      ref(:protected_path)   | 'POST' | true  | true  | false
      ref(:protected_path)   | 'POST' | true  | false | false

      # Unprotected paths are NOT throttled
      ref(:unprotected_path) | 'GET'  | true  | true  | false
      ref(:unprotected_path) | 'GET'  | true  | false | false

      # Internal API paths are skipped
      ref(:api_internal_path) | 'GET' | true  | true  | false

      # Health check paths are skipped
      ref(:health_check_path) | 'GET' | true  | true  | false
    end

    with_them do
      it { is_expected.to eq expected }
    end
  end

  describe '#throttle_authenticated_protected_paths_web?' do
    let(:protected_web_path) { '/users/sign_in' }
    let(:unprotected_web_path) { '/dashboard' }
    let(:api_path) { '/api/v4/projects' }

    let(:env) { { 'REQUEST_METHOD' => request_method } }

    subject { request.throttle_authenticated_protected_paths_web? }

    before do
      stub_application_setting(protected_paths: ['/users/sign_in'])
      stub_application_setting(throttle_protected_paths_enabled: protected_paths_enabled)
    end

    where(:path, :request_method, :protected_paths_enabled, :expected) do
      # Protected web paths with POST are throttled when enabled
      ref(:protected_web_path)   | 'POST' | true  | true
      ref(:protected_web_path)   | 'POST' | false | false

      # GET requests to protected web paths are NOT throttled
      ref(:protected_web_path)   | 'GET'  | true  | false
      ref(:protected_web_path)   | 'GET'  | false | false

      # Unprotected web paths are NOT throttled
      ref(:unprotected_web_path) | 'POST' | true  | false
      ref(:unprotected_web_path) | 'POST' | false | false

      # API paths are NOT throttled by web throttle
      ref(:api_path)             | 'POST' | true  | false
      ref(:api_path)             | 'POST' | false | false
    end

    with_them do
      it { is_expected.to eq expected }
    end
  end

  describe '#throttle_authenticated_protected_paths_api?' do
    let(:protected_api_path) { '/api/v4/user/emails' }
    let(:unprotected_api_path) { '/api/v4/projects' }
    let(:web_path) { '/users/sign_in' }

    let(:env) { { 'REQUEST_METHOD' => request_method } }

    subject { request.throttle_authenticated_protected_paths_api? }

    before do
      stub_application_setting(protected_paths: ['/api/v4/user/emails'])
      stub_application_setting(throttle_protected_paths_enabled: protected_paths_enabled)
    end

    where(:path, :request_method, :protected_paths_enabled, :expected) do
      # Protected API paths with POST are throttled when enabled
      ref(:protected_api_path)   | 'POST' | true  | true
      ref(:protected_api_path)   | 'POST' | false | false

      # GET requests to protected API paths are NOT throttled
      ref(:protected_api_path)   | 'GET'  | true  | false
      ref(:protected_api_path)   | 'GET'  | false | false

      # Unprotected API paths are NOT throttled
      ref(:unprotected_api_path) | 'POST' | true  | false
      ref(:unprotected_api_path) | 'POST' | false | false

      # Web paths are NOT throttled by API throttle
      ref(:web_path)             | 'POST' | true  | false
      ref(:web_path)             | 'POST' | false | false
    end

    with_them do
      it { is_expected.to eq expected }
    end
  end

  describe '#throttle_unauthenticated_protected_paths?' do
    let(:protected_path) { '/users/sign_in' }
    let(:unprotected_path) { '/users' }
    let(:api_internal_path) { '/api/v4/internal/check' }
    let(:health_check_path) { '/-/health' }

    let(:env) { { 'REQUEST_METHOD' => request_method } }

    subject { request.throttle_unauthenticated_protected_paths? }

    before do
      stub_application_setting(protected_paths: ['/users/sign_in'])
      stub_application_setting(throttle_protected_paths_enabled: protected_paths_enabled)
      allow(request).to receive(:unauthenticated?).and_return(unauthenticated)
    end

    where(:path, :request_method, :protected_paths_enabled, :unauthenticated, :expected) do
      # Protected paths with POST are throttled when enabled and unauthenticated
      ref(:protected_path)   | 'POST' | true  | true  | true
      ref(:protected_path)   | 'POST' | true  | false | false
      ref(:protected_path)   | 'POST' | false | true  | false
      ref(:protected_path)   | 'POST' | false | false | false

      # GET requests to protected paths are NOT throttled
      ref(:protected_path)   | 'GET'  | true  | true  | false
      ref(:protected_path)   | 'GET'  | true  | false | false

      # Unprotected paths are NOT throttled
      ref(:unprotected_path) | 'POST' | true  | true  | false
      ref(:unprotected_path) | 'POST' | true  | false | false

      # Internal API paths are skipped
      ref(:api_internal_path) | 'POST' | true  | true  | false

      # Health check paths are skipped
      ref(:health_check_path) | 'POST' | true  | true  | false
    end

    with_them do
      it { is_expected.to eq expected }
    end
  end

  describe '#throttle_authenticated_deprecated_api?' do
    let(:deprecated_api_path) { '/api/v4/groups/1' }
    let(:api_path) { '/api/v4/projects' }
    let(:web_path) { '/users/sign_in' }

    subject { request.throttle_authenticated_deprecated_api? }

    where(:path, :throttle_authenticated_deprecated_api_enabled, :expected) do
      # Deprecated API paths are throttled when enabled
      ref(:deprecated_api_path) | true  | true
      ref(:deprecated_api_path) | false | false

      # Regular API paths are NOT throttled by deprecated API throttle
      ref(:api_path) | true  | false
      ref(:api_path) | false | false

      # Web paths are NOT throttled by deprecated API throttle
      ref(:web_path) | true  | false
      ref(:web_path) | false | false
    end

    with_them do
      before do
        stub_application_setting(throttle_authenticated_deprecated_api_enabled: throttle_authenticated_deprecated_api_enabled)
      end

      it { is_expected.to eq expected }
    end
  end

  describe '#throttle_unauthenticated_deprecated_api?' do
    let(:deprecated_api_path) { '/api/v4/groups/1' }
    let(:api_path) { '/api/v4/projects' }
    let(:web_path) { '/users/sign_in' }

    subject { request.throttle_unauthenticated_deprecated_api? }

    where(:path, :throttle_unauthenticated_deprecated_api_enabled, :unauthenticated, :expected) do
      # Deprecated API paths are throttled when enabled and unauthenticated
      ref(:deprecated_api_path) | true  | true  | true
      ref(:deprecated_api_path) | true  | false | false
      ref(:deprecated_api_path) | false | true  | false
      ref(:deprecated_api_path) | false | false | false

      # Regular API paths are NOT throttled by deprecated API throttle
      ref(:api_path) | true  | true  | false
      ref(:api_path) | true  | false | false

      # Web paths are NOT throttled by deprecated API throttle
      ref(:web_path) | true  | true  | false
      ref(:web_path) | true  | false | false
    end

    with_them do
      before do
        stub_application_setting(throttle_unauthenticated_deprecated_api_enabled: throttle_unauthenticated_deprecated_api_enabled)
        allow(request).to receive(:unauthenticated?).and_return(unauthenticated)
      end

      it { is_expected.to eq expected }
    end
  end

  describe '#throttle_authenticated_files_api?' do
    let_it_be(:project) { create(:project) }

    let(:files_api_path) { "/api/v4/projects/#{project.id}/repository/files/README" }
    let(:api_path) { '/api/v4/projects' }
    let(:web_path) { '/users/sign_in' }

    subject { request.throttle_authenticated_files_api? }

    where(:path, :throttle_authenticated_files_api_enabled, :expected) do
      # Files API paths are throttled when enabled
      ref(:files_api_path) | true  | true
      ref(:files_api_path) | false | false

      # Regular API paths are NOT throttled by files API throttle
      ref(:api_path) | true  | false
      ref(:api_path) | false | false

      # Web paths are NOT throttled by files API throttle
      ref(:web_path) | true  | false
      ref(:web_path) | false | false
    end

    with_them do
      before do
        stub_application_setting(throttle_authenticated_files_api_enabled: throttle_authenticated_files_api_enabled)
      end

      it { is_expected.to eq expected }
    end
  end

  describe '#throttle_unauthenticated_files_api?' do
    let_it_be(:project) { create(:project) }

    let(:files_api_path) { "/api/v4/projects/#{project.id}/repository/files/README" }
    let(:api_path) { '/api/v4/projects' }
    let(:web_path) { '/users/sign_in' }

    subject { request.throttle_unauthenticated_files_api? }

    where(:path, :throttle_unauthenticated_files_api_enabled, :unauthenticated, :expected) do
      # Files API paths are throttled when enabled and unauthenticated
      ref(:files_api_path) | true  | true  | true
      ref(:files_api_path) | true  | false | false
      ref(:files_api_path) | false | true  | false
      ref(:files_api_path) | false | false | false

      # Regular API paths are NOT throttled by files API throttle
      ref(:api_path) | true  | true  | false
      ref(:api_path) | true  | false | false

      # Web paths are NOT throttled by files API throttle
      ref(:web_path) | true  | true  | false
      ref(:web_path) | true  | false | false
    end

    with_them do
      before do
        stub_application_setting(throttle_unauthenticated_files_api_enabled: throttle_unauthenticated_files_api_enabled)
        allow(request).to receive(:unauthenticated?).and_return(unauthenticated)
      end

      it { is_expected.to eq expected }
    end
  end

  describe '#throttle_authenticated_packages_api?' do
    let_it_be(:project) { create(:project) }

    let(:packages_api_path) { "/api/v4/projects/#{project.id}/packages/conan/v1/ping" }
    let(:api_path) { '/api/v4/projects' }
    let(:web_path) { '/users/sign_in' }

    subject { request.throttle_authenticated_packages_api? }

    where(:path, :throttle_authenticated_packages_api_enabled, :expected) do
      # Packages API paths are throttled when enabled
      ref(:packages_api_path) | true  | true
      ref(:packages_api_path) | false | false

      # Regular API paths are NOT throttled by packages API throttle
      ref(:api_path) | true  | false
      ref(:api_path) | false | false

      # Web paths are NOT throttled by packages API throttle
      ref(:web_path) | true  | false
      ref(:web_path) | false | false
    end

    with_them do
      before do
        stub_application_setting(throttle_authenticated_packages_api_enabled: throttle_authenticated_packages_api_enabled)
      end

      it { is_expected.to eq expected }
    end
  end

  describe '#throttle_unauthenticated_packages_api?' do
    let_it_be(:project) { create(:project) }

    let(:packages_api_path) { "/api/v4/projects/#{project.id}/packages/conan/v1/ping" }
    let(:api_path) { '/api/v4/projects' }
    let(:web_path) { '/users/sign_in' }

    subject { request.throttle_unauthenticated_packages_api? }

    where(:path, :throttle_unauthenticated_packages_api_enabled, :unauthenticated, :expected) do
      # Packages API paths are throttled when enabled and unauthenticated
      ref(:packages_api_path) | true  | true  | true
      ref(:packages_api_path) | true  | false | false
      ref(:packages_api_path) | false | true  | false
      ref(:packages_api_path) | false | false | false

      # Regular API paths are NOT throttled by packages API throttle
      ref(:api_path) | true  | true  | false
      ref(:api_path) | true  | false | false

      # Web paths are NOT throttled by packages API throttle
      ref(:web_path) | true  | true  | false
      ref(:web_path) | true  | false | false
    end

    with_them do
      before do
        stub_application_setting(throttle_unauthenticated_packages_api_enabled: throttle_unauthenticated_packages_api_enabled)
        allow(request).to receive(:unauthenticated?).and_return(unauthenticated)
      end

      it { is_expected.to eq expected }
    end
  end

  describe '#throttle_authenticated_api?' do
    let_it_be(:project) { create(:project) }

    let(:api_path) { '/api/v4/projects' }
    let(:packages_api_path) { "/api/v4/projects/#{project.id}/packages/conan/v1/ping" }
    let(:files_api_path) { "/api/v4/projects/#{project.id}/repository/files/README" }
    let(:deprecated_api_path) { '/api/v4/groups/1' }
    let(:web_path) { '/users/sign_in' }

    subject { request.throttle_authenticated_api? }

    where(:path, :throttle_authenticated_api_enabled, :expected) do
      # Regular API paths are throttled when enabled
      ref(:api_path) | true  | true
      ref(:api_path) | false | false

      # Packages API paths are excluded (have their own throttle)
      ref(:packages_api_path) | true  | false
      ref(:packages_api_path) | false | false

      # Files API paths are excluded (have their own throttle)
      ref(:files_api_path) | true  | false
      ref(:files_api_path) | false | false

      # Deprecated API paths are excluded (have their own throttle)
      ref(:deprecated_api_path) | true  | false
      ref(:deprecated_api_path) | false | false

      # Web paths are NOT throttled by API throttle
      ref(:web_path) | true  | false
      ref(:web_path) | false | false
    end

    with_them do
      before do
        stub_application_setting(
          throttle_authenticated_api_enabled: throttle_authenticated_api_enabled,
          throttle_authenticated_packages_api_enabled: true,
          throttle_authenticated_files_api_enabled: true,
          throttle_authenticated_deprecated_api_enabled: true
        )
      end

      it { is_expected.to eq expected }
    end
  end

  describe '#throttle_unauthenticated_web?' do
    let_it_be(:project) { create(:project) }

    let(:web_path) { '/users/sign_in' }
    let(:api_path) { '/api/v4/projects' }
    let(:git_path) { "/#{project.full_path}.git/info/refs?service=git-upload-pack" }
    let(:health_check_path) { '/-/health' }

    subject { request.throttle_unauthenticated_web? }

    where(:path, :throttle_unauthenticated_enabled, :unauthenticated, :expected) do
      # Web paths are throttled when enabled and unauthenticated
      ref(:web_path) | true  | true  | true
      ref(:web_path) | true  | false | false
      ref(:web_path) | false | true  | false
      ref(:web_path) | false | false | false

      # API paths are NOT throttled by web throttle
      ref(:api_path) | true  | true  | false
      ref(:api_path) | true  | false | false

      # Git paths are excluded from web throttle
      ref(:git_path) | true  | true  | false
      ref(:git_path) | true  | false | false

      # Health check paths are skipped
      ref(:health_check_path) | true  | true  | false
      ref(:health_check_path) | true  | false | false
    end

    with_them do
      before do
        stub_application_setting(throttle_unauthenticated_enabled: throttle_unauthenticated_enabled)
        allow(request).to receive(:unauthenticated?).and_return(unauthenticated)
      end

      it { is_expected.to eq expected }
    end
  end

  describe '#throttle_unauthenticated_api?' do
    let_it_be(:project) { create(:project) }

    let(:api_path) { '/api/v4/projects' }
    let(:packages_api_path) { "/api/v4/projects/#{project.id}/packages/conan/v1/ping" }
    let(:files_api_path) { "/api/v4/projects/#{project.id}/repository/files/README" }
    let(:deprecated_api_path) { '/api/v4/groups/1' }
    let(:internal_api_path) { '/api/v4/internal/check' }
    let(:health_check_path) { '/-/health' }
    let(:web_path) { '/users/sign_in' }

    subject { request.throttle_unauthenticated_api? }

    where(:path, :throttle_unauthenticated_api_enabled, :unauthenticated, :expected) do
      # Regular API paths are throttled when enabled and unauthenticated
      ref(:api_path) | true  | true  | true
      ref(:api_path) | true  | false | false
      ref(:api_path) | false | true  | false
      ref(:api_path) | false | false | false

      # Packages API paths are excluded (have their own throttle)
      ref(:packages_api_path) | true  | true  | false
      ref(:packages_api_path) | true  | false | false

      # Files API paths are excluded (have their own throttle)
      ref(:files_api_path) | true  | true  | false
      ref(:files_api_path) | true  | false | false

      # Deprecated API paths are excluded (have their own throttle)
      ref(:deprecated_api_path) | true  | true  | false
      ref(:deprecated_api_path) | true  | false | false

      # Internal API paths are skipped
      ref(:internal_api_path) | true  | true  | false
      ref(:internal_api_path) | true  | false | false

      # Health check paths are skipped
      ref(:health_check_path) | true  | true  | false
      ref(:health_check_path) | true  | false | false

      # Web paths are NOT throttled by API throttle
      ref(:web_path) | true  | true  | false
      ref(:web_path) | true  | false | false
    end

    with_them do
      before do
        stub_application_setting(
          throttle_unauthenticated_api_enabled: throttle_unauthenticated_api_enabled,
          throttle_unauthenticated_packages_api_enabled: true,
          throttle_unauthenticated_files_api_enabled: true,
          throttle_unauthenticated_deprecated_api_enabled: true
        )
        allow(request).to receive(:unauthenticated?).and_return(unauthenticated)
      end

      it { is_expected.to eq expected }
    end
  end

  describe '#throttle_authenticated_web?' do
    let_it_be(:project) { create(:project) }

    let(:git_info_refs_path) { "/#{project.full_path}.git/info/refs?service=git-upload-pack" }
    let(:git_lfs_path) { "/#{project.full_path}.git/info/lfs/objects/batch" }
    let(:web_path) { '/users/sign_in' }

    subject { request.throttle_authenticated_web? }

    where(:path, :throttle_authenticated_web_enabled, :throttle_authenticated_git_lfs_enabled, :expected) do
      ref(:web_path) | true  | false | true
      ref(:web_path) | false | false | false
      ref(:web_path) | true  | true  | true
      ref(:web_path) | false | true  | false

      # Git HTTP paths are always excluded regardless of settings
      ref(:git_info_refs_path) | true  | false | false
      ref(:git_info_refs_path) | false | false | false
      ref(:git_info_refs_path) | true  | true  | false
      ref(:git_info_refs_path) | false | true  | false

      # Git LFS paths are excluded when LFS throttle is enabled
      ref(:git_lfs_path) | true  | true  | false
      ref(:git_lfs_path) | false | true  | false
      ref(:git_lfs_path) | true  | false | true
      ref(:git_lfs_path) | false | false | false
    end

    with_them do
      before do
        stub_application_setting(
          throttle_authenticated_web_enabled: throttle_authenticated_web_enabled,
          throttle_authenticated_git_lfs_enabled: throttle_authenticated_git_lfs_enabled
        )
      end

      it { is_expected.to eq expected }
    end
  end

  describe '#throttle_unauthenticated_git_http?' do
    let_it_be(:project) { create(:project) }

    let(:git_clone_project_path_get_info_refs) { "/#{project.full_path}.git/info/refs?service=git-upload-pack" }
    let(:git_clone_path_post_git_upload_pack) { "/#{project.full_path}.git/git-upload-pack" }
    let(:git_lfs_path) { "/#{project.full_path}.git/info/lfs/objects/batch" }

    subject { request.throttle_unauthenticated_git_http? }

    where(:path, :request_unauthenticated?, :application_setting_throttle_unauthenticated_git_http_enabled, :expected) do
      ref(:git_clone_project_path_get_info_refs) | true  | true  | true
      ref(:git_clone_project_path_get_info_refs) | false | true  | false
      ref(:git_clone_project_path_get_info_refs) | true  | false | false
      ref(:git_clone_project_path_get_info_refs) | false | false | false

      ref(:git_clone_path_post_git_upload_pack)  | true  | true  | true
      ref(:git_clone_path_post_git_upload_pack)  | false | false | false

      ref(:git_lfs_path) | true  | true  | true
      ref(:git_lfs_path) | false | true  | false
      ref(:git_lfs_path) | true  | false | false
      ref(:git_lfs_path) | false | false | false

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

  describe '#throttle_authenticated_git_lfs?' do
    let_it_be(:project) { create(:project) }

    let(:git_lfs_path) { "/#{project.full_path}.git/info/lfs/objects/batch" }
    let(:gitlab_lfs_path) { "/#{project.full_path}.git/gitlab-lfs/objects/abc123" }
    let(:git_info_refs_path) { "/#{project.full_path}.git/info/refs?service=git-upload-pack" }
    let(:web_path) { '/users/sign_in' }

    subject { request.throttle_authenticated_git_lfs? }

    where(:path, :throttle_authenticated_git_lfs_enabled, :expected) do
      # LFS paths (info/lfs) are throttled when enabled
      ref(:git_lfs_path)       | true  | true
      ref(:git_lfs_path)       | false | false

      # LFS paths (gitlab-lfs) are throttled when enabled
      ref(:gitlab_lfs_path)    | true  | true
      ref(:gitlab_lfs_path)    | false | false

      # Git HTTP paths are NOT throttled by LFS throttle
      ref(:git_info_refs_path) | true  | false
      ref(:git_info_refs_path) | false | false

      # Web paths are NOT throttled by LFS throttle
      ref(:web_path)           | true  | false
      ref(:web_path)           | false | false
    end

    with_them do
      before do
        stub_application_setting(throttle_authenticated_git_lfs_enabled: throttle_authenticated_git_lfs_enabled)
      end

      it { is_expected.to eq expected }
    end
  end

  describe '#throttle_authenticated_git_http?' do
    let_it_be(:project) { create(:project) }

    let(:git_info_refs_path) { "/#{project.full_path}.git/info/refs?service=git-upload-pack" }
    let(:git_receive_pack_path) { "/#{project.full_path}.git/git-receive-pack" }
    let(:git_upload_pack_path) { "/#{project.full_path}.git/git-upload-pack" }
    let(:git_lfs_path) { "/#{project.full_path}.git/info/lfs/objects/batch" }

    subject { request.throttle_authenticated_git_http? }

    where(:path, :request_authenticated?, :application_setting_throttle_authenticated_git_http_enabled, :expected) do
      ref(:git_info_refs_path)     | true  | true  | true
      ref(:git_info_refs_path)     | false | true  | true
      ref(:git_info_refs_path)     | true  | false | false
      ref(:git_info_refs_path)     | false | false | false

      ref(:git_receive_pack_path)  | true  | true  | true
      ref(:git_receive_pack_path)  | false | true  | true
      ref(:git_receive_pack_path)  | true  | false | false
      ref(:git_receive_pack_path)  | false | false | false

      ref(:git_upload_pack_path)   | true  | true  | true
      ref(:git_upload_pack_path)   | false | true  | true
      ref(:git_upload_pack_path)   | true  | false | false
      ref(:git_upload_pack_path)   | false | false | false

      ref(:git_lfs_path) | true  | true  | false
      ref(:git_lfs_path) | false | true  | false
      ref(:git_lfs_path) | true  | false | false
      ref(:git_lfs_path) | false | false | false

      '/users/sign_in'             | true  | true  | false
      '/users/sign_in'             | false | true  | false
      '/users/sign_in'             | true  | false | false
      '/users/sign_in'             | false | false | false
    end

    with_them do
      before do
        stub_application_setting(throttle_authenticated_git_http_enabled: application_setting_throttle_authenticated_git_http_enabled)
        allow(request).to receive(:authenticated?).and_return(request_authenticated?)
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

  describe '#runner_jobs_request?' do
    let_it_be(:job) { create(:ci_build, :running) }
    let_it_be(:runner) { build(:ci_runner) }

    subject { request.send(:runner_jobs_request?) }

    context 'when there is no associated token' do
      let(:path) { "/api/v4/jobs/#{job.id}/update" }

      it { is_expected.to be_falsy }
    end

    context 'when there is a runner token present' do
      let(:path) { "/api/v4/jobs/request" }

      before do
        allow(Gitlab::Auth::RequestAuthenticator).to receive_message_chain(:new, :runner).and_return(runner)
      end

      it { is_expected.to be_truthy }
    end

    context 'when there is a job token present' do
      before do
        allow(Gitlab::Auth::RequestAuthenticator).to receive_message_chain(:new, :runner, :job_from_token).and_return(job)
      end

      context 'for job update request' do
        let(:path) { "/api/v4/jobs/#{job.id}/update" }

        it { is_expected.to be_truthy }
      end

      context 'for job trace request' do
        let(:path) { "/api/v4/jobs/#{job.id}/trace" }

        it { is_expected.to be_truthy }
      end

      context 'for job artifacts request' do
        let(:path) { "/api/v4/jobs/#{job.id}/artifacts" }

        it { is_expected.to be_truthy }
      end
    end
  end
end
