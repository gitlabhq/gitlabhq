# frozen_string_literal: true

require 'spec_helper'

describe 'layouts/_head' do
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

    expect(rendered).to match('<link rel="stylesheet" media="all" href="/stylesheets/highlight/themes/solarised-light.css" />')
  end

  context 'when an asset_host is set and snowplow url is set' do
    let(:asset_host) { 'http://test.host' }

    before do
      allow(ActionController::Base).to receive(:asset_host).and_return(asset_host)
      allow(Gitlab::CurrentSettings).to receive(:snowplow_enabled?).and_return(true)
      allow(Gitlab::CurrentSettings).to receive(:snowplow_collector_hostname).and_return('www.snow.plow')
    end

    it 'adds a snowplow script tag with asset host' do
      render
      expect(rendered).to match('http://test.host/assets/snowplow/')
      expect(rendered).to match('window.snowplow')
      expect(rendered).to match('www.snow.plow')
    end
  end

  context 'when a Piwik config is set' do
    let(:piwik_host) { 'piwik.example.com' }

    before do
      stub_config(extra: {
                    piwik_url: piwik_host,
                    piwik_site_id: 12345
                  })
    end

    it 'add a Piwik Javascript' do
      render

      expect(rendered).to match(/<script.*>.*var u="\/\/#{piwik_host}\/".*<\/script>/m)
      expect(rendered).to match(%r(<noscript>.*<img src="//#{piwik_host}/piwik.php.*</noscript>))
    end
  end

  def stub_helper_with_safe_string(method)
    allow_any_instance_of(PageLayoutHelper).to receive(method)
      .and_return(%q{foo" http-equiv="refresh}.html_safe)
  end
end
