# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::AssetProxyFilter, feature_category: :markdown do
  include FilterSpecHelper

  def image(path)
    %(<img src="#{path}" />)
  end

  it 'does not replace if disabled' do
    stub_asset_proxy_setting(enabled: false)

    context = described_class.transform_context({})
    src     = 'http://example.com/test.png'
    doc     = filter(image(src), context)

    expect(doc.at_css('img')['src']).to eq src
  end

  context 'during initialization' do
    after do
      Gitlab.config.asset_proxy['enabled'] = false
    end

    it '#initialize_settings' do
      stub_application_setting(asset_proxy_enabled: true)
      stub_application_setting(asset_proxy_secret_key: 'shared-secret')
      stub_application_setting(asset_proxy_url: 'https://assets.example.com')
      stub_application_setting(asset_proxy_allowlist: %w[gitlab.com *.mydomain.com])

      described_class.initialize_settings

      expect(Gitlab.config.asset_proxy.enabled).to be_truthy
      expect(Gitlab.config.asset_proxy.secret_key).to eq 'shared-secret'
      expect(Gitlab.config.asset_proxy.url).to eq 'https://assets.example.com'
      expect(Gitlab.config.asset_proxy.allowlist).to eq %w[gitlab.com *.mydomain.com]
      expect(Gitlab.config.asset_proxy.domain_regexp).to eq(/^(gitlab\.com|.*?\.mydomain\.com)$/i)
    end

    context 'when allowlist is empty' do
      it 'defaults to the install domain' do
        stub_application_setting(asset_proxy_enabled: true)
        stub_application_setting(asset_proxy_allowlist: [])

        described_class.initialize_settings

        expect(Gitlab.config.asset_proxy.allowlist).to eq [Gitlab.config.gitlab.host]
      end
    end

    it 'supports deprecated whitelist settings' do
      stub_application_setting(asset_proxy_enabled: true)
      stub_application_setting(asset_proxy_whitelist: %w[foo.com bar.com])
      stub_application_setting(asset_proxy_allowlist: [])

      described_class.initialize_settings

      expect(Gitlab.config.asset_proxy.allowlist).to eq %w[foo.com bar.com]
    end
  end

  context 'when properly configured' do
    using RSpec::Parameterized::TableSyntax

    before do
      stub_asset_proxy_setting(enabled: true)
      stub_asset_proxy_setting(secret_key: 'shared-secret')
      stub_asset_proxy_setting(url: 'https://assets.example.com')
      stub_asset_proxy_setting(allowlist: %W[gitlab.com *.mydomain.com #{Gitlab.config.gitlab.host}])
      stub_asset_proxy_setting(domain_regexp: described_class.compile_allowlist(Gitlab.config.asset_proxy.allowlist))
      @context = described_class.transform_context({})
    end

    where(:data_canonical_src, :src) do
      'http://example.com/test.png' | 'https://assets.example.com/08df250eeeef1a8cf2c761475ac74c5065105612/687474703a2f2f6578616d706c652e636f6d2f746573742e706e67'
      '///example.com/test.png' | 'https://assets.example.com/3368d2c7b9bed775bdd1e811f36a4b80a0dcd8ab/2f2f2f6578616d706c652e636f6d2f746573742e706e67'
      '//example.com/test.png' | 'https://assets.example.com/a2e9aa56319e31bbd05be72e633f2864ff08becb/2f2f6578616d706c652e636f6d2f746573742e706e67'
      # If it can't be parsed, default to use asset proxy
      'oigjsie8787%$**(#(%0' | 'https://assets.example.com/1b893f9a71d66c99437f27e19b9a061a6f5d9391/6f69676a7369653837383725242a2a2823282530'
      'https://example.com/x?¬' | 'https://assets.example.com/2f29a8c7f13f3ae14dc18c154dbbd657d703e75f/68747470733a2f2f6578616d706c652e636f6d2f783fc2ac'
      # The browser loads this as if it was a valid URL
      'http:example.com' | 'https://assets.example.com/bcefecd18484ec2850887d6730273e5e70f5ed1a/687474703a6578616d706c652e636f6d'
      'https:example.com' | 'https://assets.example.com/648e074361143780357db0b5cf73d4438d5484d3/68747470733a6578616d706c652e636f6d'
      'https://example.com/##' | 'https://assets.example.com/d7d0c845cc553d9430804c07e9456545ef3e6fe6/68747470733a2f2f6578616d706c652e636f6d2f2323'
      nil | "test.png"
      nil | "/test.png"
      nil | "#{Gitlab.config.gitlab.url}/test.png"
      nil | 'http://gitlab.com/test.png'
      nil | 'http://gitlab.com/test.png?url=http://example.com/test.png'
      nil | 'http://images.mydomain.com/test.png'
    end

    with_them do
      it 'correctly modifies the img tag' do
        original_url = data_canonical_src || src
        doc = filter(image(original_url), @context)

        expect(doc.at_css('img')['src']).to eq src
        expect(doc.at_css('img')['data-canonical-src']).to eq data_canonical_src
      end
    end
  end

  it_behaves_like 'pipeline timing check', context: { disable_asset_proxy: true }
end
