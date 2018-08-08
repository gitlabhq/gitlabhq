require 'spec_helper'

describe 'layouts/_head' do
  before do
    allow(view).to receive(:current_application_settings).and_return(Gitlab::CurrentSettings.current_application_settings)
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

  context 'when an asset_host is set and feature is activated in the config it will' do
    let(:asset_host) { 'http://assets' }

    before do
      stub_feature_flags(asset_host_prefetch: true)
      allow(ActionController::Base).to receive(:asset_host).and_return(asset_host)
    end

    it 'add a link dns-prefetch tag' do
      render
      expect(rendered).to match('<link href="http://assets" rel="dns-prefetch">')
    end

    it 'add a link preconnect tag' do
      render
      expect(rendered).to match('<link crossorigin="" href="http://assets" rel="preconnnect">')
    end
  end

  context 'when an asset_host is set and feature is not activated in the config it will' do
    let(:asset_host) { 'http://assets' }

    before do
      stub_feature_flags(asset_host_prefetch: false)
      allow(ActionController::Base).to receive(:asset_host).and_return(asset_host)
    end

    it 'not add a link dns-prefetch tag' do
      render
      expect(rendered).not_to match('<link href="http://assets" rel="dns-prefetch">')
    end
  end

  context 'when an asset_host is set and snowplow url is set' do
    let(:asset_host) { 'http://test.host' }

    before do
      allow(ActionController::Base).to receive(:asset_host).and_return(asset_host)
      allow(Gitlab::CurrentSettings).to receive(:snowplow_enabled?).and_return(true)
      allow(Gitlab::CurrentSettings).to receive(:snowplow_collector_uri).and_return('www.snow.plow')
    end

    it 'add a snowplow script tag with asset host' do
      render
      expect(rendered).to match('http://test.host/assets/shared/snowplow/')
      expect(rendered).to match('window.snowplow')
      expect(rendered).to match('www.snow.plow')
    end
  end

  def stub_helper_with_safe_string(method)
    allow_any_instance_of(PageLayoutHelper).to receive(method)
      .and_return(%q{foo" http-equiv="refresh}.html_safe)
  end
end
