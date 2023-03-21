# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ContentSecurityPolicy::ConfigLoader do
  let(:policy) { ActionDispatch::ContentSecurityPolicy.new }
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

  describe '.default_enabled' do
    let(:enabled) { described_class.default_enabled }

    it 'is enabled' do
      expect(enabled).to be_truthy
    end

    context 'when in production' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      end

      it 'is disabled' do
        expect(enabled).to be_falsey
      end
    end
  end

  describe '.default_directives' do
    let(:directives) { described_class.default_directives }

    it 'returns default directives' do
      directive_names = (described_class::DIRECTIVES - ['report_uri'])
      directive_names.each do |directive|
        expect(directives.has_key?(directive)).to be_truthy
        expect(directives[directive]).to be_truthy
      end

      expect(directives.has_key?('report_uri')).to be_truthy
      expect(directives['report_uri']).to be_nil
      expect(directives['child_src']).to eq("#{directives['frame_src']} #{directives['worker_src']}")
    end

    describe 'the images-src directive' do
      it 'can be loaded from anywhere' do
        expect(directives['img_src']).to include('http: https:')
      end
    end

    describe 'the media-src directive' do
      it 'can be loaded from anywhere' do
        expect(directives['media_src']).to include('http: https:')
      end
    end

    context 'adds all websocket origins to support Safari' do
      it 'with insecure domain' do
        stub_config_setting(host: 'example.com', https: false)
        expect(directives['connect_src']).to eq("'self' ws://example.com")
      end

      it 'with secure domain' do
        stub_config_setting(host: 'example.com', https: true)
        expect(directives['connect_src']).to eq("'self' wss://example.com")
      end

      it 'with custom port' do
        stub_config_setting(host: 'example.com', port: '1234')
        expect(directives['connect_src']).to eq("'self' ws://example.com:1234")
      end

      it 'with custom port and secure domain' do
        stub_config_setting(host: 'example.com', https: true, port: '1234')
        expect(directives['connect_src']).to eq("'self' wss://example.com:1234")
      end
    end

    context 'when CDN host is defined' do
      before do
        stub_config_setting(cdn_host: 'https://cdn.example.com')
      end

      it 'adds CDN host to CSP' do
        expect(directives['script_src']).to eq(::Gitlab::ContentSecurityPolicy::Directives.script_src + " https://cdn.example.com")
        expect(directives['style_src']).to eq(::Gitlab::ContentSecurityPolicy::Directives.style_src + " https://cdn.example.com")
        expect(directives['font_src']).to eq("'self' https://cdn.example.com")
        expect(directives['worker_src']).to eq('http://localhost/assets/ blob: data: https://cdn.example.com')
        expect(directives['frame_src']).to eq(::Gitlab::ContentSecurityPolicy::Directives.frame_src + " https://cdn.example.com http://localhost/admin/ http://localhost/assets/ http://localhost/-/speedscope/index.html http://localhost/-/sandbox/")
      end
    end

    describe 'Zuora directives' do
      context 'when on SaaS', :saas do
        it 'adds Zuora host to CSP' do
          expect(directives['frame_src']).to include('https://*.zuora.com/apps/PublicHostedPageLite.do')
        end
      end

      context 'when is not Gitlab.com?' do
        it 'does not add Zuora host to CSP' do
          expect(directives['frame_src']).not_to include('https://*.zuora.com/apps/PublicHostedPageLite.do')
        end
      end
    end

    context 'when sentry is configured' do
      let(:legacy_dsn) { 'dummy://abc@legacy-sentry.example.com/1' }
      let(:dsn) { 'dummy://def@sentry.example.com/2' }

      before do
        stub_config_setting(host: 'gitlab.example.com')
      end

      context 'when legacy sentry is configured' do
        before do
          allow(Gitlab.config.sentry).to receive(:enabled).and_return(true)
          allow(Gitlab.config.sentry).to receive(:clientside_dsn).and_return(legacy_dsn)
          allow(Gitlab::CurrentSettings).to receive(:sentry_enabled).and_return(false)
        end

        it 'adds legacy sentry path to CSP' do
          expect(directives['connect_src']).to eq("'self' ws://gitlab.example.com dummy://legacy-sentry.example.com")
        end
      end

      context 'when sentry is configured' do
        before do
          allow(Gitlab.config.sentry).to receive(:enabled).and_return(false)
          allow(Gitlab::CurrentSettings).to receive(:sentry_enabled).and_return(true)
          allow(Gitlab::CurrentSettings).to receive(:sentry_clientside_dsn).and_return(dsn)
        end

        it 'adds new sentry path to CSP' do
          expect(directives['connect_src']).to eq("'self' ws://gitlab.example.com dummy://sentry.example.com")
        end
      end

      context 'when sentry settings are from older schemas and sentry setting are missing' do
        before do
          allow(Gitlab.config.sentry).to receive(:enabled).and_return(false)

          allow(Gitlab::CurrentSettings).to receive(:respond_to?).with(:sentry_enabled).and_return(false)
          allow(Gitlab::CurrentSettings).to receive(:sentry_enabled).and_raise(NoMethodError)

          allow(Gitlab::CurrentSettings).to receive(:respond_to?).with(:sentry_clientside_dsn).and_return(false)
          allow(Gitlab::CurrentSettings).to receive(:sentry_clientside_dsn).and_raise(NoMethodError)
        end

        it 'config is backwards compatible, does not add sentry path to CSP' do
          expect(directives['connect_src']).to eq("'self' ws://gitlab.example.com")
        end
      end

      context 'when legacy sentry and sentry are both configured' do
        before do
          allow(Gitlab.config.sentry).to receive(:enabled).and_return(true)
          allow(Gitlab.config.sentry).to receive(:clientside_dsn).and_return(legacy_dsn)

          allow(Gitlab::CurrentSettings).to receive(:sentry_enabled).and_return(true)
          allow(Gitlab::CurrentSettings).to receive(:sentry_clientside_dsn).and_return(dsn)
        end

        it 'adds both sentry paths to CSP' do
          expect(directives['connect_src']).to eq("'self' ws://gitlab.example.com dummy://legacy-sentry.example.com dummy://sentry.example.com")
        end
      end
    end

    context 'when CUSTOMER_PORTAL_URL is set' do
      let(:customer_portal_url) { 'https://customers.example.com' }

      before do
        stub_env('CUSTOMER_PORTAL_URL', customer_portal_url)
      end

      it 'adds CUSTOMER_PORTAL_URL to CSP' do
        expect(directives['frame_src']).to eq(::Gitlab::ContentSecurityPolicy::Directives.frame_src + " http://localhost/admin/ http://localhost/assets/ http://localhost/-/speedscope/index.html http://localhost/-/sandbox/ #{customer_portal_url}")
      end
    end

    context 'letter_opener application URL' do
      let(:gitlab_url) { 'http://gitlab.example.com' }
      let(:letter_opener_url) { "#{gitlab_url}/rails/letter_opener/" }

      before do
        stub_config_setting(url: gitlab_url)
      end

      context 'when in production' do
        before do
          allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
        end

        it 'does not add letter_opener to CSP' do
          expect(directives['frame_src']).not_to include(letter_opener_url)
        end
      end

      context 'when in development' do
        before do
          allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
        end

        it 'adds letter_opener to CSP' do
          expect(directives['frame_src']).to include(letter_opener_url)
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
          expect(directives['connect_src']).not_to include(snowplow_micro_url)
        end
      end

      context 'when in development' do
        before do
          stub_rails_env('development')
        end

        it 'adds Snowplow Micro URL with trailing slash to connect-src' do
          expect(directives['connect_src']).to match(Regexp.new(snowplow_micro_url))
        end

        context 'when not enabled using config' do
          before do
            stub_config(snowplow_micro: { enabled: false })
          end

          it 'does not add Snowplow Micro URL to connect-src' do
            expect(directives['connect_src']).not_to include(snowplow_micro_url)
          end
        end

        context 'when REVIEW_APPS_ENABLED is set' do
          before do
            stub_env('REVIEW_APPS_ENABLED', 'true')
          end

          it 'adds gitlab-org/gitlab merge requests API endpoint to CSP' do
            expect(directives['connect_src']).to include('https://gitlab.com/api/v4/projects/278964/merge_requests/')
          end
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
