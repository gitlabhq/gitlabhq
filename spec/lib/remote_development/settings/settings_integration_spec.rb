# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::Settings, feature_category: :remote_development do # rubocop:disable RSpec/FilePath -- Not sure why this is being flagged
  subject(:settings_module) { described_class }

  context "when there is no override" do
    before do
      # Ensure the test doesn't fail if the setting's env var happens to be set in current environment
      stub_env("GITLAB_REMOTE_DEVELOPMENT_MAX_HOURS_BEFORE_TERMINATION_LIMIT", nil)
    end

    it "uses default value" do
      expect(settings_module.get_single_setting(:max_hours_before_termination_limit)).to eq(120)
      expect(settings_module.get_single_setting(:default_branch_name)).to be_nil
    end
  end

  context "when there is an env var override" do
    before do
      stub_env("GITLAB_REMOTE_DEVELOPMENT_MAX_HOURS_BEFORE_TERMINATION_LIMIT", "42")
    end

    it "uses the env var override value and casts it" do
      expect(settings_module.get_single_setting(:max_hours_before_termination_limit)).to eq(42)
    end
  end

  context "when there is and ENV var override and also a ::Gitlab::CurrentSettings override" do
    let(:override_value_from_env) { "value_from_env" }
    let(:override_value_from_current_settings) { "value_from_current_settings" }

    before do
      stub_env("GITLAB_REMOTE_DEVELOPMENT_DEFAULT_BRANCH_NAME", override_value_from_env)

      create(:application_setting)
      stub_application_setting(default_branch_name: override_value_from_current_settings)
    end

    it "uses the ENV var value and not the CurrentSettings value" do
      # fixture sanity check
      expect(Gitlab::CurrentSettings.default_branch_name).to eq(override_value_from_current_settings)

      expect(settings_module.get_single_setting(:default_branch_name)).to eq(override_value_from_env)
    end
  end

  context "when passed an invalid setting name" do
    it "uses default value" do
      expect { settings_module.get_single_setting(:invalid_setting_name) }
        .to raise_error("Unsupported Remote Development setting name: 'invalid_setting_name'")
    end
  end

  context "for vscode_extensions_gallery setting" do
    subject(:vscode_extensions_gallery_setting) { settings_module.get_single_setting(:vscode_extensions_gallery) }

    it "uses default value" do
      expected_value = {
        item_url: "https://open-vsx.org/vscode/item",
        resource_url_template: "https://open-vsx.org/api/{publisher}/{name}/{version}/file/{path}",
        service_url: "https://open-vsx.org/vscode/gallery"
      }

      expect(vscode_extensions_gallery_setting).to eq(expected_value)
    end

    context "when invalid value is set" do
      before do
        stub_env("GITLAB_REMOTE_DEVELOPMENT_VSCODE_EXTENSIONS_GALLERY", '{"foo":"bar"}')
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
    let_it_be(:user) { create(:user) }
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
      expected_value = {
        enabled: false,
        disabled_reason: :instance_disabled
      }

      expect(vscode_extensions_gallery_metadata_setting).to eq(expected_value)
    end

    context "when invalid value is set" do
      before do
        stub_env("GITLAB_REMOTE_DEVELOPMENT_VSCODE_EXTENSIONS_GALLERY_METADATA", '{"foo":"bar"}')
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
