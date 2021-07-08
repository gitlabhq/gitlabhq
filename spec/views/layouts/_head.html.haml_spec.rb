# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/_head' do
  include StubConfiguration

  before do
    allow(view).to receive(:current_application_settings).and_return(Gitlab::CurrentSettings.current_application_settings)
    allow(view).to receive(:experiment_enabled?).and_return(false)
  end

  it 'escapes HTML-safe strings in page_title' do
    stub_helper_with_safe_string(:page_title)

    render

    expect(rendered).to match(%{content="foo&quot; http-equiv=&quot;refresh"})
  end

  it 'escapes HTML-safe strings in page_description' do
    stub_helper_with_safe_string(:page_description)

    render

    expect(rendered).to match(%{content="foo&quot; http-equiv=&quot;refresh"})
  end

  it 'escapes HTML-safe strings in page_image' do
    stub_helper_with_safe_string(:page_image)

    render

    expect(rendered).to match(%{content="foo&quot; http-equiv=&quot;refresh"})
  end

  context 'when an asset_host is set' do
    let(:asset_host) { 'http://assets' }

    before do
      allow(ActionController::Base).to receive(:asset_host).and_return(asset_host)
    end

    it 'adds a link dns-prefetch tag' do
      render

      expect(rendered).to match(%Q(<link href="#{asset_host}" rel="dns-prefetch">))
    end

    it 'adds a link preconnect tag' do
      render

      expect(rendered).to match(%Q(<link crossorigin="" href="#{asset_host}" rel="preconnect">))
    end
  end

  it 'adds selected syntax highlight stylesheet' do
    allow_any_instance_of(PreferencesHelper).to receive(:user_color_scheme).and_return("solarised-light")

    render

    expect(rendered).to match('<link rel="stylesheet" media="print" href="/stylesheets/highlight/themes/solarised-light.css" />')
  end

  context 'when an asset_host is set and snowplow url is set' do
    let(:asset_host) { 'http://test.host' }
    let(:snowplow_collector_hostname) { 'www.snow.plow' }

    before do
      allow(ActionController::Base).to receive(:asset_host).and_return(asset_host)
      allow(Gitlab::CurrentSettings).to receive(:snowplow_enabled?).and_return(true)
      allow(Gitlab::CurrentSettings).to receive(:snowplow_collector_hostname).and_return(snowplow_collector_hostname)
    end

    it 'adds a snowplow script tag with asset host' do
      render
      expect(rendered).to match('http://test.host/assets/snowplow/')
      expect(rendered).to match('window.snowplow')
      expect(rendered).to match(snowplow_collector_hostname)
    end

    it 'adds a link preconnect tag' do
      render

      expect(rendered).to match(%Q(<link crossorigin="" href="#{snowplow_collector_hostname}" rel="preconnect">))
    end
  end

  context 'when a Matomo config is set' do
    let(:matomo_host) { 'matomo.example.com' }

    before do
      stub_config(extra: {
                    matomo_url: matomo_host,
                    matomo_site_id: 12345,
                    matomo_disable_cookies: false
                  })
    end

    it 'add a Matomo Javascript' do
      render

      expect(rendered).to match(%r{<script.*>.*var u="//#{matomo_host}/".*</script>}m)
      expect(rendered).to match(%r(<noscript>.*<img src="//#{matomo_host}/matomo.php.*</noscript>))
      expect(rendered).not_to include('_paq.push(["disableCookies"])')
    end

    context 'when matomo_disable_cookies is true' do
      before do
        stub_config(extra: { matomo_url: matomo_host, matomo_site_id: 12345, matomo_disable_cookies: true })
      end

      it 'disables cookies' do
        render

        expect(rendered).to include('_paq.push(["disableCookies"])')
      end
    end
  end

  def stub_helper_with_safe_string(method)
    allow_any_instance_of(PageLayoutHelper).to receive(method)
      .and_return(%q{foo" http-equiv="refresh}.html_safe)
  end
end
