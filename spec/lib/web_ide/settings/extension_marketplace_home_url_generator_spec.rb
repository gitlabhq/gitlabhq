# frozen_string_literal: true

require "fast_spec_helper"

RSpec.describe WebIde::Settings::ExtensionMarketplaceHomeUrlGenerator, feature_category: :web_ide do
  using RSpec::Parameterized::TableSyntax

  let(:vscode_extension_marketplace) { {} }
  let(:requested_setting_names) { [:vscode_extension_marketplace_home_url] }
  let(:context) do
    {
      requested_setting_names: requested_setting_names,
      settings: {
        vscode_extension_marketplace: vscode_extension_marketplace
      }
    }
  end

  subject(:result) { described_class.generate(context)[:settings][:vscode_extension_marketplace_home_url] }

  where(:requested_setting_names, :vscode_extension_marketplace, :expectation) do
    [:vscode_extension_marketplace_home_url] | {}                                          | ''
    [:vscode_extension_marketplace_home_url] | { item_url: 'https://example.com/foo/bar' } | 'https://example.com'
    [:vscode_extension_marketplace_home_url] | { item_url: 'https://example.com:123/foo' } | 'https://example.com:123'
    [:vscode_extension_marketplace_home_url] | { item_url: 'not really a thing...' }       | ''
    []                                       | { item_url: 'https://example.com:123/foo' } | nil
  end

  with_them do
    it { is_expected.to eq(expectation) }
  end
end
