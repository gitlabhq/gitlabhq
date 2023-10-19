# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AssetProxy do
  context 'when asset proxy is disabled' do
    before do
      stub_asset_proxy_setting(enabled: false)
    end

    it 'returns the original URL' do
      url = 'http://example.com/test.png'

      expect(described_class.proxy_url(url)).to eq(url)
    end
  end

  context 'when asset proxy is enabled' do
    before do
      stub_asset_proxy_setting(allowlist: %w[gitlab.com *.mydomain.com])
      stub_asset_proxy_setting(
        enabled: true,
        url: 'https://assets.example.com',
        secret_key: 'shared-secret',
        domain_regexp: Banzai::Filter::AssetProxyFilter.compile_allowlist(Gitlab.config.asset_proxy.allowlist)
      )
    end

    it 'returns a proxied URL' do
      url = 'http://example.com/test.png'
      proxied_url = 'https://assets.example.com/08df250eeeef1a8cf2c761475ac74c5065105612/687474703a2f2f6578616d706c652e636f6d2f746573742e706e67'

      expect(described_class.proxy_url(url)).to eq(proxied_url)
    end

    it 'returns original URL for invalid domains' do
      url = 'foo_bar://'

      expect(described_class.proxy_url(url)).to eq(url)
    end

    context 'whitelisted domain' do
      it 'returns original URL for single domain whitelist' do
        url = 'http://gitlab.com/${default_branch}/test.png'

        expect(described_class.proxy_url(url)).to eq(url)
      end

      it 'returns original URL for wildcard subdomain whitelist' do
        url = 'http://test.mydomain.com/test.png'

        expect(described_class.proxy_url(url)).to eq(url)
      end
    end
  end
end
