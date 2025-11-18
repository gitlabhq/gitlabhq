# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_extension_marketplace', feature_category: :web_ide do
  subject(:page) do
    # We use `view.render`, because just `render` throws a "no implicit conversion of nil into String" exception
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/53093#note_499060593
    view.assign({ application_setting: build(:application_setting) })
    rendered = view.render('admin/application_settings/extension_marketplace')

    rendered && Nokogiri::HTML.parse(rendered)
  end

  it 'renders settings' do
    settings = page.at('#js-extension-marketplace-settings')

    expect(settings).not_to be_nil
    expect(settings).to have_text(_('VS Code Extension Marketplace'))
    expect(settings).to have_text(
      _('Enable VS Code Extension Marketplace and configure the extensions registry for Web IDE.')
    )
  end

  it 'renders data-view-model for vue app' do
    vue_app = page.at('#js-extension-marketplace-settings-app')
    expected_presets = ::WebIde::ExtensionMarketplacePreset.all.map do |x|
      {
        key: x.key,
        name: x.name,
        values: {
          serviceUrl: x.values[:service_url],
          itemUrl: x.values[:item_url],
          resourceUrlTemplate: x.values[:resource_url_template]
        }
      }
    end

    expected_json = {
      presets: expected_presets,
      initialSettings: { enabled: false, extension_host_domain: "cdn.web-ide.gitlab-static.net" }
    }.to_json

    expect(vue_app).not_to be_nil
    expect(vue_app['data-view-model']).to eq(expected_json)
  end

  it 'renders link to the extension marketplace admin docs' do
    expect(page).to have_link(href: help_page_path('administration/settings/vscode_extension_marketplace.md'))
  end
end
