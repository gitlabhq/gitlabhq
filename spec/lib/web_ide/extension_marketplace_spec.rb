# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebIde::ExtensionMarketplace, feature_category: :web_ide do
  using RSpec::Parameterized::TableSyntax

  let(:help_url) { "/help/user/project/web_ide/_index.md#extension-marketplace" }
  let(:user_preferences_url) { "/-/profile/preferences#integrations" }
  let(:custom_home_url) { 'https://example.com:8444' }
  let(:custom_app_setting) do
    {
      enabled: true,
      preset: "custom",
      custom_values: {
        item_url: "https://example.com:8444/vscode/item",
        service_url: "https://example.com:8444/vscode/service",
        resource_url_template: "https://example.com:8444/vscode/resource"
      }
    }
  end

  let(:open_vsx_app_setting) { custom_app_setting.merge(preset: 'open_vsx') }

  let_it_be_with_reload(:current_user) { create(:user) }

  describe 'feature enabled methods' do
    where(:vscode_web_ide, :web_ide_extensions_marketplace, :vscode_extension_marketplace_settings, :app_setting,
      :expectation) do
      ref(:current_user) | ref(:current_user) | false | {}                | true
      ref(:current_user) | ref(:current_user) | true  | {}                | false
      ref(:current_user) | ref(:current_user) | true  | { enabled: true } | true
      ref(:current_user) | false              | false | { enabled: true } | false
      false              | ref(:current_user) | false | {}                | false
    end

    with_them do
      before do
        stub_feature_flags(
          vscode_web_ide: vscode_web_ide,
          web_ide_extensions_marketplace: web_ide_extensions_marketplace,
          vscode_extension_marketplace_settings: vscode_extension_marketplace_settings
        )

        stub_application_setting(vscode_extension_marketplace: app_setting)
      end

      describe '#feature_enabled?' do
        it { expect(described_class.feature_enabled?(user: current_user)).to be(expectation) }
      end

      describe '#feature_enabled_for_any_user?' do
        it { expect(described_class.feature_enabled_for_any_user?).to be(expectation) }
      end
    end
  end

  describe '#feature_enabled_from_application_settings?' do
    where(:vscode_extension_marketplace_settings, :app_setting, :user_arg, :expectation) do
      false              | {}                 | ref(:current_user) | true
      false              | { enabled: true }  | ref(:current_user) | true
      false              | { enabled: true }  | nil                | true
      ref(:current_user) | { enabled: true }  | nil                | true
      ref(:current_user) | { enabled: true }  | ref(:current_user) | true
      ref(:current_user) | {}                 | ref(:current_user) | false
      ref(:current_user) | { enabled: false } | ref(:current_user) | false
    end

    subject(:enabled) do
      described_class.feature_enabled_from_application_settings?(user: user_arg)
    end

    with_them do
      before do
        stub_feature_flags(vscode_extension_marketplace_settings: vscode_extension_marketplace_settings)
        stub_application_setting(vscode_extension_marketplace: app_setting)
      end

      it { is_expected.to be(expectation) }
    end
  end

  describe '#marketplace_home_url' do
    where(:vscode_extension_marketplace_settings, :app_setting, :expectation) do
      false | {}                         | "https://open-vsx.org"
      true  | {}                         | "https://open-vsx.org"
      true  | ref(:custom_app_setting)   | "https://example.com:8444"
      true  | ref(:open_vsx_app_setting) | "https://open-vsx.org"
    end

    subject(:marketplace_home_url) do
      described_class.marketplace_home_url(user: current_user)
    end

    with_them do
      before do
        stub_feature_flags(vscode_extension_marketplace_settings: vscode_extension_marketplace_settings)
        stub_application_setting(vscode_extension_marketplace: app_setting)
      end

      it { is_expected.to eq(expectation) }
    end
  end

  describe '#help_preferences_url' do
    subject(:url) { described_class.help_preferences_url }

    it { is_expected.to match('/help/user/profile/preferences.md#integrate-with-the-extension-marketplace') }
  end

  describe '#webide_extension_marketplace_settings' do
    # rubocop:disable Layout/LineLength -- last parameter extens past line but is preferable to rubocop's suggestion
    where(:web_ide_extensions_marketplace, :vscode_extension_marketplace_settings, :app_setting, :opt_in_status, :opt_in_url, :expectation) do
      # web_ide_extensions_marketplace | vscode_extension_marketplace_settings | app_setting                | opt_in_status | opt_in_url            | expectation
      true                            | false                                 | {}                         | :enabled      | nil                   | lazy { { enabled: true, vscode_settings: ::WebIde::ExtensionMarketplacePreset.open_vsx.values } }
      true                            | false                                 | {}                         | :unset        | nil                   | lazy { { enabled: false, reason: :opt_in_unset, help_url: /#{help_url}/, user_preferences_url: /#{user_preferences_url}/ } }
      true                            | false                                 | {}                         | :disabled     | nil                   | lazy { { enabled: false, reason: :opt_in_disabled, help_url: /#{help_url}/, user_preferences_url: /#{user_preferences_url}/ } }
      false                           | false                                 | {}                         | :enabled      | nil                   | lazy { { enabled: false, reason: :instance_disabled, help_url: /#{help_url}/ } }
      true                            | true                                  | {}                         | :enabled      | nil                   | lazy { { enabled: false, reason: :instance_disabled, help_url: /#{help_url}/ } }
      true                            | true                                  | { enabled: false }         | :enabled      | nil                   | lazy { { enabled: false, reason: :instance_disabled, help_url: /#{help_url}/ } }
      true                            | true                                  | ref(:custom_app_setting)   | :enabled      | nil                   | lazy { { enabled: false, reason: :opt_in_unset, help_url: /#{help_url}/, user_preferences_url: /#{user_preferences_url}/ } }
      true                            | true                                  | ref(:custom_app_setting)   | :enabled      | ref(:custom_home_url) | lazy { { enabled: true, vscode_settings: custom_app_setting[:custom_values] } }
      true                            | true                                  | ref(:open_vsx_app_setting) | :enabled      | nil                   | lazy { { enabled: true, vscode_settings: ::WebIde::ExtensionMarketplacePreset.open_vsx.values } }
    end
    # rubocop:enable Layout/LineLength

    subject(:webide_settings) { described_class.webide_extension_marketplace_settings(user: current_user) }

    before do
      stub_feature_flags(
        vscode_extension_marketplace_settings: vscode_extension_marketplace_settings,
        web_ide_extensions_marketplace: web_ide_extensions_marketplace,
        vscode_web_ide: true
      )

      stub_application_setting(vscode_extension_marketplace: app_setting)

      current_user.update!(
        extensions_marketplace_opt_in_status: opt_in_status,
        extensions_marketplace_opt_in_url: opt_in_url
      )
    end

    with_them do
      it { is_expected.to match(expectation) }
    end
  end
end
