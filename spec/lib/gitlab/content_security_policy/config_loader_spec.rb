# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ContentSecurityPolicy::ConfigLoader, feature_category: :shared do
  let(:policy) { ActionDispatch::ContentSecurityPolicy.new }
  let(:lfs_enabled) { false }
  let(:proxy_download) { false }

  let(:csp_config) do
    {
      enabled: true,
      report_only: false,
      directives: {
        base_uri: 'http://example.com',
        child_src: "'self' https://child.example.com",
        connect_src: "'self' ws://example.com",
        default_src: "'self' https://other.example.com",
        script_src: "'self'  https://script.exammple.com ",
        worker_src: "data:  https://worker.example.com",
        report_uri: "http://example.com"
      }
    }
  end

  let(:lfs_config) do
    {
      enabled: lfs_enabled,
      remote_directory: 'lfs-objects',
      connection: object_store_connection_config,
      direct_upload: false,
      proxy_download: proxy_download,
      storage_options: {}
    }
  end

  let(:object_store_connection_config) do
    {
      provider: 'AWS',
      aws_access_key_id: 'AWS_ACCESS_KEY_ID',
      aws_secret_access_key: 'AWS_SECRET_ACCESS_KEY'
    }
  end

  before do
    stub_lfs_setting(enabled: lfs_enabled)
    allow(LfsObjectUploader)
      .to receive(:object_store_options)
      .and_return(GitlabSettings::Options.build(lfs_config))
  end

  describe '.default_enabled' do
    let(:enabled) { described_class.default_enabled }

    it 'is enabled' do
      expect(enabled).to be_truthy
    end

    context 'when in production' do
      before do
        stub_rails_env('production')
      end

      it 'is disabled' do
        expect(enabled).to be_falsey
      end
    end
  end

  describe '.default_directives' do
    let(:directives) { described_class.default_directives }
    let(:child_src) { directives['child_src'] }
    let(:connect_src) { directives['connect_src'] }
    let(:font_src) { directives['font_src'] }
    let(:frame_src) { directives['frame_src'] }
    let(:img_src) { directives['img_src'] }
    let(:media_src) { directives['media_src'] }
    let(:report_uri) { directives['report_uri'] }
    let(:script_src) { directives['script_src'] }
    let(:style_src) { directives['style_src'] }
    let(:worker_src) { directives['worker_src'] }

    before do
      stub_env('GITLAB_ANALYTICS_URL', nil)
    end

    it 'returns default directives' do
      directive_names = (described_class::DIRECTIVES - ['report_uri'])
      directive_names.each do |directive|
        expect(directives.has_key?(directive)).to be_truthy
        expect(directives[directive]).to be_truthy
      end

      expect(directives.has_key?('report_uri')).to be_truthy
      expect(report_uri).to be_nil
      expect(child_src).to eq("#{frame_src} #{worker_src}")
    end

    describe 'the images-src directive' do
      it 'can be loaded from anywhere' do
        expect(img_src).to include('http: https:')
      end
    end

    describe 'the media-src directive' do
      it 'can be loaded from anywhere' do
        expect(media_src).to include('http: https:')
      end
    end

    describe 'the worker-src directive' do
      it 'can be loaded from local origins' do
        expect(worker_src).to eq("'self' http://localhost/assets/ blob: data:")
      end
    end

    describe 'Webpack dev server websocket connections' do
      let(:webpack_dev_server_host) { 'webpack-dev-server.com' }
      let(:webpack_dev_server_port) { '9999' }
      let(:webpack_dev_server_https) { true }

      before do
        stub_config_setting(
          webpack: { dev_server: {
            host: webpack_dev_server_host,
            webpack_dev_server_port: webpack_dev_server_port,
            https: webpack_dev_server_https
          } }
        )
      end

      context 'when in production' do
        before do
          stub_rails_env('production')
        end

        context 'with secure domain' do
          it 'does not include webpack dev server in connect-src' do
            expect(connect_src).not_to include(webpack_dev_server_host)
            expect(connect_src).not_to include(webpack_dev_server_port)
          end
        end

        context 'with insecure domain' do
          let(:webpack_dev_server_https) { false }

          it 'does not include webpack dev server in connect-src' do
            expect(connect_src).not_to include(webpack_dev_server_host)
            expect(connect_src).not_to include(webpack_dev_server_port)
          end
        end
      end

      context 'when in development' do
        before do
          stub_rails_env('development')
        end

        context 'with secure domain' do
          before do
            stub_config_setting(host: webpack_dev_server_host, port: webpack_dev_server_port, https: true)
          end

          it 'includes secure websocket url for webpack dev server in connect-src' do
            expect(connect_src).to include("wss://#{webpack_dev_server_host}:#{webpack_dev_server_port}")
            expect(connect_src).not_to include("ws://#{webpack_dev_server_host}:#{webpack_dev_server_port}")
          end
        end

        context 'with insecure domain' do
          before do
            stub_config_setting(host: webpack_dev_server_host, port: webpack_dev_server_port, https: false)
          end

          it 'includes insecure websocket url for webpack dev server in connect-src' do
            expect(connect_src).not_to include("wss://#{webpack_dev_server_host}:#{webpack_dev_server_port}")
            expect(connect_src).to include("ws://#{webpack_dev_server_host}:#{webpack_dev_server_port}")
          end
        end
      end
    end

    describe 'Websocket connections' do
      it 'with insecure domain' do
        stub_config_setting(host: 'example.com', https: false)
        expect(connect_src).to eq("'self' ws://example.com")
      end

      it 'with secure domain' do
        stub_config_setting(host: 'example.com', https: true)
        expect(connect_src).to eq("'self' wss://example.com")
      end

      it 'with custom port' do
        stub_config_setting(host: 'example.com', port: '1234')
        expect(connect_src).to eq("'self' ws://example.com:1234")
      end

      it 'with custom port and secure domain' do
        stub_config_setting(host: 'example.com', https: true, port: '1234')
        expect(connect_src).to eq("'self' wss://example.com:1234")
      end

      it 'when port is included in HTTP_PORTS' do
        described_class::HTTP_PORTS.each do |port|
          stub_config_setting(host: 'example.com', https: true, port: port)
          expect(connect_src).to eq("'self' wss://example.com")
        end
      end
    end

    describe 'LFS connect-src headers' do
      let(:url_for_provider) { described_class.send(:build_lfs_url) }

      context 'when LFS is enabled' do
        let(:lfs_enabled) { true }

        context 'and object storage is not in use' do
          let(:lfs_config) do
            {
              enabled: false,
              remote_directory: 'lfs-objects',
              connection: {},
              direct_upload: false,
              proxy_download: true,
              storage_options: {}
            }
          end

          it 'is expected to be skipped' do
            expect(described_class.send(:allow_lfs, directives)).to be_nil
            expect(connect_src).not_to include('lfs-objects')
          end
        end

        context 'and direct downloads are enabled' do
          let(:provider) { LfsObjectUploader.object_store_options.connection.provider }

          context 'when provider is AWS' do
            it { expect(provider).to eq('AWS') }

            it { expect(url_for_provider).to be_present }

            it { expect(directives['connect_src']).to include(url_for_provider) }
          end

          context 'when provider is AzureRM' do
            let(:object_store_connection_config) do
              {
                provider: 'AzureRM',
                azure_storage_account_name: 'azuretest',
                azure_storage_access_key: 'ABCD1234'
              }
            end

            it { expect(provider).to eq('AzureRM') }

            it { expect(url_for_provider).to be_present }

            it { expect(directives['connect_src']).to include(url_for_provider) }
          end

          context 'when provider is Google' do
            let(:object_store_connection_config) do
              {
                provider: 'Google',
                google_project: 'GOOGLE_PROJECT',
                google_application_default: true
              }
            end

            it { expect(provider).to eq('Google') }

            it { expect(url_for_provider).to be_present }

            it { expect(directives['connect_src']).to include(url_for_provider) }
          end
        end

        context 'but direct downloads are disabled' do
          let(:proxy_download) { true }

          it { expect(directives['connect_src']).not_to include(url_for_provider) }
        end
      end

      context 'when LFS is disabled' do
        let(:proxy_download) { true }

        it { expect(directives['connect_src']).not_to include(url_for_provider) }
      end
    end

    describe 'CDN connections' do
      before do
        allow(described_class).to receive(:allow_letter_opener)
        allow(described_class).to receive(:allow_zuora)
        allow(described_class).to receive(:allow_framed_gitlab_paths)
        allow(described_class).to receive(:allow_customersdot)
        allow(described_class).to receive(:csp_level_3_backport)
      end

      context 'when CDN host is defined' do
        let(:cdn_host) { 'https://cdn.example.com' }

        before do
          stub_config_setting(cdn_host: cdn_host)
        end

        it 'adds CDN host to CSP' do
          expect(script_src).to include(cdn_host)
          expect(style_src).to include(cdn_host)
          expect(font_src).to include(cdn_host)
          expect(worker_src).to include(cdn_host)
          expect(frame_src).to include(cdn_host)
        end
      end

      context 'when CDN host is undefined' do
        before do
          stub_config_setting(cdn_host: nil)
        end

        it 'does not include CDN host in CSP' do
          expect(script_src).to eq(::Gitlab::ContentSecurityPolicy::Directives.script_src)
          expect(style_src).to eq(::Gitlab::ContentSecurityPolicy::Directives.style_src)
          expect(font_src).to eq("'self'")
          expect(worker_src).to eq(::Gitlab::ContentSecurityPolicy::Directives.worker_src)
          expect(frame_src).to eq(::Gitlab::ContentSecurityPolicy::Directives.frame_src)
        end
      end
    end

    describe 'Zuora directives' do
      context 'when on SaaS', :saas do
        it 'adds Zuora host to CSP' do
          expect(frame_src).to include('https://*.zuora.com/apps/PublicHostedPageLite.do')
        end
      end

      context 'when is not Gitlab.com?' do
        it 'does not add Zuora host to CSP' do
          expect(frame_src).not_to include('https://*.zuora.com/apps/PublicHostedPageLite.do')
        end
      end
    end

    context 'when sentry is configured' do
      let(:dsn) { 'dummy://def@sentry.example.com/2' }

      before do
        stub_config_setting(host: 'gitlab.example.com')
      end

      context 'when sentry is configured' do
        before do
          allow(Gitlab::CurrentSettings).to receive(:sentry_enabled).and_return(true)
          allow(Gitlab::CurrentSettings).to receive(:sentry_clientside_dsn).and_return(dsn)
        end

        it 'adds new sentry path to CSP' do
          expect(connect_src).to eq("'self' ws://gitlab.example.com dummy://sentry.example.com")
        end
      end

      context 'when sentry settings are from older schemas and sentry setting are missing' do
        before do
          allow(Gitlab::CurrentSettings).to receive(:respond_to?).with(:sentry_enabled).and_return(false)
          allow(Gitlab::CurrentSettings).to receive(:sentry_enabled).and_raise(NoMethodError)

          allow(Gitlab::CurrentSettings).to receive(:respond_to?).with(:sentry_clientside_dsn).and_return(false)
          allow(Gitlab::CurrentSettings).to receive(:sentry_clientside_dsn).and_raise(NoMethodError)
        end

        it 'config is backwards compatible, does not add sentry path to CSP' do
          expect(connect_src).to eq("'self' ws://gitlab.example.com")
        end
      end
    end

    describe 'Customer portal frames' do
      context 'when CUSTOMER_PORTAL_URL is set' do
        let(:customer_portal_url) { 'https://customers.example.com' }
        let(:frame_src_expectation) do
          [
            ::Gitlab::ContentSecurityPolicy::Directives.frame_src,
            'http://localhost/admin/',
            'http://localhost/assets/',
            'http://localhost/-/speedscope/index.html',
            'http://localhost/-/sandbox/',
            customer_portal_url
          ].join(' ')
        end

        before do
          stub_env('CUSTOMER_PORTAL_URL', customer_portal_url)
        end

        it 'adds CUSTOMER_PORTAL_URL to CSP' do
          expect(frame_src).to eq(frame_src_expectation)
        end
      end

      context 'when CUSTOMER_PORTAL_URL is blank' do
        let(:customer_portal_url) { '' }
        let(:frame_src_expectation) do
          [
            ::Gitlab::ContentSecurityPolicy::Directives.frame_src,
            'http://localhost/admin/',
            'http://localhost/assets/',
            'http://localhost/-/speedscope/index.html',
            'http://localhost/-/sandbox/'
          ].join(' ')
        end

        before do
          stub_env('CUSTOMER_PORTAL_URL', customer_portal_url)
        end

        it 'adds CUSTOMER_PORTAL_URL to CSP' do
          expect(frame_src).to eq(frame_src_expectation)
        end
      end
    end

    describe 'letter_opener application URL' do
      let(:gitlab_url) { 'http://gitlab.example.com' }
      let(:letter_opener_url) { "#{gitlab_url}/rails/letter_opener/" }

      before do
        stub_config_setting(url: gitlab_url)
      end

      context 'when in production' do
        before do
          stub_rails_env('production')
        end

        it 'does not add letter_opener to CSP' do
          expect(frame_src).not_to include(letter_opener_url)
        end
      end

      context 'when in development' do
        before do
          stub_rails_env('development')
        end

        it 'adds letter_opener to CSP' do
          expect(frame_src).to include(letter_opener_url)
        end
      end
    end

    context 'Snowplow Micro event collector' do
      let(:snowplow_micro_hostname) { 'localhost:9090' }
      let(:snowplow_micro_url) { "http://#{snowplow_micro_hostname}/" }

      before do
        stub_config(snowplow_micro: { enabled: true })
        allow(Gitlab::Tracking).to receive(:collector_hostname).and_return(snowplow_micro_hostname)
      end

      context 'when in production' do
        before do
          stub_rails_env('production')
        end

        it 'does not add Snowplow Micro URL to connect-src' do
          expect(connect_src).not_to include(snowplow_micro_url)
        end
      end

      context 'when in development' do
        before do
          stub_rails_env('development')
        end

        it 'adds Snowplow Micro URL with trailing slash to connect-src' do
          expect(connect_src).to match(Regexp.new(snowplow_micro_url))
        end
      end
    end

    describe 'browsersdk_tracking' do
      let(:analytics_url) { 'https://analytics.gitlab.com' }
      let(:is_gitlab_com) { true }

      before do
        allow(Gitlab).to receive(:com?).and_return(is_gitlab_com)
      end

      context 'when browsersdk_tracking is enabled, GITLAB_ANALYTICS_URL is set, and Gitlab.com? is true' do
        before do
          stub_env('GITLAB_ANALYTICS_URL', analytics_url)
        end

        it 'adds GITLAB_ANALYTICS_URL to connect-src' do
          expect(connect_src).to include(analytics_url)
        end
      end

      context 'when Gitlab.com? is false' do
        let(:is_gitlab_com) { false }

        before do
          stub_env('GITLAB_ANALYTICS_URL', analytics_url)
        end

        it 'does not add GITLAB_ANALYTICS_URL to connect-src' do
          expect(connect_src).not_to include(analytics_url)
        end
      end

      context 'when GITLAB_ANALYTICS_URL is not set' do
        before do
          stub_env('GITLAB_ANALYTICS_URL', nil)
        end

        it 'does not add GITLAB_ANALYTICS_URL to connect-src' do
          expect(connect_src).not_to include(analytics_url)
        end
      end
    end
  end

  describe '#load' do
    let(:default_directives) { described_class.default_directives }

    subject { described_class.new(csp_config[:directives]) }

    def expected_config(directive)
      csp_config[:directives][directive].split(' ').map(&:strip)
    end

    it 'sets the policy properly' do
      subject.load(policy)

      expect(policy.directives['base-uri']).to eq([csp_config[:directives][:base_uri]])
      expect(policy.directives['default-src']).to eq(expected_config(:default_src))
      expect(policy.directives['connect-src']).to eq(expected_config(:connect_src))
      expect(policy.directives['child-src']).to eq(expected_config(:child_src))
      expect(policy.directives['worker-src']).to eq(expected_config(:worker_src))
      expect(policy.directives['report-uri']).to eq(expected_config(:report_uri))
    end

    it 'ignores malformed policy statements' do
      csp_config[:directives][:base_uri] = 123

      subject.load(policy)

      expect(policy.directives['base-uri']).to be_nil
    end

    it 'returns default values for directives not defined by the user or with <default_value> and disables directives set to false' do
      # Explicitly disabling script_src and setting report_uri
      csp_config[:directives] = {
        script_src: false,
        style_src: '<default_value>',
        report_uri: 'https://example.org'
      }

      subject.load(policy)

      expected_policy = ActionDispatch::ContentSecurityPolicy.new
      # Creating a policy from default settings and manually overriding the custom values
      described_class.new(default_directives).load(expected_policy)
      expected_policy.script_src(nil)
      expected_policy.report_uri('https://example.org')

      expect(policy.directives).to eq(expected_policy.directives)
    end
  end
end
