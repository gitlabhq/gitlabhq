# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebIde::ExtensionsMarketplace, feature_category: :web_ide do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:current_user) { create(:user) }
  let_it_be(:default_vscode_settings) do
    {
      item_url: 'https://open-vsx.org/vscode/item',
      service_url: 'https://open-vsx.org/vscode/gallery',
      resource_url_template:
        'https://open-vsx.org/vscode/unpkg/{publisher}/{name}/{version}/{path}'
    }
  end

  describe '#feature_enabled?' do
    where(:web_ide_extensions_marketplace, :web_ide_oauth, :expectation) do
      ref(:current_user) | false | false
      false              | true  | false
      ref(:current_user) | true  | true
    end

    with_them do
      it 'returns the expected value' do
        stub_feature_flags(web_ide_extensions_marketplace: web_ide_extensions_marketplace)
        expect(::WebIde::DefaultOauthApplication).to receive(:feature_enabled?)
          .with(current_user).and_return(web_ide_oauth)

        expect(described_class.feature_enabled?(user: current_user)).to be(expectation)
      end
    end
  end

  describe '#vscode_settings' do
    it { expect(described_class.vscode_settings).to match(hash_including(default_vscode_settings)) }
  end

  describe '#marketplace_home_url' do
    it { expect(described_class.marketplace_home_url).to eq('https://open-vsx.org') }
  end

  describe '#help_url' do
    it { expect(described_class.help_url).to match('/help/user/project/web_ide/index#extension-marketplace') }
  end

  describe '#help_preferences_url' do
    it do
      expect(described_class.help_preferences_url).to match(
        '/help/user/profile/preferences#integrate-with-the-extension-marketplace'
      )
    end
  end

  describe '#user_preferences_url' do
    it { expect(described_class.user_preferences_url).to match('/-/profile/preferences#integrations') }
  end

  describe '#metadata_for_user' do
    where(:user, :opt_in_status, :flag_enabled, :expectation) do
      nil                | nil       | false | { enabled: false, disabled_reason: :no_user }
      ref(:current_user) | nil       | nil   | { enabled: false, disabled_reason: :no_flag }
      ref(:current_user) | nil       | false | { enabled: false, disabled_reason: :instance_disabled }
      ref(:current_user) | :enabled  | true  | { enabled: true }
      ref(:current_user) | :disabled | true  | { enabled: false, disabled_reason: :opt_in_disabled }
      ref(:current_user) | :unset    | true  | { enabled: false, disabled_reason: :opt_in_unset }
    end

    with_them do
      subject(:metadata) { described_class.metadata_for_user(user: user, flag_enabled: flag_enabled) }

      before do
        user.update!(extensions_marketplace_opt_in_status: opt_in_status) if user && opt_in_status
      end

      it 'returns expected metadata for user' do
        expect(metadata).to eq(expectation)
      end
    end
  end

  describe '#webide_extensions_gallery_settings' do
    subject(:webide_settings) { described_class.webide_extensions_gallery_settings(user: current_user) }

    context 'when instance enabled' do
      before do
        stub_feature_flags(
          web_ide_extensions_marketplace: current_user,
          web_ide_oauth: current_user,
          vscode_web_ide: current_user
        )
      end

      it 'when user opt in enabled, returns enabled settings' do
        current_user.update!(extensions_marketplace_opt_in_status: :enabled)

        expect(webide_settings).to match({
          enabled: true,
          vscode_settings: hash_including(default_vscode_settings)
        })
      end

      context 'when user opt in disabled' do
        where(:opt_in_status, :reason) do
          :unset    | :opt_in_unset
          :disabled | :opt_in_disabled
        end

        with_them do
          it 'returns disabled settings' do
            current_user.update!(extensions_marketplace_opt_in_status: opt_in_status)

            expect(webide_settings).to match({
              enabled: false,
              reason: reason,
              help_url: described_class.help_url,
              user_preferences_url: described_class.user_preferences_url
            })
          end
        end
      end
    end

    context 'when instance disabled' do
      it 'returns disabled settings and help url' do
        expect(webide_settings).to match({
          enabled: false,
          reason: :instance_disabled,
          help_url: described_class.help_url
        })
      end
    end
  end
end
