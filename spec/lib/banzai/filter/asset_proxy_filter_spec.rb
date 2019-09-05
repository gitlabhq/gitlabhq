require 'spec_helper'

describe Banzai::Filter::AssetProxyFilter do
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
      stub_application_setting(asset_proxy_whitelist: %w(gitlab.com *.mydomain.com))

      described_class.initialize_settings

      expect(Gitlab.config.asset_proxy.enabled).to be_truthy
      expect(Gitlab.config.asset_proxy.secret_key).to eq 'shared-secret'
      expect(Gitlab.config.asset_proxy.url).to eq 'https://assets.example.com'
      expect(Gitlab.config.asset_proxy.whitelist).to eq %w(gitlab.com *.mydomain.com)
      expect(Gitlab.config.asset_proxy.domain_regexp).to eq /^(gitlab\.com|.*?\.mydomain\.com)$/i
    end

    context 'when whitelist is empty' do
      it 'defaults to the install domain' do
        stub_application_setting(asset_proxy_enabled: true)
        stub_application_setting(asset_proxy_whitelist: [])

        described_class.initialize_settings

        expect(Gitlab.config.asset_proxy.whitelist).to eq [Gitlab.config.gitlab.host]
      end
    end
  end

  context 'when properly configured' do
    before do
      stub_asset_proxy_setting(enabled: true)
      stub_asset_proxy_setting(secret_key: 'shared-secret')
      stub_asset_proxy_setting(url: 'https://assets.example.com')
      stub_asset_proxy_setting(whitelist: %W(gitlab.com *.mydomain.com #{Gitlab.config.gitlab.host}))
      stub_asset_proxy_setting(domain_regexp: described_class.compile_whitelist(Gitlab.config.asset_proxy.whitelist))
      @context = described_class.transform_context({})
    end

    it 'replaces img src' do
      src     = 'http://example.com/test.png'
      new_src = 'https://assets.example.com/08df250eeeef1a8cf2c761475ac74c5065105612/687474703a2f2f6578616d706c652e636f6d2f746573742e706e67'
      doc     = filter(image(src), @context)

      expect(doc.at_css('img')['src']).to eq new_src
      expect(doc.at_css('img')['data-canonical-src']).to eq src
    end

    it 'skips internal images' do
      src      = "#{Gitlab.config.gitlab.url}/test.png"
      doc      = filter(image(src), @context)

      expect(doc.at_css('img')['src']).to eq src
    end

    it 'skip relative urls' do
      src = "/test.png"
      doc = filter(image(src), @context)

      expect(doc.at_css('img')['src']).to eq src
    end

    it 'skips single domain' do
      src = "http://gitlab.com/test.png"
      doc = filter(image(src), @context)

      expect(doc.at_css('img')['src']).to eq src
    end

    it 'skips single domain and ignores url in query string' do
      src = "http://gitlab.com/test.png?url=http://example.com/test.png"
      doc = filter(image(src), @context)

      expect(doc.at_css('img')['src']).to eq src
    end

    it 'skips wildcarded domain' do
      src = "http://images.mydomain.com/test.png"
      doc = filter(image(src), @context)

      expect(doc.at_css('img')['src']).to eq src
    end
  end
end
