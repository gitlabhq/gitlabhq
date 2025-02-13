# frozen_string_literal: true

require "fast_spec_helper"

RSpec.describe WebIde::Settings::SettingsInitializer, feature_category: :web_ide do
  let(:all_possible_requested_setting_names) { WebIde::Settings::DefaultSettings.default_settings.keys }
  let(:context) do
    { requested_setting_names: all_possible_requested_setting_names }
  end

  subject(:returned_value) do
    described_class.init(context)
  end

  it "invokes DefaultSettingsParser and sets up necessary values in context for subsequent steps" do
    expect(returned_value).to match(
      {
        requested_setting_names: [
          :vscode_extension_marketplace,
          :vscode_extension_marketplace_metadata,
          :vscode_extension_marketplace_view_model
        ],
        settings: {
          vscode_extension_marketplace: {
            control_url: "",
            item_url: "https://open-vsx.org/vscode/item",
            nls_base_url: "",
            publisher_url: "",
            resource_url_template: 'https://open-vsx.org/vscode/asset/{publisher}/{name}/{version}/Microsoft.VisualStudio.Code.WebResources/{path}',
            service_url: "https://open-vsx.org/vscode/gallery"
          },
          vscode_extension_marketplace_metadata: {
            enabled: false,
            disabled_reason: :instance_disabled
          },
          vscode_extension_marketplace_view_model: {
            enabled: false,
            reason: :instance_disabled,
            help_url: ''
          }
        },
        setting_types: {
          vscode_extension_marketplace: Hash,
          vscode_extension_marketplace_metadata: Hash,
          vscode_extension_marketplace_view_model: Hash
        },
        env_var_prefix: "GITLAB_WEB_IDE",
        env_var_failed_message_class: WebIde::Settings::Messages::SettingsEnvironmentVariableOverrideFailed
      }
    )
  end
end
