# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '1_settings', feature_category: :shared do
  include_context 'when loading 1_settings initializer'

  it 'settings do not change after reload', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/501317' do
    original_settings = Settings.to_h

    load_settings

    new_settings = Settings.to_h

    # Gitlab::Pages::Settings is a SimpleDelegator, so each time the settings
    # are reloaded a new SimpleDelegator wraps the original object. Convert
    # the settings to a Hash to ensure the comparison works.
    [new_settings, original_settings].each do |settings|
      settings['pages'] = settings['pages'].to_h
    end
    expect(new_settings).to eq(original_settings)
  end

  describe 'DNS rebinding protection' do
    subject(:dns_rebinding_protection_enabled) { Settings.gitlab.dns_rebinding_protection_enabled }

    let(:http_proxy) { nil }

    before do
      # Reset it, because otherwise we might memoize the value across tests.
      Settings.gitlab['dns_rebinding_protection_enabled'] = nil
      stub_env('http_proxy', http_proxy)
      load_settings
    end

    it { is_expected.to be(true) }

    context 'when an HTTP proxy environment variable is set' do
      let(:http_proxy) { 'http://myproxy.com:8080' }

      it { is_expected.to be(false) }
    end
  end

  describe 'log_decompressed_response_bytesize' do
    it { expect(Settings.gitlab.log_decompressed_response_bytesize).to eq(0) }

    context 'when GITLAB_LOG_DECOMPRESSED_RESPONSE_BYTESIZE is set' do
      before do
        stub_env('GITLAB_LOG_DECOMPRESSED_RESPONSE_BYTESIZE', '10')
        load_settings
      end

      it { expect(Settings.gitlab.log_decompressed_response_bytesize).to eq(10) }
    end
  end

  describe 'initial_gitlab_product_usage_data' do
    it 'is enabled by default' do
      Settings.gitlab['initial_gitlab_product_usage_data'] = nil
      load_settings

      expect(Settings.gitlab.initial_gitlab_product_usage_data).to be(true)
    end

    context 'when explicitly set' do
      before do
        Settings.gitlab['initial_gitlab_product_usage_data'] = false
        load_settings
      end

      it 'uses the configured value' do
        expect(Settings.gitlab.initial_gitlab_product_usage_data).to be(false)
      end
    end
  end

  describe 'cell configuration' do
    let(:config) do
      {
        address: 'test-topology-service-host:8080',
        ca_file: '/test/topology-service-ca.pem',
        certificate_file: '/test/topology-service-cert.pem',
        private_key_file: '/test/topology-service-key.pem'
      }
    end

    context 'when legacy topology service client config is provided as a top-level key' do
      before do
        stub_config({ cell: { enabled: true, id: 1 }, topology_service: config })
        load_settings
      end

      it { expect(Settings.cell.topology_service_client.address).to eq(config[:address]) }
      it { expect(Settings.cell.topology_service_client.ca_file).to eq(config[:ca_file]) }
      it { expect(Settings.cell.topology_service_client.certificate_file).to eq(config[:certificate_file]) }
      it { expect(Settings.cell.topology_service_client.private_key_file).to eq(config[:private_key_file]) }
    end

    context 'when topology service client config is provided as a key nested' do
      before do
        stub_config({ cell: { enabled: true, id: 1, topology_service_client: config } })
        load_settings
      end

      it { expect(Settings.cell.topology_service_client.address).to eq(config[:address]) }
      it { expect(Settings.cell.topology_service_client.ca_file).to eq(config[:ca_file]) }
      it { expect(Settings.cell.topology_service_client.certificate_file).to eq(config[:certificate_file]) }
      it { expect(Settings.cell.topology_service_client.private_key_file).to eq(config[:private_key_file]) }
    end
  end

  describe 'Pages custom domains settings' do
    using RSpec::Parameterized::TableSyntax

    where(:external_http, :external_https, :initial_custom_domain_mode, :expected_custom_domain_mode) do
      nil   | true  | nil     | 'https'
      true  | nil   | nil     | 'http'
      true  | true  | nil     | 'https'
      nil   | nil   | 'https' | 'https'
      false | false | 'http'  | 'http'
      nil   | true  | 'http'  | 'https'
      nil   | nil   | nil     | nil
    end

    with_them do
      before do
        stub_config(pages: {
          enabled: true,
          external_http: external_http,
          external_https: external_https,
          custom_domain_mode: initial_custom_domain_mode
        })

        allow(Settings.pages).to receive(:__getobj__).and_return(Settings.pages)
      end

      it 'sets the expected custom_domain_mode value' do
        load_settings

        expect(Settings.pages['custom_domain_mode']).to eq(expected_custom_domain_mode)
      end
    end
  end

  describe 'ci_id_tokens_issuer_url' do
    after do
      Settings.ci_id_tokens['issuer_url'] = nil
      load_settings
    end

    it 'is set as Settings.gitlab.url by default' do
      Settings.ci_id_tokens['issuer_url'] = nil
      load_settings

      expect(Settings.ci_id_tokens.issuer_url).to eq Settings.gitlab.url
    end

    it 'uses the configured value' do
      Settings.ci_id_tokens['issuer_url'] = 'https://example.com'
      load_settings

      expect(Settings.ci_id_tokens.issuer_url).to eq('https://example.com')
    end
  end
end
