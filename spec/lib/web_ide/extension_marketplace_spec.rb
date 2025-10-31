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

  describe '#feature_enabled_from_application_settings?' do
    where(:app_setting, :expectation) do
      { enabled: true }  | true
      { enabled: false } | false
      {}                 | false
    end

    subject(:enabled) do
      described_class.feature_enabled_from_application_settings?
    end

    with_them do
      before do
        Gitlab::CurrentSettings.update!(vscode_extension_marketplace: app_setting)
      end

      it { is_expected.to be(expectation) }
    end
  end

  describe '#marketplace_home_url' do
    where(:app_setting, :expectation) do
      {}                         | "https://open-vsx.org"
      ref(:open_vsx_app_setting) | "https://open-vsx.org"
      ref(:custom_app_setting)   | "https://example.com:8444"
    end

    subject(:marketplace_home_url) do
      described_class.marketplace_home_url(user: current_user)
    end

    with_them do
      before do
        Gitlab::CurrentSettings.update!(vscode_extension_marketplace: app_setting)
      end

      it { is_expected.to eq(expectation) }
    end
  end

  describe '#help_preferences_url' do
    subject(:url) { described_class.help_preferences_url }

    it { is_expected.to match('/help/user/profile/preferences.md#integrate-with-the-extension-marketplace') }
  end

  describe '#webide_extension_marketplace_settings' do
    # rubocop:disable Layout/LineLength -- last parameter extends past line but is preferable to rubocop's suggestion
    where(:app_setting, :opt_in_status, :opt_in_url, :expectation) do
      # app_setting              | opt_in_status | opt_in_url            | expectation
      {}                         | :enabled      | nil                   | lazy { { enabled: false, reason: :instance_disabled, help_url: /#{help_url}/ } }
      { enabled: false }         | :enabled      | nil                   | lazy { { enabled: false, reason: :instance_disabled, help_url: /#{help_url}/ } }
      ref(:custom_app_setting)   | :enabled      | nil                   | lazy { { enabled: false, reason: :opt_in_unset, help_url: /#{help_url}/, user_preferences_url: /#{user_preferences_url}/ } }
      ref(:custom_app_setting)   | :enabled      | ref(:custom_home_url) | lazy { { enabled: true, vscode_settings: custom_app_setting[:custom_values] } }
      ref(:open_vsx_app_setting) | :enabled      | nil                   | lazy { { enabled: true, vscode_settings: ::WebIde::ExtensionMarketplacePreset.open_vsx.values } }
    end
    # rubocop:enable Layout/LineLength

    subject(:webide_settings) { described_class.webide_extension_marketplace_settings(user: current_user) }

    before do
      Gitlab::CurrentSettings.update!(vscode_extension_marketplace: app_setting)

      current_user.update!(
        extensions_marketplace_opt_in_status: opt_in_status,
        extensions_marketplace_opt_in_url: opt_in_url
      )
    end

    with_them do
      it { is_expected.to match(expectation) }
    end
  end

  describe '#extension_host_domain' do
    subject(:extension_host_domain) { described_class.extension_host_domain }

    context 'when vscode_extension_marketplace_extension_host_domain is set to default' do
      before do
        Gitlab::CurrentSettings.update!(
          vscode_extension_marketplace_extension_host_domain: 'cdn.web-ide.gitlab-static.net'
        )
      end

      it { is_expected.to eq('cdn.web-ide.gitlab-static.net') }
    end

    context 'when vscode_extension_marketplace_extension_host_domain is set to custom domain' do
      before do
        Gitlab::CurrentSettings.update!(
          vscode_extension_marketplace_extension_host_domain: 'custom-cdn.example.com'
        )
      end

      it { is_expected.to eq('custom-cdn.example.com') }
    end
  end

  describe '#extension_host_domain_changed?' do
    subject(:extension_host_domain_changed) { described_class.extension_host_domain_changed? }

    context 'when extension_host_domain is set to default value' do
      before do
        Gitlab::CurrentSettings.update!(
          vscode_extension_marketplace_extension_host_domain: 'cdn.web-ide.gitlab-static.net'
        )
      end

      it { is_expected.to be(false) }
    end

    context 'when extension_host_domain is set to custom domain' do
      before do
        Gitlab::CurrentSettings.update!(
          vscode_extension_marketplace_extension_host_domain: 'custom-cdn.example.com'
        )
      end

      it { is_expected.to be(true) }
    end
  end

  describe '#origin_matches_extension_host_regexp' do
    subject(:regexp) { described_class.origin_matches_extension_host_regexp }

    where(:extension_host_domain, :origin, :should_match) do
      # matches valid origins with minimum length identifier
      'web-ide.net' | 'https://abcdefghijklmnopqrstuvwxyz1234.web-ide.net' | true
      # matches valid origins with maximum length identifier
      'web-ide.net' | 'https://abcdefghijklmnopqrstuvwxyz123456789012345678901234567890.web-ide.net' | true
      # matches origins with v-- prefix
      'web-ide.net' | 'https://v--abcdefghijklmnopqrstuvwxyz1234.web-ide.net' | true
      # matches origins with workbench- prefix
      'web-ide.net' | 'https://workbench-abcdefghijklmnopqrstuvwxyz1234.web-ide.net' | true
      # matches origins with port
      'web-ide.net:3443' | 'https://workbench-abcdefghijklmnopqrstuvwxyz1234.web-ide.net:3443' | true

      # invalid cases
      # does not match origins with too short identifier
      'web-ide.net' | 'https://abc123.web-ide.net' | false
      # does not match origins with too long identifier
      'web-ide.net' | 'https://abcdefghijklmnopqrstuvwxyz1234567890123456789012345678901.web-ide.net' | false
      # does not match origins with uppercase letters in identifier
      'web-ide.net' | 'https://ABCDEFGHIJKLMNOPQRSTUVWXYZ1234.web-ide.net' | false
      # does not match origins with special characters in identifier
      'web-ide.net' | 'https://abcdefghijklmnopqrstuvwxyz-123.web-ide.net' | false
      # does not match http origins
      'web-ide.net' | 'http://abcdefghijklmnopqrstuvwxyz1234.web-ide.net' | false
      # does not match origins without protocol
      'web-ide.net' | 'abcdefghijklmnopqrstuvwxyz1234.web-ide.net' | false
      # does not match origins with wrong domain
      'web-ide.net' | 'https://abcdefghijklmnopqrstuvwxyz1234.example.com' | false
      # does not match origins with path
      'web-ide.net' | 'https://abcdefghijklmnopqrstuvwxyz1234.web-ide.net/path' | false
      # does not match origins with query parameters
      'web-ide.net' | 'https://abcdefghijklmnopqrstuvwxyz1234.web-ide.net?param=value' | false
      # does not match origins with fragment
      'web-ide.net' | 'https://abcdefghijklmnopqrstuvwxyz1234.web-ide.net#fragment' | false
    end

    with_them do
      before do
        Gitlab::CurrentSettings.update!(
          vscode_extension_marketplace_extension_host_domain: extension_host_domain
        )
      end

      it 'matches valid origins and rejects invalid ones' do
        if should_match
          expect(origin).to match(regexp)
        else
          expect(origin).not_to match(regexp)
        end
      end
    end

    it "captures subdomain in group 1" do
      Gitlab::CurrentSettings.update!(
        vscode_extension_marketplace_extension_host_domain: 'web-ide.net'
      )
      origin = 'https://abcdefghijklmnopqrstuvwxyz1234.web-ide.net'

      expect(described_class.origin_matches_extension_host_regexp.match(origin)[1])
        .to eq('abcdefghijklmnopqrstuvwxyz1234')
    end
  end
end
