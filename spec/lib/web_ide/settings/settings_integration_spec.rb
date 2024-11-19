# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::WebIde::Settings, feature_category: :web_ide do # rubocop:disable RSpec/SpecFilePathFormat -- This cop fails because the spec is named 'settings_integration_spec.rb' but describes ::WebIde::Settings class. But we want it that way, because it's an integration spec, not a unit spec, but we still want to be able to use `described_class`
  let_it_be(:user) { create(:user) }

  let(:expected_vscode_extension_gallery_setting) do
    {
      service_url: "https://open-vsx.org/vscode/gallery",
      item_url: "https://open-vsx.org/vscode/item",
      resource_url_template: 'https://open-vsx.org/vscode/asset/{publisher}/{name}/{version}/Microsoft.VisualStudio.Code.WebResources/{path}',
      control_url: "",
      nls_base_url: "",
      publisher_url: ""
    }
  end

  let(:expected_vscode_extension_gallery_metadata_setting) do
    {
      enabled: false,
      disabled_reason: :instance_disabled
    }
  end

  subject(:settings_module) { described_class }

  describe "#get" do
    let_it_be(:options) do
      {
        user: user,
        vscode_extensions_marketplace_feature_flag_enabled: false
      }
    end

    before do
      # Ensure the test doesn't fail if the setting's env var happens to be set in current environment
      stub_env("GITLAB_WEB_IDE_VSCODE_EXTENSIONS_GALLERY", nil)
      stub_env("GITLAB_WEB_IDE_VSCODE_EXTENSIONS_GALLERY_METADATA", nil)
    end

    it "returns default settings", :unlimited_max_formatted_output_length do
      actual_value = settings_module.get(
        [:vscode_extensions_gallery, :vscode_extensions_gallery_metadata],
        options
      )

      expect(actual_value).to eq(
        {
          vscode_extensions_gallery: expected_vscode_extension_gallery_setting,
          vscode_extensions_gallery_metadata: expected_vscode_extension_gallery_metadata_setting
        }
      )
    end
  end

  describe "#get_single_setting" do
    context "when there is no override" do
      before do
        # Ensure the test doesn't fail if the setting's env var happens to be set in current environment
        stub_env("GITLAB_WEB_IDE_VSCODE_EXTENSIONS_GALLERY", nil)
      end

      it "uses default value" do
        expect(settings_module.get_single_setting(:vscode_extensions_gallery))
          .to eq(expected_vscode_extension_gallery_setting)
      end
    end

    context "when there is an env var override" do
      before do
        stub_env("GITLAB_WEB_IDE_VSCODE_EXTENSIONS_GALLERY",
          '{"service_url":"https://OVERRIDE.org/vscode/gallery",' \
            '"item_url":"https://OVERRIDE.org/vscode/item",' \
            '"resource_url_template":"https://open-vsx.org/vscode/asset/{publisher}/{name}/{version}/Microsoft.VisualStudio.Code.WebResources/{path}"}'
        )
      end

      it "uses the env var override value and casts it" do
        expect(settings_module.get_single_setting(:vscode_extensions_gallery)).to eq(
          {
            service_url: "https://OVERRIDE.org/vscode/gallery",
            item_url: "https://OVERRIDE.org/vscode/item",
            resource_url_template: "https://open-vsx.org/vscode/asset/{publisher}/{name}/{version}/Microsoft.VisualStudio.Code.WebResources/{path}"
          }
        )
      end
    end

    context "when passed an invalid setting name" do
      it "uses default value" do
        expect { settings_module.get_single_setting(:invalid_setting_name) }
          .to raise_error("Unsupported setting name(s): invalid_setting_name")
      end
    end

    context "for vscode_extensions_gallery setting" do
      subject(:vscode_extensions_gallery_setting) do
        settings_module.get_single_setting(:vscode_extensions_gallery)
      end

      it "uses default value" do
        expected_value = {
          item_url: "https://open-vsx.org/vscode/item",
          resource_url_template: "https://open-vsx.org/vscode/asset/{publisher}/{name}/{version}/Microsoft.VisualStudio.Code.WebResources/{path}",
          service_url: "https://open-vsx.org/vscode/gallery",
          control_url: "",
          nls_base_url: "",
          publisher_url: ""
        }

        expect(vscode_extensions_gallery_setting).to eq(expected_value)
      end

      context "when invalid value is set" do
        before do
          stub_env("GITLAB_WEB_IDE_VSCODE_EXTENSIONS_GALLERY", '{"foo":"bar"}')
        end

        it "raises an error" do
          expected_err_msg = "Settings VSCode extensions gallery validation failed: root is missing required keys: " \
            "service_url, item_url, resource_url_template"
          expect { vscode_extensions_gallery_setting }
            .to raise_error(expected_err_msg)
        end
      end
    end

    context "for vscode_extensions_gallery_metadata setting" do
      let_it_be(:options) do
        {
          user: user,
          vscode_extensions_marketplace_feature_flag_enabled: false
        }
      end

      subject(:vscode_extensions_gallery_metadata_setting) do
        settings_module.get_single_setting(:vscode_extensions_gallery_metadata, options)
      end

      it "uses default value" do
        expect(vscode_extensions_gallery_metadata_setting).to eq(expected_vscode_extension_gallery_metadata_setting)
      end

      context "when invalid value is set" do
        before do
          stub_env("GITLAB_WEB_IDE_VSCODE_EXTENSIONS_GALLERY_METADATA", '{"foo":"bar"}')
        end

        it "raises an error" do
          expected_err_msg = "Settings VSCode extensions gallery metadata validation failed: " \
            "root is missing required keys: enabled"
          expect { vscode_extensions_gallery_metadata_setting }
            .to raise_error(expected_err_msg)
        end
      end
    end
  end
end
