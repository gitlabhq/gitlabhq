# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebIde::SettingsSync, feature_category: :web_ide do
  describe '#settings_context_hash' do
    where do
      {
        "disabled vscode settings" => {
          enabled: false,
          vscode_settings: {
            service_url: 'https://example.com',
            item_url: 'https://example.com',
            resource_url_template: 'https://example.com'
          },
          expectation: nil
        },
        "enabled vscode settings" => {
          enabled: true,
          vscode_settings: {
            service_url: 'https://example.com',
            item_url: 'https://example.com',
            resource_url_template: 'https://example.com'
          },
          expectation: 'c6620244fe72864fa8d8'
        },
        "default vscode settings" => {
          enabled: true,
          vscode_settings: {
            service_url: 'https://open-vsx.org/vscode/gallery',
            item_url: 'https://open-vsx.org/vscode/item',
            resource_url_template: 'https://open-vsx.org/vscode/asset/{publisher}/{name}/{version}/Microsoft.VisualStudio.Code.WebResources/{path}'
          },
          expectation: '2e0d3e8c1107f9ccc5ea'
        },
        "default vscode settings (compatability after bug fix)" => {
          # This is the default vscode settings that creates the same
          # hash as default_vscode_settings to avoid breaking-changes.
          # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178491
          enabled: true,
          vscode_settings: {
            service_url: 'https://open-vsx.org/vscode/gallery',
            item_url: 'https://open-vsx.org/vscode/item',
            resource_url_template: ''
          },
          expectation: '2e0d3e8c1107f9ccc5ea'
        },
        "vscode settings with different resource_url_template" => {
          # We want to verify that a different resource_url_template (not empty) will generate a different hash
          enabled: true,
          vscode_settings: {
            service_url: 'https://open-vsx.org/vscode/gallery',
            item_url: 'https://open-vsx.org/vscode/item',
            resource_url_template: 'https://example.com/'
          },
          expectation: '576b985920ef0d6bb244'
        }
      }
    end

    subject(:settings_context_hash) do
      described_class.settings_context_hash(extensions_gallery_settings: {
        enabled: enabled,
        vscode_settings: vscode_settings
      })
    end

    with_them do
      it { is_expected.to eq(expectation) }
    end
  end
end
