# frozen_string_literal: true

require "fast_spec_helper"

RSpec.describe WebIde::Settings::ExtensionMarketplaceGenerator, feature_category: :web_ide do
  using RSpec::Parameterized::TableSyntax

  let(:user_class) do
    stub_const(
      "User",
      Class.new do
        def flipper_id
          "UserStub"
        end
      end
    )
  end

  let(:user) { user_class.new }
  let(:requested_setting_names) { [:vscode_extension_marketplace] }
  let(:custom_app_settings) do
    {
      "enabled" => false,
      "preset" => "custom",
      "custom_values" => {
        "item_url" => "abc",
        "service_url" => "def",
        "resource_url_template" => "ghi"
      }
    }
  end

  let(:context) do
    {
      requested_setting_names: requested_setting_names,
      options: { user: user },
      settings: {}
    }
  end

  subject(:result) { described_class.generate(context)[:settings][:vscode_extension_marketplace] }

  before do
    allow(Feature).to receive(:enabled?).with(:vscode_extension_marketplace_settings, user).and_return(settings_flag)
    allow(Gitlab::CurrentSettings).to receive(:vscode_extension_marketplace).and_return(app_setting)
  end

  describe 'default (with setting requested)' do
    where(:settings_flag, :app_setting, :expectation) do
      false | {}                         | ::WebIde::ExtensionMarketplacePreset.open_vsx.values
      true  | {}                         | ::WebIde::ExtensionMarketplacePreset.open_vsx.values
      true  | { "preset" => 'open_vsx' } | ::WebIde::ExtensionMarketplacePreset.open_vsx.values
      true  | ref(:custom_app_settings)  | { item_url: "abc", service_url: "def", resource_url_template: "ghi" }
      # This should never happen, but lets test it anyways
      true  | { "preset" => 'DNE' }      | nil
    end

    with_them do
      it { is_expected.to eq(expectation) }
    end
  end

  describe 'without setting requested' do
    let(:requested_setting_names) { [] }
    let(:settings_flag) { true }
    let(:app_setting) { custom_app_settings }

    it { is_expected.to be_nil }
  end
end
