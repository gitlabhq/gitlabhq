# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_extension_marketplace', feature_category: :web_ide do
  let(:feature_available) { true }

  subject(:page) do
    # We use `view.render`, because just `render` throws a "no implicit conversion of nil into String" exception
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/53093#note_499060593
    view.assign({ application_setting: build(:application_setting) })
    rendered = view.render('admin/application_settings/extension_marketplace')

    rendered && Nokogiri::HTML.parse(rendered)
  end

  before do
    stub_feature_flags(vscode_extension_marketplace_settings: feature_available)
  end

  context 'when feature available' do
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
        initialSettings: { enabled: false }
      }.to_json

      expect(vue_app).not_to be_nil
      expect(vue_app['data-view-model']).to eq(expected_json)
    end
  end

  context 'when feature not available' do
    let(:feature_available) { false }

    it 'renders nothing' do
      expect(page).to be_nil
    end
  end
end
