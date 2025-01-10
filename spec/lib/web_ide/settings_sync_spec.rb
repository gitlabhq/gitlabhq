# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebIde::SettingsSync, feature_category: :web_ide do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:disabled_vscode_settings) { { enabled: false } }
  let_it_be(:enabled_vscode_settings) do
    { enabled: true,
      vscode_settings: { service_url: 'https://example.com', item_url: 'https://example.com', resource_template_url: 'https://example.com' } }
  end

  describe '#settings_context_hash' do
    where(:extensions_gallery_settings, :expectation) do
      ref(:enabled_vscode_settings)  | 'c6620244fe72864fa8d8'
      ref(:disabled_vscode_settings) | nil
    end

    subject(:settings_context_hash) do
      described_class.settings_context_hash(extensions_gallery_settings: extensions_gallery_settings)
    end

    with_them do
      it { is_expected.to eq(expectation) }
    end
  end
end
